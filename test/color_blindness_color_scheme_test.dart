import 'package:color_blindness/color_blindness_contrast_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        () => colorBlindnessAssertContrast(colorScheme, 7.5), returnsNormally);
  });
}
