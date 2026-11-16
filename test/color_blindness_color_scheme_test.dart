import 'dart:ui' show ColorSpace;

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

  test('supports Display P3 and extendedSRGB colors', () {
    const p3Red = Color.from(
      alpha: 0.8,
      red: 1.0,
      green: 0.0,
      blue: 0.0,
      colorSpace: ColorSpace.displayP3,
    );
    const p3Gray = Color.from(
      alpha: 1.0,
      red: 0.5,
      green: 0.5,
      blue: 0.5,
      colorSpace: ColorSpace.displayP3,
    );

    const srgbGray = Color.from(alpha: 1.0, red: 0.5, green: 0.5, blue: 0.5);

    for (final type in ColorBlindnessType.values) {
      final simRed = p3Red.simulateColorBlindness(type);
      expect(simRed.colorSpace, ColorSpace.displayP3);
      expect(simRed.a, closeTo(0.8, 1e-6));

      final simGray = p3Gray.simulateColorBlindness(type);
      final srgbSimGray = srgbGray.simulateColorBlindness(type);
      expect(simGray.colorSpace, ColorSpace.displayP3);
      expect(simGray.r, closeTo(srgbSimGray.r, 1e-3));
      expect(simGray.g, closeTo(srgbSimGray.g, 1e-3));
      expect(simGray.b, closeTo(srgbSimGray.b, 1e-3));
    }

    // Achromatopsia on P3 primary red produces a neutral P3 gray (r == g == b)
    // reflecting P3 red luminance rather than naive sRGB 0.299 channel weight.
    final p3RedAchrom = achromatopsia(p3Red);
    expect(p3RedAchrom.r, closeTo(p3RedAchrom.g, 1e-4));
    expect(p3RedAchrom.g, closeTo(p3RedAchrom.b, 1e-4));
    expect(p3RedAchrom.r, lessThan(0.25));

    // In-gamut sRGB color expressed in P3 gives matching sRGB-equivalent output.
    const srgbSample = Color(0xFF2E7D32);
    final srgbAsP3 = srgbSample.withValues(colorSpace: ColorSpace.displayP3);
    final simSrgb = deuteranopia(srgbSample);
    final simP3ViaExt = deuteranopia(srgbAsP3)
        .withValues(colorSpace: ColorSpace.extendedSRGB);
    expect(simP3ViaExt.r, closeTo(simSrgb.r, 1e-3));
    expect(simP3ViaExt.g, closeTo(simSrgb.g, 1e-3));
    expect(simP3ViaExt.b, closeTo(simSrgb.b, 1e-3));

    // extendedSRGB keeps wide-gamut values outside [0, 1] and contrast works.
    final p3RedExt = p3Red.withValues(colorSpace: ColorSpace.extendedSRGB);
    expect(tritanopia(p3RedExt).r, greaterThan(1.0));
    expect(deuteranomaly(p3RedExt).b, lessThan(0.0));
    expect(deuteranomaly(p3RedExt).colorSpace, ColorSpace.extendedSRGB);
    expect(colorContrastRatio(p3Red, Colors.white), inInclusiveRange(3.5, 5.5));
    expect(
      colorContrastRatio(p3RedExt, Colors.black),
      closeTo(colorContrastRatio(p3Red, Colors.black), 1e-4),
    );
  });
}
