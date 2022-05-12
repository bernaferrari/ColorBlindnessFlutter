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
    onPrimary: colorBlindness(scheme.onPrimary, type),
    primaryContainer: colorBlindness(scheme.primaryContainer, type),
    onPrimaryContainer: colorBlindness(scheme.onPrimaryContainer, type),
    secondary: colorBlindness(scheme.secondary, type),
    onSecondary: colorBlindness(scheme.onSecondary, type),
    secondaryContainer: colorBlindness(scheme.secondaryContainer, type),
    onSecondaryContainer: colorBlindness(scheme.onSecondaryContainer, type),
    tertiary: colorBlindness(scheme.tertiary, type),
    onTertiary: colorBlindness(scheme.onTertiary, type),
    tertiaryContainer: colorBlindness(scheme.tertiaryContainer, type),
    onTertiaryContainer: colorBlindness(scheme.onTertiaryContainer, type),
    error: colorBlindness(scheme.error, type),
    onError: colorBlindness(scheme.onError, type),
    errorContainer: colorBlindness(scheme.errorContainer, type),
    onErrorContainer: colorBlindness(scheme.onErrorContainer, type),
    background: colorBlindness(scheme.background, type),
    onBackground: colorBlindness(scheme.onBackground, type),
    surface: colorBlindness(scheme.surface, type),
    surfaceVariant: colorBlindness(scheme.surfaceVariant, type),
    onSurface: colorBlindness(scheme.onSurface, type),
    onSurfaceVariant: colorBlindness(scheme.onSurfaceVariant, type),
    outline: colorBlindness(scheme.outline, type),
    shadow: colorBlindness(scheme.shadow, type),
    inverseSurface: colorBlindness(scheme.inverseSurface, type),
    onInverseSurface: colorBlindness(scheme.onInverseSurface, type),
    inversePrimary: colorBlindness(scheme.inversePrimary, type),
    brightness: scheme.brightness,
  );
}
