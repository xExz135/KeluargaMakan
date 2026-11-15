// KIT-01 to KIT-07 the kitchen repository and decoders: strict decoding
// (unknown state is "Habis", never "Ada"), the account-bound copy of the
// kitchen, the catalog with ETag / If-None-Match and 304, 503
// `reference_data_unavailable` as a failure, and the local search.
// TEST FIXTURE: not real safety or nutrition data. Names are invented.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keluargamakan/core/api/api_client.dart';
import 'package:keluargamakan/core/api/api_problem.dart';
import 'package:keluargamakan/core/api/api_result.dart';
import 'package:keluargamakan/core/api/token_store.dart';
import 'package:keluargamakan/core/storage/app_database.dart';
import 'package:keluargamakan/data/ingredient_search.dart';
import 'package:keluargamakan/data/kitchen_decoders.dart';
import 'package:keluargamakan/data/models/kitchen.dart';
import 'package:keluargamakan/data/models/sourced.dart';
import 'package:keluargamakan/data/repositories/kitchen_repository.dart';
import 'package:keluargamakan/features/dapur_saya/labels.dart';

import '../helpers/api_fixtures.dart';

Map<String, Object?> _item({
  String id = 'k-1',
  String? ingredientId = 'fx_kit_tempe',
  String? customName,
  Object? state = 'available',
  String category = 'protein',
  int? usageRank,
}) => {
  'id': id,
  'ingredientId': ingredientId,
  'isCustom': ingredientId == null,
  'displayName': ingredientId == null ? null : {'id': 'Tempe', 'en': 'Tempeh'},
  'customName': customName,
  'category': category,
  'state': state,
  'quantity': null,
  'brand': null,
  'isDefaultStaple': false,
  'usageRank': usageRank,
  'changedAt': '2026-11-15T01:00:00Z',
  'createdAt': '2026-11-14T01:00:00Z',
};

Map<String, Object?> _list(List<Map<String, Object?>> items) => {
  'items': items,
  'maxItems': 300,
  'referenceVersion': 'fx-1',
};

Map<String, Object?> _catalogJson() => {
  'referenceVersion': 'fx-1',
  'items': [
    {
      'ingredientId': 'fx_kit_kemangi',
      'displayName': {'id': 'Kemangi', 'en': 'Lemon basil'},
      'localNames': ['selasih'],
      'category': 'spices_aromatics',
      'brandVaries': false,
      'brands': <Object?>[],
    },
    {
      'ingredientId': 'fx_kit_tempe',
      'displayName': {'id': 'Tempe', 'en': 'Tempeh'},
      'localNames': <Object?>[],
      'category': 'protein',
      'brandVaries': false,
      'brands': <Object?>[],
    },
  ],
};

void main() {
  group('KIT-02 decoding', () {
    test('KIT-02 an unknown state shows as out, never as available', () {
      final item = decodeKitchenItem(_item(state: 'expired'));
      expect(item.state, KitchenItemState.out);
      expect(decodeKitchenItem(_item(state: null)).state, KitchenItemState.out);
    });

    test(
      'KIT-03 an unknown category fails the whole list (breaking change)',
      () {
        expect(
          () => decodeKitchenList(
            _list([_item(), _item(id: 'k-2', category: 'snacks')]),
          ),
          throwsFormatException,
        );
      },
    );

    test('KIT-05 the custom flag must match the missing ingredient ID', () {
      expect(
        () => decodeKitchenItem({..._item(), 'isCustom': true}),
        throwsFormatException,
      );
      expect(
        () => decodeKitchenItem(_item(ingredientId: null)),
        throwsFormatException,
        reason: 'a custom item needs its name',
      );
      final custom = decodeKitchenItem(
        _item(ingredientId: null, customName: 'Sambal Ibu'),
      );
      expect(custom.isCustom, isTrue);
      expect(custom.key, const CustomIngredient('Sambal Ibu'));
    });

    test('KIT-01 a missing list or limit fails closed, never an empty '
        'kitchen', () {
      expect(() => decodeKitchenList({'maxItems': 1}), throwsFormatException);
      expect(
        () =>
            decodeKitchenList({'items': <Object?>[], 'referenceVersion': null}),
        throwsFormatException,
      );
    });

    test('KIT-04 a catalog category this app does not know is asked for, '
        'not guessed', () {
      final json = _catalogJson();
      ((json['items']! as List).first as Map)['category'] = 'snacks';
      final catalog = decodeCatalog(json, etag: null);
      expect(catalog.items.first.category, isNull);
    });

    test('L1 a repeated kitchen item ID fails the list', () {
      expect(
        () => decodeKitchenList(_list([_item(), _item(state: 'out')])),
        throwsFormatException,
      );
    });

    test('L1 a repeated catalog ingredient ID fails the catalog', () {
      final json = _catalogJson();
      final items = json['items']! as List;
      json['items'] = [...items, items.first];
      expect(() => decodeCatalog(json, etag: null), throwsFormatException);
    });

    test('KIT-04 only a well-formed ETag is kept', () {
      expect(acceptableEtag('"abc123"'), '"abc123"');
      expect(acceptableEtag('W/"abc"'), 'W/"abc"');
      expect(acceptableEtag('abc'), isNull);
      expect(acceptableEtag('"a\r\nX-Evil: 1"'), isNull);
      expect(acceptableEtag('"${'a' * 300}"'), isNull);
    });
  });

  group('KIT-04 catalog download', () {
    late AppDatabase db;
    late FutureOr<http.Response> Function(http.Request) respond;
    final requests = <http.Request>[];

    setUp(() {
      db = memoryDatabase();
      addTearDown(db.close);
      requests.clear();
    });

    Future<KitchenRepository> repo() async {
      final c = testContainer(
        handler: (r) async {
          requests.add(r);
          return respond(r);
        },
        tokens: InMemoryTokenStore(testTokens),
        db: db,
      );
      addTearDown(c.dispose);
      await c.read(sessionManagerProvider).load();
      return c.read(kitchenRepositoryProvider);
    }

    test('KIT-04 200 keeps the copy with its ETag; the next call sends '
        'If-None-Match and a 304 returns the copy', () async {
      respond = (r) => r.headers['if-none-match'] == '"fx-1"'
          ? http.Response('', 304, headers: {'etag': '"fx-1"'})
          : http.Response(
              jsonEncode(_catalogJson()),
              200,
              headers: {'content-type': 'application/json', 'etag': '"fx-1"'},
            );
      final r = await repo();
      final first = valueOf(await r.refreshCatalog());
      expect(first.items, hasLength(2));
      expect(first.etag, '"fx-1"');
      expect(requests.single.headers['if-none-match'], isNull);

      final second = valueOf(await r.refreshCatalog());
      expect(requests.last.headers['if-none-match'], '"fx-1"');
      expect(second.items.map((i) => i.ingredientId), [
        'fx_kit_kemangi',
        'fx_kit_tempe',
      ]);
      expect(second.source, isA<FromNetwork>());
    });

    http.Response catalogOk({String? etag}) => http.Response(
      jsonEncode(_catalogJson()),
      200,
      headers: {'content-type': 'application/json', 'etag': ?etag},
    );

    test('L2 a 304 when no If-None-Match was sent is not trusted: one full '
        'download follows', () async {
      // A first download without an ETag: the copy has none to send.
      respond = (_) => catalogOk();
      final r = await repo();
      valueOf(await r.refreshCatalog());
      requests.clear();
      respond = (req) => requests.length == 1
          ? http.Response('', 304)
          : catalogOk(etag: '"fx-2"');
      final result = valueOf(await r.refreshCatalog());
      expect(requests, hasLength(2));
      expect(requests[0].headers['if-none-match'], isNull);
      expect(requests[1].headers['if-none-match'], isNull);
      expect(result.etag, '"fx-2"');
    });

    test(
      'L2 a 304 naming another tag than the one sent is not trusted',
      () async {
        respond = (_) => catalogOk(etag: '"fx-1"');
        final r = await repo();
        await r.refreshCatalog();
        requests.clear();
        respond = (req) => req.headers['if-none-match'] != null
            ? http.Response('', 304, headers: {'etag': '"other"'})
            : catalogOk(etag: '"fx-3"');
        final result = valueOf(await r.refreshCatalog());
        expect(requests.first.headers['if-none-match'], '"fx-1"');
        expect(requests.last.headers['if-none-match'], isNull);
        expect(result.etag, '"fx-3"');
      },
    );

    test('L2 a 304 to the full download fails closed', () async {
      respond = (_) => catalogOk(etag: '"fx-1"');
      final r = await repo();
      await r.refreshCatalog();
      respond = (_) => http.Response('', 304, headers: {'etag': '"other"'});
      expect(failureOf(await r.refreshCatalog()), isA<DecodeFailure>());
    });

    test('KIT-04 a 304 without a copy fails closed', () async {
      respond = (_) => http.Response('', 304);
      final r = await repo();
      expect(failureOf(await r.refreshCatalog()), isA<DecodeFailure>());
    });

    test('KIT-04 without internet the copy is returned; 503 is a failure '
        'even with a copy', () async {
      respond = (_) => http.Response(
        jsonEncode(_catalogJson()),
        200,
        headers: {'content-type': 'application/json', 'etag': '"fx-1"'},
      );
      final r = await repo();
      await r.refreshCatalog();

      respond = (_) => throw http.ClientException('offline');
      final offline = valueOf(await r.refreshCatalog());
      expect(offline.source, isA<FromCache>());

      respond = (_) => problemResponse('reference_data_unavailable', 503);
      expect(
        failureOf(await r.refreshCatalog()).problemCode,
        ApiErrorCode.referenceDataUnavailable,
      );
    });

    test('KIT-04 search sends the query in the body only, and 503 is not '
        '"no results"', () async {
      respond = (_) => problemResponse('reference_data_unavailable', 503);
      final r = await repo();
      final result = await r.search('kemangi');
      expect(
        failureOf(result).problemCode,
        ApiErrorCode.referenceDataUnavailable,
      );
      final sent = requests.single;
      expect(sent.method, 'POST');
      expect(sent.url.toString(), isNot(contains('kemangi')));
      expect(jsonDecode(sent.body), {'query': 'kemangi'});
    });

    test('KIT-01 the kitchen copy is used only without internet', () async {
      respond = (_) => jsonResponse(_list([_item()]));
      final r = await repo();
      expect(valueOf(await r.listItems()).source, isA<FromNetwork>());

      respond = (_) => problemResponse('internal_error', 500);
      expect(failureOf(await r.listItems()), isA<ProblemFailure>());

      respond = (_) => throw http.ClientException('offline');
      final cached = valueOf(await r.listItems());
      expect(cached.source, isA<FromCache>());
      expect(cached.items.single.ingredientId, 'fx_kit_tempe');
    });
  });

  group('KIT-04 local search', () {
    final catalog = decodeCatalog(_catalogJson(), etag: null);

    test('KIT-04 matches local names and says which one matched', () {
      final hits = searchCatalog(catalog, 'Selasih');
      expect(hits.single.ingredient.ingredientId, 'fx_kit_kemangi');
      expect(hits.single.matchedName, 'selasih');
    });

    test('KIT-04 ignores case, accents and spacing; exact and starting '
        'matches first', () {
      expect(
        searchCatalog(catalog, '  TÉMPE ').single.ingredient.ingredientId,
        'fx_kit_tempe',
      );
      expect(
        searchCatalog(catalog, 'e').first.ingredient.ingredientId,
        'fx_kit_kemangi',
      );
      expect(searchCatalog(catalog, '!!!'), isEmpty);
    });

    test(
      'KIT-05 "did you mean" needs a name that is or starts the known one',
      () {
        expect(
          closestCatalogMatch(catalog, 'temp')?.ingredient.ingredientId,
          'fx_kit_tempe',
        );
        expect(closestCatalogMatch(catalog, 'te'), isNull);
        expect(closestCatalogMatch(catalog, 'empe'), isNull);
      },
    );
  });

  group('KIT-06 order within a category', () {
    KitchenEntry entry(String id, {int? rank}) =>
        decodeKitchenItem(_item(id: id, usageRank: rank));

    test('KIT-06 ranked items first up to the count, then A to Z', () {
      final names = {'a': 'Tahu', 'b': 'Tempe', 'c': 'Oncom', 'd': 'Ayam'};
      final order = orderCategoryItems(
        [entry('a'), entry('b', rank: 2), entry('c', rank: 1), entry('d')],
        frequentCount: 1,
        nameOf: (e) => names[e.id]!,
      );
      expect(order.frequent.map((e) => names[e.id]), ['Oncom']);
      expect(order.other.map((e) => names[e.id]), ['Ayam', 'Tahu', 'Tempe']);
    });

    test('KIT-06 without ranks (until T-032) everything is A to Z, and the '
        'local rank hook can order them', () {
      final names = {'a': 'Tempe', 'b': 'Ayam'};
      final plain = orderCategoryItems(
        [entry('a'), entry('b')],
        frequentCount: 6,
        nameOf: (e) => names[e.id]!,
      );
      expect(plain.frequent, isEmpty);
      expect(plain.other.map((e) => names[e.id]), ['Ayam', 'Tempe']);
      final hooked = orderCategoryItems(
        [entry('a'), entry('b')],
        frequentCount: 6,
        nameOf: (e) => names[e.id]!,
        rankOf: (e) => e.id == 'a' ? 1 : null,
      );
      expect(hooked.frequent.map((e) => names[e.id]), ['Tempe']);
    });
  });
}
