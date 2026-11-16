import 'package:material_ui/material_ui.dart';

import 'color_blindness.dart';

/// Convenience simulation helper on any Material 3 [ColorScheme].
extension ColorBlindnessColorSchemeExtension on ColorScheme {
  /// Returns a copy of this scheme with every color role simulated under [type].
  ColorScheme simulateColorBlindness(ColorBlindnessType type) =>
      colorBlindnessColorScheme(this, type);
}

/// Simulates color blindness for every color role in a Material 3 [scheme].
///
/// Transforms each token individually via [colorBlindness] (keeping
/// `brightness` unchanged) rather than applying a full-screen shader, so you
/// can pass the resulting [ColorScheme] into [ThemeData] or run contrast
/// checks against simulated tokens via `colorBlindnessContrastIssues`.
///
/// Returns [scheme] unchanged when [type] is [ColorBlindnessType.none].
ColorScheme colorBlindnessColorScheme(
  ColorScheme scheme,
  ColorBlindnessType type,
) {
  if (type == ColorBlindnessType.none) return scheme;

  Color sim(Color color) => colorBlindness(color, type);

  return ColorScheme(
    brightness: scheme.brightness,
    primary: sim(scheme.primary),
    onPrimary: sim(scheme.onPrimary),
    primaryContainer: sim(scheme.primaryContainer),
    onPrimaryContainer: sim(scheme.onPrimaryContainer),
    primaryFixed: sim(scheme.primaryFixed),
    primaryFixedDim: sim(scheme.primaryFixedDim),
    onPrimaryFixed: sim(scheme.onPrimaryFixed),
    onPrimaryFixedVariant: sim(scheme.onPrimaryFixedVariant),
    secondary: sim(scheme.secondary),
    onSecondary: sim(scheme.onSecondary),
    secondaryContainer: sim(scheme.secondaryContainer),
    onSecondaryContainer: sim(scheme.onSecondaryContainer),
    secondaryFixed: sim(scheme.secondaryFixed),
    secondaryFixedDim: sim(scheme.secondaryFixedDim),
    onSecondaryFixed: sim(scheme.onSecondaryFixed),
    onSecondaryFixedVariant: sim(scheme.onSecondaryFixedVariant),
    tertiary: sim(scheme.tertiary),
    onTertiary: sim(scheme.onTertiary),
    tertiaryContainer: sim(scheme.tertiaryContainer),
    onTertiaryContainer: sim(scheme.onTertiaryContainer),
    tertiaryFixed: sim(scheme.tertiaryFixed),
    tertiaryFixedDim: sim(scheme.tertiaryFixedDim),
    onTertiaryFixed: sim(scheme.onTertiaryFixed),
    onTertiaryFixedVariant: sim(scheme.onTertiaryFixedVariant),
    error: sim(scheme.error),
    onError: sim(scheme.onError),
    errorContainer: sim(scheme.errorContainer),
    onErrorContainer: sim(scheme.onErrorContainer),
    surface: sim(scheme.surface),
    onSurface: sim(scheme.onSurface),
    surfaceDim: sim(scheme.surfaceDim),
    surfaceBright: sim(scheme.surfaceBright),
    surfaceContainerLowest: sim(scheme.surfaceContainerLowest),
    surfaceContainerLow: sim(scheme.surfaceContainerLow),
    surfaceContainer: sim(scheme.surfaceContainer),
    surfaceContainerHigh: sim(scheme.surfaceContainerHigh),
    surfaceContainerHighest: sim(scheme.surfaceContainerHighest),
    onSurfaceVariant: sim(scheme.onSurfaceVariant),
    outline: sim(scheme.outline),
    outlineVariant: sim(scheme.outlineVariant),
    shadow: sim(scheme.shadow),
    scrim: sim(scheme.scrim),
    inverseSurface: sim(scheme.inverseSurface),
    onInverseSurface: sim(scheme.onInverseSurface),
    inversePrimary: sim(scheme.inversePrimary),
    surfaceTint: sim(scheme.surfaceTint),
  );
}
