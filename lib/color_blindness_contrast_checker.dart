import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'color_blindness.dart';

/// Describes a foreground/background pair that fell below [threshold] WCAG
/// contrast under a simulated [ColorBlindnessType].
class ContrastCheckIssue {
  /// Creates an immutable [ContrastCheckIssue] diagnostic record.
  const ContrastCheckIssue({
    required this.type,
    required this.foregroundRole,
    required this.backgroundRole,
    required this.foreground,
    required this.background,
    required this.contrast,
    required this.threshold,
  });

  final ColorBlindnessType type;
  final String foregroundRole;
  final String backgroundRole;
  final Color foreground;
  final Color background;
  final double contrast;
  final double threshold;

  @override
  String toString() =>
      'Fail! For ${type.name}, $foregroundRole ($foreground) on $backgroundRole '
      '($background) got contrast ${contrast.toStringAsFixed(2)} (< $threshold)';
}

/// Computes the WCAG 2.1 relative luminance contrast ratio between two colors,
/// ranging from `1.0` to `21.0`.
double colorContrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final darker = min(firstLuminance, secondLuminance);
  final lighter = max(firstLuminance, secondLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Returns every contrast failure found when simulating [scheme] across [types].
///
/// Always checks `primary`/`surface` and `secondary`/`surface`. When
/// [includeOnRoles] is `true`, also checks Material 3 `on*` foreground/surface
/// and container pairs (`onPrimary`/`primary`, `onSecondary`/`secondary`,
/// `onTertiary`/`tertiary`, `onSurface`/`surface`, `onError`/`error`, and their
/// container counterparts).
List<ContrastCheckIssue> colorBlindnessContrastIssues(
  ColorScheme scheme, {
  double minThreshold = 4.5,
  bool includeOnRoles = true,
  List<ColorBlindnessType> types = ColorBlindnessType.values,
}) {
  final issues = <ContrastCheckIssue>[];

  for (final type in types) {
    final updated = colorBlindnessColorScheme(scheme, type);
    final pairs = <(String, Color, String, Color)>[
      ('primary', updated.primary, 'surface', updated.surface),
      ('secondary', updated.secondary, 'surface', updated.surface),
      if (includeOnRoles) ...[
        ('onPrimary', updated.onPrimary, 'primary', updated.primary),
        ('onSecondary', updated.onSecondary, 'secondary', updated.secondary),
        ('onTertiary', updated.onTertiary, 'tertiary', updated.tertiary),
        ('onSurface', updated.onSurface, 'surface', updated.surface),
        ('onError', updated.onError, 'error', updated.error),
        (
          'onPrimaryContainer',
          updated.onPrimaryContainer,
          'primaryContainer',
          updated.primaryContainer,
        ),
        (
          'onSecondaryContainer',
          updated.onSecondaryContainer,
          'secondaryContainer',
          updated.secondaryContainer,
        ),
        (
          'onTertiaryContainer',
          updated.onTertiaryContainer,
          'tertiaryContainer',
          updated.tertiaryContainer,
        ),
        (
          'onErrorContainer',
          updated.onErrorContainer,
          'errorContainer',
          updated.errorContainer,
        ),
      ],
    ];

    for (final (fgRole, fg, bgRole, bg) in pairs) {
      final contrast = colorContrastRatio(fg, bg);
      if (contrast < minThreshold) {
        issues.add(
          ContrastCheckIssue(
            type: type,
            foregroundRole: fgRole,
            backgroundRole: bgRole,
            foreground: fg,
            background: bg,
            contrast: contrast,
            threshold: minThreshold,
          ),
        );
      }
    }
  }

  return issues;
}

/// Simulates color blindness across every [ColorBlindnessType] and throws an
/// [Exception] if `primary` or `secondary` falls below [minThreshold] contrast
/// on `surface`.
///
/// Intended for CI checks and unit tests (typically `4.5` for AA or `7.0` for AAA).
void colorBlindnessAssertContrast(
  ColorScheme scheme, [
  double minThreshold = 4.5,
]) {
  final issues = colorBlindnessContrastIssues(
    scheme,
    minThreshold: minThreshold,
    includeOnRoles: false,
  );
  if (issues.isNotEmpty) {
    final first = issues.first;
    throw Exception(
      'Fail! For ${first.type.name}, ${first.foregroundRole} '
      '(${first.foreground}) on ${first.backgroundRole} '
      '(${first.background}) got value ${first.contrast.toStringAsFixed(2)}',
    );
  }
}
