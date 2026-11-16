import 'package:color_blindness/color_blindness.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulation keeps transparent scrims and colors transparent', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.purple)
        .copyWith(scrim: const Color(0x55336699));
    for (final type in ColorBlindnessType.values) {
      expect(colorBlindnessColorScheme(scheme, type).scrim.a, scheme.scrim.a);
    }
    expect(
      colorBlindnessColorScheme(scheme, ColorBlindnessType.none),
      same(scheme),
    );
  });

  test('simulation transforms fixed accents and tonal surfaces', () {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ).copyWith(
          primaryFixed: Colors.teal,
          onTertiaryFixedVariant: Colors.deepOrange,
          surfaceDim: Colors.indigo,
          surfaceBright: Colors.amber,
          surfaceContainerHighest: Colors.lime,
        );
    const type = ColorBlindnessType.tritanopia;
    final result = colorBlindnessColorScheme(scheme, type);
    expect(result.brightness, Brightness.dark);
    for (final (before, after) in [
      (scheme.primaryFixed, result.primaryFixed),
      (scheme.onTertiaryFixedVariant, result.onTertiaryFixedVariant),
      (scheme.surfaceDim, result.surfaceDim),
      (scheme.surfaceBright, result.surfaceBright),
      (scheme.surfaceContainerHighest, result.surfaceContainerHighest),
    ]) {
      expect(after, colorBlindness(before, type));
    }
  });

  test('test contrast CI', () {
    var colorScheme = ColorScheme.dark();
    expect(() => colorBlindnessAssertContrast(colorScheme), throwsException);

    colorScheme = ColorScheme.light();
    expect(() => colorBlindnessAssertContrast(colorScheme), throwsException);

    colorScheme = ColorScheme.light(
      primary: const Color(0xff9f0042),
      secondary: const Color(0xff1e6100),
    );
    expect(() => colorBlindnessAssertContrast(colorScheme), returnsNormally);

    colorScheme = ColorScheme.light(
      primary: const Color(0xff00263b),
      secondary: const Color(0xff390062),
    );
    expect(
      () => colorBlindnessAssertContrast(colorScheme, 7.5),
      returnsNormally,
    );
  });

  test('2026 extensions, enum metadata, and structured contrast check', () {
    const color = Color(0xCC24A16B);
    expect(
      color.simulateColorBlindness(ColorBlindnessType.deuteranopia),
      deuteranopia(color),
    );

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF006C51));
    expect(
      scheme.simulateColorBlindness(ColorBlindnessType.tritanopia),
      colorBlindnessColorScheme(scheme, ColorBlindnessType.tritanopia),
    );

    for (final type in ColorBlindnessType.values) {
      expect(type.label, isNotEmpty);
      expect(type.shortDescription, isNotEmpty);
    }

    expect(colorContrastRatio(Colors.black, Colors.white), closeTo(21.0, 0.01));

    final brokenScheme = ColorScheme.light(
      primary: const Color(0xFFB71C1C),
      onPrimary: const Color(0xFFD32F2F),
    );
    final issues = colorBlindnessContrastIssues(
      brokenScheme,
      types: const [ColorBlindnessType.none, ColorBlindnessType.deuteranopia],
    );
    expect(issues.any((issue) => issue.foregroundRole == 'onPrimary'), isTrue);
  });
}
