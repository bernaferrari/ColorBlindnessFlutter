import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:color_blindness/color_blindness.dart';

/// Archival warm-paper and obsidian studio palettes inspired by Chroma Folio.
class const StudioPalette({
  required final Color paper,
  required final Color surface,
  required final Color track,
  required final Color activePill,
  required final Color border,
  required final Color ink,
  required final Color inkMuted,
}) {
  static const light = StudioPalette(
    paper: Color(0xFFF6F4EE),
    surface: Color(0xFFFCFAF5),
    track: Color(0xFFECE9E1),
    activePill: Color(0xFFFFFFFF),
    border: Color(0xFFE0DDD4),
    ink: Color(0xFF191918),
    inkMuted: Color(0xFF6B6A66),
  );

  static const dark = StudioPalette(
    paper: Color(0xFF0C0D10),
    surface: Color(0xFF12141A),
    track: Color(0xFF16181F),
    activePill: Color(0xFF292C36),
    border: Color(0xFF262934),
    ink: Color(0xFFF3F1EC),
    inkMuted: Color(0xFF9EA0A8),
  );

  static StudioPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Code block constants.
abstract final class StudioColors {
  static const codeSurface = Color(0xFF141519);
  static const codeInk = Color(0xFFF0EFEA);
}

/// Filter options for comparing Original and Simulated specimens.
enum ComparisonView(final String label) {
  both('Compare'),
  original('Original'),
  simulated('Simulated'),
}

/// Curated stress-test seeds for red-green and blue-yellow vision deficiencies.
class const SeedPreset({
  required final String name,
  required final Color color,
});

/// Vibrant Material 3 seed presets showcased as inline color wells.
const seedPresets = <SeedPreset>[
  SeedPreset(name: 'Emerald', color: Color(0xFF006C51)),
  SeedPreset(name: 'Indigo', color: Color(0xFF3949AB)),
  SeedPreset(name: 'Cyan', color: Color(0xFF00838F)),
  SeedPreset(name: 'Crimson', color: Color(0xFFC62828)),
  SeedPreset(name: 'Amber', color: Color(0xFFE65100)),
  SeedPreset(name: 'Plum', color: Color(0xFF7B1FA2)),
];

/// Describes one color role in a swatch cluster.
class const ColorToken({
  required final String label,
  required final Color color,
});

/// Returns the 6 key role swatches for an accent dot cluster.
List<ColorToken> dotSwatchesFor(ColorScheme scheme) => [
  ColorToken(label: 'Primary', color: scheme.primary),
  ColorToken(label: 'Primary Container', color: scheme.primaryContainer),
  ColorToken(label: 'Secondary', color: scheme.secondary),
  ColorToken(label: 'Secondary Container', color: scheme.secondaryContainer),
  ColorToken(label: 'Tertiary', color: scheme.tertiary),
  ColorToken(label: 'Error', color: scheme.error),
];

/// Returns the 6 key swatches to display in the role grid.
List<ColorToken> swatchesFor(ColorScheme scheme) => [
  ColorToken(label: 'Primary', color: scheme.primary),
  ColorToken(label: 'Secondary', color: scheme.secondary),
  ColorToken(label: 'Tertiary', color: scheme.tertiary),
  ColorToken(label: 'Surface', color: scheme.surface),
  ColorToken(label: 'Container', color: scheme.surfaceContainerHigh),
  ColorToken(label: 'Error', color: scheme.error),
];

/// Encodes [color] as `#RRGGBB`.
String encodeHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Returns a Dart `Color(0xFF...)` literal for [color].
String encodeColorLiteral(Color color) =>
    'Color(0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})';

/// Picks readable black or white ink over [background].
Color readableInk(Color background) =>
    background.computeLuminance() > 0.179 ? Colors.black : Colors.white;

/// Builds a copy-ready `colorBlindnessColorScheme(...)` snippet.
String buildSchemeSnippet({
  required Color seedColor,
  required Brightness brightness,
  required ColorBlindnessType type,
}) {
  final colorLiteral = encodeColorLiteral(seedColor);
  return [
    'final baseScheme = ColorScheme.fromSeed(',
    '  seedColor: $colorLiteral,',
    '  brightness: Brightness.${brightness.name},',
    ');',
    '',
    'final simulatedScheme = baseScheme.simulateColorBlindness(',
    '  ColorBlindnessType.${type.name},',
    ');',
  ].join('\n');
}

/// Builds a CI contrast test snippet using `colorBlindnessAssertContrast`.
String buildContrastSnippet({
  required Color seedColor,
  required Brightness brightness,
}) {
  final colorLiteral = encodeColorLiteral(seedColor);
  return [
    "test('palette stays legible across color vision deficiencies', () {",
    '  final scheme = ColorScheme.fromSeed(',
    '    seedColor: $colorLiteral,',
    '    brightness: Brightness.${brightness.name},',
    '  );',
    '',
    '  colorBlindnessAssertContrast(scheme, 4.5);',
    '});',
  ].join('\n');
}

/// Copies [value] to the clipboard and notifies the user cleanly.
Future<void> copyWithFeedback(
  BuildContext context,
  String value, {
  String? label,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    _showSnackBar(messenger, 'Copied ${label ?? value}');
  } on PlatformException {
    if (!context.mounted) return;
    _showSnackBar(messenger, 'Clipboard unavailable');
  }
}

void _showSnackBar(ScaffoldMessengerState? messenger, String message) {
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
