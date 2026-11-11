// Navigation label fitting (owner decision 2026-11-11, DECISIONS.md; INT-05,
// NFR-15, INT-02).
//
// A narrow exception to "never clamp text scaling" (accessibility.md 3), for
// bottom navigation labels only. Labels follow the system text size until one
// no longer fits its slot on one line; then all labels are drawn at the
// largest scale at which every label fits, so none breaks mid-word
// ("Berand / a"). The text is never cut or abbreviated, so TalkBack reads the
// full label. All other text keeps scaling to 200%. The navigation rail
// already keeps its labels on one line by growing wider, so it is unchanged.

import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// The text scaler that fits [text] in [maxWidth] on one line: [scaler]
/// when the text already fits, otherwise a smaller linear scaler.
TextScaler fitTextScaler({
  required String text,
  required TextStyle style,
  required TextScaler scaler,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  double widthAt(TextScaler s) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: s,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  if (!maxWidth.isFinite || maxWidth <= 0) return scaler;
  final fullWidth = widthAt(scaler);
  if (fullWidth <= maxWidth) return scaler;

  // Effective factor of the system scaler at this font size (Android 14+
  // scales large fonts non-linearly), reduced in proportion to the overflow.
  final fontSize = style.fontSize ?? 14;
  var factor = scaler.scale(fontSize) / fontSize * maxWidth / fullWidth;
  // Glyph advances round, so width is not exactly linear in size: step down
  // until it really fits.
  for (var i = 0; i < 5; i++) {
    if (widthAt(TextScaler.linear(factor)) <= maxWidth) break;
    factor *= 0.98;
  }
  return TextScaler.linear(math.max(factor, 0.01));
}

/// One shared scaler for a row of labels: the smallest of the per-label fits,
/// so every label in the navigation bar is drawn at the same size. Measure
/// with the widest style a label can take (the bold selected style), so the
/// size does not change when the user switches tabs.
TextScaler fitAllTextScaler({
  required Iterable<String> texts,
  required TextStyle style,
  required TextScaler scaler,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  var result = scaler;
  var smallest = scaler.scale(1);
  for (final text in texts) {
    final fitted = fitTextScaler(
      text: text,
      style: style,
      scaler: scaler,
      maxWidth: maxWidth,
      textDirection: textDirection,
    );
    if (fitted.scale(1) < smallest) {
      smallest = fitted.scale(1);
      result = fitted;
    }
  }
  return result;
}
