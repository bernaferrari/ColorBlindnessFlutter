import 'dart:math';

import 'package:flutter/material.dart';

import 'color_blindness.dart';
import 'color_blindness_color_scheme.dart';

/// This method simulates color blindness in a ColorScheme and compares
/// [primary, secondary] against [background, surface].
///
/// Should be used in CI and tests.
///
/// Input:
/// ColorScheme: the ColorScheme you are using as your theme.
/// double: the minimum threshold in WCAG 2.1 where it should pass.
/// The value is usually 4.5 (AA) or 7.0 (AAA). Contrast ranges from 0 to 21.
///
/// Output:
/// if successful: nothing
/// if there is an error: it will throw an exception
void colorBlindnessAssertContrast(ColorScheme scheme,
    [double minThreshold = 4.5]) {
  for (ColorBlindnessType type in ColorBlindnessType.values) {
    final updatedScheme = colorBlindnessColorScheme(scheme, type);

    void calculate({
      required Color aColor,
      required Color bColor,
      required String aStr,
      required String bStr,
    }) {
      final contrast = _calculateContrast(aColor, bColor);
      if (contrast < minThreshold) {
        throw Exception(
            "Fail! For ${type.toString().substring(19)}, $aStr ($aColor) on $bStr ($bColor) got value ${contrast.toStringAsFixed(2)}");
      }
    }

    calculate(
      aColor: updatedScheme.primary,
      bColor: updatedScheme.background,
      aStr: "primary",
      bStr: "background",
    );

    calculate(
      aColor: updatedScheme.primary,
      bColor: updatedScheme.surface,
      aStr: "primary",
      bStr: "surface",
    );

    calculate(
      aColor: updatedScheme.secondary,
      bColor: updatedScheme.background,
      aStr: "secondary",
      bStr: "background",
    );

    calculate(
      aColor: updatedScheme.secondary,
      bColor: updatedScheme.background,
      aStr: "secondary",
      bStr: "surface",
    );
  }
}

double _calculateContrast(Color color1, Color color2) {
  final double colorFirstLum = color1.computeLuminance();
  final double colorSecondLum = color2.computeLuminance();

  final double l1 = min(colorFirstLum, colorSecondLum);
  final double l2 = max(colorFirstLum, colorSecondLum);

  return 1 / ((l1 + 0.05) / (l2 + 0.05));
}
