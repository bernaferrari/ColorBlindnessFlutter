import 'dart:math' as math;
import 'dart:ui';

// IEC 61966-2-1 sRGB transfer function constants (extended to negative values
// by odd symmetry for wide-gamut extended sRGB coordinates).
const double _kSrgbGamma = 2.4;
const double _kSrgbLinearThreshold = 0.04045;
const double _kSrgbLinearSlope = 12.92;
const double _kSrgbEncodedOffset = 0.055;
const double _kSrgbEncodedDivisor = 1.055;
const double _kSrgbLinearToEncodedThreshold = 0.0031308;

// Linear Display P3 -> Linear sRGB (D65, row-major 3x3).
const List<double> _kP3ToSrgbLinear = [
  1.2249401,
  -0.2249402,
  0.0,
  -0.0420569,
  1.0420571,
  0.0,
  -0.0196376,
  -0.0786507,
  1.0982884,
];

// Linear sRGB -> Linear Display P3 (inverse of [_kP3ToSrgbLinear], D65).
const List<double> _kSrgbToP3Linear = [
  0.8224622,
  0.1775380,
  0.0,
  0.0331942,
  0.9668058,
  0.0,
  0.0170806,
  0.0723974,
  0.9105220,
];

double _srgbEotf(double v) {
  final av = v.abs();
  final decoded = av <= _kSrgbLinearThreshold
      ? av / _kSrgbLinearSlope
      : math.pow((av + _kSrgbEncodedOffset) / _kSrgbEncodedDivisor, _kSrgbGamma)
            as double;
  return v < 0.0 ? -decoded : decoded;
}

double _srgbOetf(double v) {
  final av = v.abs();
  final encoded = av <= _kSrgbLinearToEncodedThreshold
      ? av * _kSrgbLinearSlope
      : _kSrgbEncodedDivisor * (math.pow(av, 1.0 / _kSrgbGamma) as double) -
            _kSrgbEncodedOffset;
  return v < 0.0 ? -encoded : encoded;
}

(double, double, double) _mul3x3(
  List<double> m,
  double r,
  double g,
  double b,
) => (
  m[0] * r + m[1] * g + m[2] * b,
  m[3] * r + m[4] * g + m[5] * b,
  m[6] * r + m[7] * g + m[8] * b,
);

/// Converts gamma-encoded Display P3 `(r, g, b)` to gamma-encoded extended sRGB
/// coordinates (which may fall outside `[0.0, 1.0]` for wide-gamut colors).
(double, double, double) displayP3ToExtendedSrgb(double r, double g, double b) {
  final (ro, go, bo) = _mul3x3(
    _kP3ToSrgbLinear,
    _srgbEotf(r),
    _srgbEotf(g),
    _srgbEotf(b),
  );
  return (_srgbOetf(ro), _srgbOetf(go), _srgbOetf(bo));
}

/// Converts gamma-encoded extended sRGB `(r, g, b)` back to Display P3,
/// clamped to `[0.0, 1.0]`.
(double, double, double) extendedSrgbToDisplayP3(double r, double g, double b) {
  final (ro, go, bo) = _mul3x3(
    _kSrgbToP3Linear,
    _srgbEotf(r),
    _srgbEotf(g),
    _srgbEotf(b),
  );
  return (
    _srgbOetf(ro).clamp(0.0, 1.0),
    _srgbOetf(go).clamp(0.0, 1.0),
    _srgbOetf(bo).clamp(0.0, 1.0),
  );
}

/// Computes CIE relative luminance (`Y` in `[0.0, 1.0]`) for sRGB, Display P3,
/// and extended sRGB colors.
double relativeLuminance(Color color) {
  return switch (color.colorSpace) {
    ColorSpace.sRGB => color.computeLuminance(),
    ColorSpace.extendedSRGB =>
      (0.2126 * _srgbEotf(color.r) +
              0.7152 * _srgbEotf(color.g) +
              0.0722 * _srgbEotf(color.b))
          .clamp(0.0, 1.0),
    ColorSpace.displayP3 => (() {
      final (rLin, gLin, bLin) = _mul3x3(
        _kP3ToSrgbLinear,
        _srgbEotf(color.r),
        _srgbEotf(color.g),
        _srgbEotf(color.b),
      );
      return (0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin).clamp(0.0, 1.0);
    })(),
  };
}
