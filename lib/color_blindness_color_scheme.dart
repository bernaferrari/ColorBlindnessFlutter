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
    brightness: scheme.brightness,
    primary: colorBlindness(scheme.primary, type),
    onPrimary: colorBlindness(scheme.onPrimary, type),
    primaryContainer: colorBlindness(scheme.primaryContainer, type),
    onPrimaryContainer: colorBlindness(scheme.onPrimaryContainer, type),
    primaryFixed: colorBlindness(scheme.primaryFixed, type),
    primaryFixedDim: colorBlindness(scheme.primaryFixedDim, type),
    onPrimaryFixed: colorBlindness(scheme.onPrimaryFixed, type),
    onPrimaryFixedVariant: colorBlindness(scheme.onPrimaryFixedVariant, type),
    secondary: colorBlindness(scheme.secondary, type),
    onSecondary: colorBlindness(scheme.onSecondary, type),
    secondaryContainer: colorBlindness(scheme.secondaryContainer, type),
    onSecondaryContainer: colorBlindness(scheme.onSecondaryContainer, type),
    secondaryFixed: colorBlindness(scheme.secondaryFixed, type),
    secondaryFixedDim: colorBlindness(scheme.secondaryFixedDim, type),
    onSecondaryFixed: colorBlindness(scheme.onSecondaryFixed, type),
    onSecondaryFixedVariant:
        colorBlindness(scheme.onSecondaryFixedVariant, type),
    tertiary: colorBlindness(scheme.tertiary, type),
    onTertiary: colorBlindness(scheme.onTertiary, type),
    tertiaryContainer: colorBlindness(scheme.tertiaryContainer, type),
    onTertiaryContainer: colorBlindness(scheme.onTertiaryContainer, type),
    tertiaryFixed: colorBlindness(scheme.tertiaryFixed, type),
    tertiaryFixedDim: colorBlindness(scheme.tertiaryFixedDim, type),
    onTertiaryFixed: colorBlindness(scheme.onTertiaryFixed, type),
    onTertiaryFixedVariant: colorBlindness(scheme.onTertiaryFixedVariant, type),
    error: colorBlindness(scheme.error, type),
    onError: colorBlindness(scheme.onError, type),
    errorContainer: colorBlindness(scheme.errorContainer, type),
    onErrorContainer: colorBlindness(scheme.onErrorContainer, type),
    surface: colorBlindness(scheme.surface, type),
    onSurface: colorBlindness(scheme.onSurface, type),
    surfaceDim: colorBlindness(scheme.surfaceDim, type),
    surfaceBright: colorBlindness(scheme.surfaceBright, type),
    surfaceContainerLowest: colorBlindness(scheme.surfaceContainerLowest, type),
    surfaceContainerLow: colorBlindness(scheme.surfaceContainerLow, type),
    surfaceContainer: colorBlindness(scheme.surfaceContainer, type),
    surfaceContainerHigh: colorBlindness(scheme.surfaceContainerHigh, type),
    surfaceContainerHighest:
        colorBlindness(scheme.surfaceContainerHighest, type),
    onSurfaceVariant: colorBlindness(scheme.onSurfaceVariant, type),
    outline: colorBlindness(scheme.outline, type),
    outlineVariant: colorBlindness(scheme.outlineVariant, type),
    shadow: colorBlindness(scheme.shadow, type),
    scrim: colorBlindness(scheme.scrim, type),
    inverseSurface: colorBlindness(scheme.inverseSurface, type),
    onInverseSurface: colorBlindness(scheme.onInverseSurface, type),
    inversePrimary: colorBlindness(scheme.inversePrimary, type),
    surfaceTint: colorBlindness(scheme.surfaceTint, type),
    background: colorBlindness(scheme.background, type),
    onBackground: colorBlindness(scheme.onBackground, type),
    surfaceVariant: colorBlindness(scheme.surfaceVariant, type),
  );
}
