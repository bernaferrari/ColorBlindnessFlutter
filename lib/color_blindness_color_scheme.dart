import 'package:flutter/material.dart';

import 'color_blindness.dart';

/// Simulates color blindness for every color in a ColorScheme.
///
/// Input:
/// ColorScheme: the ColorScheme you are using as your theme.
/// ColorBlindnessType: the type to be used.
///
/// Output:
/// a ColorScheme containing all colors modified.
ColorScheme colorBlindnessColorScheme(
  ColorScheme scheme,
  ColorBlindnessType type,
) {
  return ColorScheme(
    primary: colorBlindness(scheme.primary, type),
    primaryVariant: colorBlindness(scheme.primaryVariant, type),
    secondary: colorBlindness(scheme.secondary, type),
    secondaryVariant: colorBlindness(scheme.secondaryVariant, type),
    background: colorBlindness(scheme.background, type),
    surface: colorBlindness(scheme.surface, type),
    error: colorBlindness(scheme.error, type),
    onPrimary: colorBlindness(scheme.onPrimary, type),
    onSecondary: colorBlindness(scheme.onSecondary, type),
    onBackground: colorBlindness(scheme.onBackground, type),
    onSurface: colorBlindness(scheme.onSurface, type),
    onError: colorBlindness(scheme.onError, type),
    brightness: scheme.brightness,
  );
}
