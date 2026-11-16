/// Simulates eight types of color vision deficiency (CVD) on Flutter [Color]
/// values and Material 3 [ColorScheme]s.
///
/// ## How the simulation works
///
/// Human photopic vision relies on three retinal cone types sensitive to long
/// (L, red), medium (M, green), and short (S, blue) wavelengths:
///
/// - **Anomalous trichromacy** (`-anomaly`): all three cone types are present,
///   but one has shifted spectral sensitivity.
/// - **Dichromacy** (`-opia`): one cone type is completely absent.
/// - **Monochromacy** (`achromatopsia`, `achromatomaly`): cone color
///   discrimination is absent or severely diminished.
///
/// Each transform multiplies the input color's normalized `[r, g, b]` channels
/// by a 3×3 channel-mixing matrix whose rows sum to `~1.0` (preserving neutral
/// grays while collapsing hues along the affected confusion lines):
///
/// - **Protan / Deutan (red–green)**: blend `r` and `g` together and add a small
///   `g -> b` shift so greens/reds move toward indistinguishable yellows/browns
///   while blue–yellow contrast stays mostly intact.
/// - **Tritan (blue–yellow)**: keep `r` largely intact (small `r/g` mix) and
///   heavily mix `g` and `b`, collapsing blues toward greens/cyans and yellows
///   toward pinks/grays.
/// - **Achromatopsia / Achromatomaly**: project channels toward luminance
///   (`achromatopsia` uses ITU-R BT.601 weights `0.299 R + 0.587 G + 0.114 B`).
///
/// ## Accuracy & wide-gamut (`displayP3` / `extendedSRGB`) support
///
/// These matrices are adapted from https://github.com/jdekock/Colorblinds and
/// trace back to the Matthew Wickline / HCIRN RGB-filter approximations for
/// sRGB primaries. Because they multiply encoded sRGB components directly
/// instead of linearizing into LMS cone space (as in Brettel et al. 1997,
/// Viénot et al. 1999, or Machado et al. 2009), treat them as fast,
/// lightweight **visual approximations** for UI accessibility previews rather
/// than exact colorimetric simulations.
///
/// Colors in [ColorSpace.displayP3] are converted to extended sRGB before
/// applying the matrix and converted back to [ColorSpace.displayP3] (avoiding
/// sRGB gamut clipping on intermediate wide-gamut values), while
/// [ColorSpace.extendedSRGB] preserves out-of-`[0.0, 1.0]` coordinates.
///
/// Further reading:
/// - Understanding LMS & CVD simulation models:
///   https://daltonlens.org/understanding-cvd-simulation/
/// - 3×3 matrix filters vs. physiological LMS models:
///   https://daltonlens.org/cvd-simulation-svg-filters/
/// - WCAG 2.1 contrast ratio specification:
///   https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
library;

import 'dart:ui';

import 'src/color_space_math.dart';

export 'package:color_blindness/color_blindness_color_scheme.dart';
export 'package:color_blindness/color_blindness_contrast_checker.dart';

/// Color vision deficiency simulation modes.
///
/// Includes [none] as an identity pass-through convenience.
enum ColorBlindnessType {
  /// Standard trichromatic vision (no transformation applied).
  none('Normal vision', 'Full trichromatic vision'),

  /// Red-weak trichromacy (shifted L-cone sensitivity).
  protanomaly('Protanomaly', 'Red-weak trichromacy'),

  /// Green-weak trichromacy (shifted M-cone sensitivity).
  deuteranomaly('Deuteranomaly', 'Green-weak trichromacy'),

  /// Blue-weak trichromacy (shifted S-cone sensitivity).
  tritanomaly('Tritanomaly', 'Blue-weak trichromacy'),

  /// Red-blind dichromacy (missing L-cones).
  protanopia('Protanopia', 'Red-blind dichromacy'),

  /// Green-blind dichromacy (missing M-cones).
  deuteranopia('Deuteranopia', 'Green-blind dichromacy'),

  /// Blue-blind dichromacy (missing S-cones).
  tritanopia('Tritanopia', 'Blue-blind dichromacy'),

  /// Complete monochromacy (rod/luminance vision only; no cone color perception).
  achromatopsia('Achromatopsia', 'Complete monochromacy'),

  /// Partial monochromacy (severely muted color perception across all channels).
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
///
/// Applies the 3×3 RGB approximation corresponding to [type], preserving
/// [Color.a] and [Color.colorSpace]. Returns [color] unchanged when [type] is
/// [ColorBlindnessType.none].
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

// Matrices adapted from https://github.com/jdekock/Colorblinds (originally
// derived from Matthew Wickline / HCIRN RGB simulation matrices).
//
// Each 3x3 matrix maps normalized `(r, g, b)` channels as:
//   r' = rr*r + rg*g + rb*b
//   g' = gr*r + gg*g + gb*b
//   b' = br*r + bg*g + bb*b
// with rows summing to ~1.0 so neutral grays (`r == g == b`) stay unchanged.

/// Simulates **deuteranomaly** (malfunctioning / shifted M-cones).
///
/// Mildly mixes red (`0.20`) into red output and shifts green (`0.74167`) and
/// blue slightly, reducing subtle green–red contrast while retaining most hue.
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

/// Simulates **protanopia** (missing L-cones; red-blind dichromacy).
///
/// Heavily mixes red and green into nearly overlapping weights so pure reds and
/// greens collapse toward muted olive/yellow-brown hues, while blue stays clear.
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

/// Simulates **deuteranopia** (missing M-cones; green-blind dichromacy).
///
/// Collapses red and green along red–green confusion lines (`0.625/0.375` and
/// `0.7/0.3`), shifting green toward amber/beige and mixing some green into blue.
Color deuteranopia(Color color) =>
    _applyMatrix(color, 0.625, 0.375, 0.0, 0.7, 0.3, 0.0, 0.0, 0.3, 0.7);

/// Simulates **protanomaly** (malfunctioning / shifted L-cones).
///
/// Partially blends red and green (`0.81667/0.18333` and `0.33333/0.66667`),
/// representing a milder form of [protanopia].
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

/// Simulates **tritanopia** (missing S-cones; blue-blind dichromacy).
///
/// Keeps red nearly pure (`0.95/0.05`) while strongly coupling green and blue
/// (`0.43/0.56` and `0.4755/0.525`), turning blues greenish and yellows pink/gray.
Color tritanopia(Color color) =>
    _applyMatrix(color, 0.95, 0.05, 0.0, 0.0, 0.43, 0.56, 0.0, 0.4755, 0.525);

/// Simulates **tritanomaly** (malfunctioning / shifted S-cones).
///
/// Milder blue–yellow green/blue coupling (`0.733/0.2667` and `0.183/0.8167`)
/// compared to [tritanopia].
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

/// Simulates **achromatomaly** (partial monochromacy / low cone sensitivity).
///
/// Pulls all three channels heavily toward perceived luminance while preserving
/// roughly half of each channel's dominant primary contribution.
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

/// Simulates **achromatopsia** (complete monochromacy; grayscale vision).
///
/// Replaces all three RGB channels with the ITU-R BT.601 weighted luma
/// (`0.299 * r + 0.587 * g + 0.114 * b`), producing a neutral gray with matched
/// brightness perception.
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

/// Multiplies [color]'s normalized RGB channels by a row-major 3×3 matrix.
///
/// Preserves [Color.a] and [Color.colorSpace]. For [ColorSpace.sRGB], outputs
/// are clamped to `[0.0, 1.0]`. For [ColorSpace.displayP3], the color is mapped
/// through extended sRGB so the sRGB-calibrated CVD matrix applies consistently
/// to Display P3 colors before converting back to [ColorSpace.displayP3]. For
/// [ColorSpace.extendedSRGB], wide-gamut coordinates outside `[0.0, 1.0]` are
/// preserved unclamped.
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
  final (srcR, srcG, srcB) = switch (color.colorSpace) {
    ColorSpace.displayP3 => displayP3ToExtendedSrgb(color.r, color.g, color.b),
    ColorSpace.sRGB || ColorSpace.extendedSRGB => (color.r, color.g, color.b),
  };

  final simR = srcR * rr + srcG * rg + srcB * rb;
  final simG = srcR * gr + srcG * gg + srcB * gb;
  final simB = srcR * br + srcG * bg + srcB * bb;

  final (outR, outG, outB) = switch (color.colorSpace) {
    ColorSpace.sRGB => (
      simR.clamp(0.0, 1.0),
      simG.clamp(0.0, 1.0),
      simB.clamp(0.0, 1.0),
    ),
    ColorSpace.extendedSRGB => (simR, simG, simB),
    ColorSpace.displayP3 => extendedSrgbToDisplayP3(simR, simG, simB),
  };

  return Color.from(
    alpha: color.a,
    red: outR,
    green: outG,
    blue: outB,
    colorSpace: color.colorSpace,
  );
}
