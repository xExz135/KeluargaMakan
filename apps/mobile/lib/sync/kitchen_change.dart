// A kitchen change made on this phone and queued for the sync (KIT-16,
// contract `KitchenChange`), and the rules for collapsing the queue.
//
// - Every change names its ingredient (a reference ID or a custom name), so
//   an item added without internet needs no server ID.
// - Every change has a random change ID made with it and never changed
//   afterwards, so sending it again is safe: the server returns the first
//   result instead of applying it twice.
// - Its age is measured on a monotonic clock where possible (DeviceClock).
// - The queue is collapsed per ingredient only where the result is the same
//   as sending every change in order (see [changesReplacedBy]).
//
// toString() never prints names: custom names and typed brands are the
// user's own text (DAT-08).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:keluargamakan_api/api.dart' as api;

import '../data/models/kitchen.dart';
import 'device_clock.dart';

enum KitchenChangeOp {
  upsert,
  remove;

  api.KitchenChangeOperation toApi() => switch (this) {
    upsert => api.KitchenChangeOperation.upsert,
    remove => api.KitchenChangeOperation.remove,
  };
}

/// A field a change leaves as it is ([Keep]) or sets, possibly to null
/// ([SetTo]).
@immutable
sealed class Setting<T> {
  const Setting();
}

final class Keep<T> extends Setting<T> {
  const Keep();

  @override
  bool operator ==(Object other) => other is Keep<T>;

  @override
  int get hashCode => 0;
}

final class SetTo<T> extends Setting<T> {
  const SetTo(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is SetTo<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// The fields an upsert sets (contract `KitchenChange`).
@immutable
final class KitchenPatch {
  const KitchenPatch({
    this.category,
    this.state,
    this.quantity = const Keep(),
    this.brand = const Keep(),
  });

  /// Everything an item has, so applying it re-creates the item as it was
  /// (Undo of a removal).
  factory KitchenPatch.snapshotOf(KitchenEntry item) => KitchenPatch(
    category: item.category,
    state: item.state,
    quantity: SetTo(item.quantity),
    brand: SetTo(item.brand),
  );

  final api.KitchenCategory? category;
  final KitchenItemState? state;
  final Setting<KitchenAmount?> quantity;
  final Setting<KitchenBrand?> brand;

  static const allFields = {'category', 'state', 'quantity', 'brand'};

  Set<String> get fields => {
    if (category != null) 'category',
    if (state != null) 'state',
    if (quantity is SetTo) 'quantity',
    if (brand is SetTo) 'brand',
  };

  /// Sets at least every field [older] sets.
  bool covers(KitchenPatch older) => fields.containsAll(older.fields);

  /// Sets every field an item has.
  bool get isSnapshot => fields.containsAll(allFields);

  /// [item] with this patch applied, as the screen shows it.
  KitchenEntry applyTo(KitchenEntry item, DateTime at) => item.copyWith(
    category: category,
    state: state,
    quantity: switch (quantity) {
      SetTo(:final value) => () => value,
      Keep() => null,
    },
    brand: switch (brand) {
      SetTo(:final value) => () => value,
      Keep() => null,
    },
    changedAt: at,
  );

  // ---------------------------------------------------------- storage

  Map<String, Object?> toJson() => {
    if (category case final c?) 'category': c.toJson(),
    if (state case final s?) 'state': s.wire,
    if (quantity case SetTo(:final value)) 'quantity': value?.wire,
    if (brand case SetTo(:final value))
      'brand': switch (value) {
        ReferenceBrand(:final brandId, :final name) => {
          'brandId': brandId,
          'name': name,
        },
        TypedBrand(:final name) => {'typed': name},
        null => null,
      },
  };

  /// Reads what [toJson] wrote. Throws [FormatException] for anything else,
  /// so a row this app version cannot read is never sent half understood.
  static KitchenPatch fromJson(Object? json) {
    if (json is! Map<String, Object?>) throw const FormatException('patch');
    api.KitchenCategory? category;
    if (json.containsKey('category')) {
      category =
          api.KitchenCategory.fromJson(json['category']) ??
          (throw const FormatException('patch category'));
    }
    KitchenItemState? state;
    if (json.containsKey('state')) {
      state = switch (json['state']) {
        'available' => KitchenItemState.available,
        'out' => KitchenItemState.out,
        _ => throw const FormatException('patch state'),
      };
    }
    Setting<KitchenAmount?> quantity = const Keep();
    if (json.containsKey('quantity')) {
      final raw = json['quantity'];
      quantity = SetTo(
        raw == null
            ? null
            : KitchenAmount.fromWire(raw) ??
                  (throw const FormatException('patch quantity')),
      );
    }
    Setting<KitchenBrand?> brand = const Keep();
    if (json.containsKey('brand')) {
      brand = SetTo(switch (json['brand']) {
        null => null,
        {'brandId': final String id, 'name': final String name} =>
          ReferenceBrand(id, name),
        {'typed': final String name} => TypedBrand(name),
        _ => throw const FormatException('patch brand'),
      });
    }
    return KitchenPatch(
      category: category,
      state: state,
      quantity: quantity,
      brand: brand,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KitchenPatch &&
      other.category == category &&
      other.state == state &&
      other.quantity == quantity &&
      other.brand == brand;

  @override
  int get hashCode => Object.hash(category, state, quantity, brand);

  @override
  String toString() => 'KitchenPatch(${fields.join(',')})';
}

/// One queued change.
@immutable
final class QueuedChange {
  const QueuedChange({
    required this.seq,
    required this.changeId,
    required this.ingredient,
    required this.op,
    required this.patch,
    required this.stamp,
    this.sendAttempts = 0,
  });

  /// Order on this phone: oldest first.
  final int seq;

  /// Random UUID made with the change, never changed afterwards.
  final String changeId;
  final IngredientKey ingredient;
  final KitchenChangeOp op;

  /// Empty for a removal.
  final KitchenPatch patch;

  /// When the edit was made. [pendingTimeline] until the device clock has
  /// answered; such a change is never sent or expired.
  final ClockReading stamp;

  /// How often this change was sent. 0: it cannot have reached the server.
  final int sendAttempts;

  /// The same change after one more send.
  QueuedChange sentOnceMore() => QueuedChange(
    seq: seq,
    changeId: changeId,
    ingredient: ingredient,
    op: op,
    patch: patch,
    stamp: stamp,
    sendAttempts: sendAttempts + 1,
  );

  /// The timeline of a change whose device clock reading has not arrived.
  static const pendingTimeline = 'pending';

  /// The device clock has stamped this change.
  bool get isStamped => stamp.timeline != pendingTimeline;

  /// The key the latest change wins on ([ingredientKeyOf]).
  String get key => ingredientKeyOf(ingredient);

  DateTime get editedAt =>
      DateTime.fromMillisecondsSinceEpoch(stamp.wallMs, isUtc: true);

  /// The change as the contract sends it, [ageMs] old.
  api.KitchenChange toApi({required int ageMs}) {
    final brand = switch (patch.brand) {
      Keep() => const api.Optional<api.KitchenBrandInput?>.absent(),
      SetTo(:final value) => api.Optional<api.KitchenBrandInput?>.present(
        switch (value) {
          ReferenceBrand(:final brandId) => api.KitchenBrandInput(
            brandId: api.Optional.present(brandId),
          ),
          TypedBrand(:final name) => api.KitchenBrandInput(
            customName: api.Optional.present(name),
          ),
          null => null,
        },
      ),
    };
    return api.KitchenChange(
      changeId: changeId,
      ingredient: switch (ingredient) {
        ReferenceIngredient(:final ingredientId) => api.KitchenIngredientKey(
          ingredientId: api.Optional.present(ingredientId),
        ),
        CustomIngredient(:final name) => api.KitchenIngredientKey(
          customName: api.Optional.present(name),
        ),
      },
      operation: op.toApi(),
      ageMs: ageMs,
      category: op == KitchenChangeOp.remove || patch.category == null
          ? const api.Optional.absent()
          : api.Optional.present(patch.category),
      state: op == KitchenChangeOp.remove || patch.state == null
          ? const api.Optional.absent()
          : api.Optional.present(patch.state!.toApi()),
      quantity: switch (patch.quantity) {
        SetTo(:final value) when op == KitchenChangeOp.upsert =>
          api.Optional.present(value?.toApi()),
        _ => const api.Optional.absent(),
      },
      brand: op == KitchenChangeOp.upsert ? brand : const api.Optional.absent(),
    );
  }

  String patchJson() => jsonEncode(patch.toJson());

  @override
  String toString() => 'QueuedChange($seq, ${op.name}, $patch)';
}

/// The queued changes that [next] makes unnecessary, by change ID. Only
/// changes for the same ingredient that are not on their way ([inFlight])
/// are dropped, and only where sending [next] alone ends the same as sending
/// them all in order (the server keeps the latest change per ingredient):
/// - a removal replaces every earlier change to the ingredient;
/// - an upsert replaces an earlier upsert whose fields it all sets again;
/// - an upsert that sets every field (Undo of a removal) also replaces an
///   earlier removal, so the item keeps its server ID and its sets.
Set<String> changesReplacedBy(
  QueuedChange next,
  Iterable<QueuedChange> queue, {
  Set<String> inFlight = const {},
}) => {
  for (final queued in queue)
    if (queued.key == next.key &&
        queued.changeId != next.changeId &&
        !inFlight.contains(queued.changeId) &&
        switch ((queued.op, next.op)) {
          (_, KitchenChangeOp.remove) => true,
          (KitchenChangeOp.upsert, KitchenChangeOp.upsert) => next.patch.covers(
            queued.patch,
          ),
          (KitchenChangeOp.remove, KitchenChangeOp.upsert) =>
            next.patch.isSnapshot,
        })
      queued.changeId,
};
