import 'dart:ui';

export 'package:color_blindness/color_blindness_color_scheme.dart';
export 'package:color_blindness/color_blindness_contrast_checker.dart';

/// Color vision deficiency simulation modes.
///
/// Includes [none] as an identity pass-through convenience.
enum ColorBlindnessType {
  none('Normal vision', 'Full trichromatic vision'),
  protanomaly('Protanomaly', 'Red-weak trichromacy'),
  deuteranomaly('Deuteranomaly', 'Green-weak trichromacy'),
  tritanomaly('Tritanomaly', 'Blue-weak trichromacy'),
  protanopia('Protanopia', 'Red-blind dichromacy'),
  deuteranopia('Deuteranopia', 'Green-blind dichromacy'),
  tritanopia('Tritanopia', 'Blue-blind dichromacy'),
  achromatopsia('Achromatopsia', 'Complete monochromacy'),
  achromatomaly('Achromatomaly', 'Partial monochromacy');

  const ColorBlindnessType(this.label, this.shortDescription);

  /// Human-readable display name.
  final String label;

  /// Concise summary of the color vision deficiency.
  final String shortDescription;
}

/// Convenience simulation helper on any Flutter [Color].
extension ColorBlindnessColorExtension on Color {
  /// Returns this color as perceived under [type].
  Color simulateColorBlindness(ColorBlindnessType type) =>
      colorBlindness(this, type);
}

/// Simulates color blindness in a single [color].
Color colorBlindness(Color color, ColorBlindnessType type) => switch (type) {
  ColorBlindnessType.none => color,
  ColorBlindnessType.protanomaly => protanomaly(color),
  ColorBlindnessType.deuteranomaly => deuteranomaly(color),
  ColorBlindnessType.tritanomaly => tritanomaly(color),
  ColorBlindnessType.protanopia => protanopia(color),
  ColorBlindnessType.deuteranopia => deuteranopia(color),
  ColorBlindnessType.tritanopia => tritanopia(color),
  ColorBlindnessType.achromatopsia => achromatopsia(color),
  ColorBlindnessType.achromatomaly => achromatomaly(color),
};

// Matrices adapted from https://github.com/jordidekock/Colorblinds.

/// Malfunctioning green cones.
Color deuteranomaly(Color color) => _applyMatrix(
  color,
  0.80,
  0.20,
  0.0,
  0.25833,
  0.74167,
  0.0,
  0.0,
  0.14167,
  0.85833,
);

/// Missing red cones.
Color protanopia(Color color) => _applyMatrix(
  color,
  0.56667,
  0.43333,
  0.0,
  0.55833,
  0.44167,
  0.0,
  0.0,
  0.24167,
  0.75833,
);

/// Missing green cones.
Color deuteranopia(Color color) =>
    _applyMatrix(color, 0.625, 0.375, 0.0, 0.7, 0.3, 0.0, 0.0, 0.3, 0.7);

/// Malfunctioning red cones.
Color protanomaly(Color color) => _applyMatrix(
  color,
  0.81667,
  0.18333,
  0.0,
  0.33333,
  0.66667,
  0.0,
  0.0,
  0.125,
  0.875,
);

/// Missing blue cones.
Color tritanopia(Color color) =>
    _applyMatrix(color, 0.95, 0.05, 0.0, 0.0, 0.43, 0.56, 0.0, 0.4755, 0.525);

/// Malfunctioning blue cones.
Color tritanomaly(Color color) => _applyMatrix(
  color,
  0.9667,
  0.033,
  0.0,
  0.0,
  0.733,
  0.2667,
  0.0,
  0.183,
  0.8167,
);

/// Less severe form of total color blindness (partial monochromacy).
Color achromatomaly(Color color) => _applyMatrix(
  color,
  0.618,
  0.32,
  0.062,
  0.163,
  0.775,
  0.062,
  0.163,
  0.32,
  0.516,
);

/// Total color blindness (monochromacy).
Color achromatopsia(Color color) => _applyMatrix(
  color,
  0.299,
  0.587,
  0.114,
  0.299,
  0.587,
  0.114,
  0.299,
  0.587,
  0.114,
);

Color _applyMatrix(
  Color color,
  double rr,
  double rg,
  double rb,
  double gr,
  double gg,
  double gb,
  double br,
  double bg,
  double bb,
) {
  final red = (color.r * rr + color.g * rg + color.b * rb).clamp(0.0, 1.0);
  final green = (color.r * gr + color.g * gg + color.b * gb).clamp(0.0, 1.0);
  final blue = (color.r * br + color.g * bg + color.b * bb).clamp(0.0, 1.0);

  return Color.from(
    alpha: color.a,
    red: red,
    green: green,
    blue: blue,
    colorSpace: color.colorSpace,
  );
}
