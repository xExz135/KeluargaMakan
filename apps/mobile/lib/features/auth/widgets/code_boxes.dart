// The O2b code field: `length` single-digit boxes drawn over one text field,
// so autofill (one-time-code hint, SMS Retriever or SMS User Consent on
// Android) fills all digits at once, and TalkBack reads one control:
// "Kode, 6 angka" (screens.md O2b).
//
// The field is not restorable, not suggested and not learned by the
// keyboard (enableIMEPersonalizedLearning: false), so the code is not kept
// anywhere after it is used.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/tokens.dart';

class CodeBoxes extends StatelessWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.enabled,
    required this.semanticsLabel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final String semanticsLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digitStyle = theme.textTheme.headlineSmall!;
    final scaler = MediaQuery.textScalerOf(context);
    final boxHeight = math.max(
      56.0,
      scaler.scale(digitStyle.fontSize ?? 24) + 2 * SpacingTokens.m,
    );
    return Stack(
      children: [
        ExcludeSemantics(
          child: ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              final text = controller.text;
              return Row(
                children: [
                  for (var i = 0; i < length; i++) ...[
                    if (i > 0) const SizedBox(width: SpacingTokens.s),
                    Expanded(
                      child: _Box(
                        height: boxHeight,
                        digit: i < text.length ? text[i] : '',
                        active:
                            enabled &&
                            focusNode.hasFocus &&
                            (i == text.length ||
                                (i == length - 1 && text.length == length)),
                        enabled: enabled,
                        style: digitStyle,
                        scheme: scheme,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        Positioned.fill(
          child: Semantics(
            label: semanticsLabel,
            child: TextField(
              key: const Key('code.field'),
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(length),
              ],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              enableInteractiveSelection: false,
              showCursor: false,
              textInputAction: TextInputAction.done,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.height,
    required this.digit,
    required this.active,
    required this.enabled,
    required this.style,
    required this.scheme,
  });

  final double height;
  final String digit;
  final bool active;
  final bool enabled;
  final TextStyle style;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final borderColor = !enabled
        ? scheme.outlineVariant
        : (active ? scheme.primary : scheme.outline);
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(RadiusTokens.control),
        border: Border.all(color: borderColor, width: active ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            digit,
            style: style.copyWith(
              color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
