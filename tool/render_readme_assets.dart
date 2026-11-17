// Generates the README hero animation for `color_blindness`:
//   - build/readme_frames/hero/*.png -> doc/screenshots/hero.webp
//
// Run via `./tool/generate_assets.sh` (downloads fonts into build/readme_fonts;
// requires `flutter`, `curl`, `ffmpeg`, and `img2webp`).
//
// Visual language (shared with random_color_scheme): the app icon's ink
// background, Instrument Serif wordmark, and mini phones wearing Material 3
// schemes. This package's motif is the icon's eye, its iris a color wheel: each
// kind of color vision sweeps around the wheel, then across three themed apps.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:color_blindness/color_blindness.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const double _width = 760.0;
const double _height = 420.0;
const double _dpr = 2.0;

const int _framesPerType = 56;
const int _wedgeFrames = 10;
const int _phoneFrames = 12;

const Color _ink = Color(0xFF191918);
const Color _paper = Color(0xFFF6F4EE);
const Color _muted = Color(0xFF9EA0A8);
const Color _irisGreen = Color(0xFF10B981);
const Color _irisGold = Color(0xFFD4A72C);

const List<ColorBlindnessType> _types = [
  ColorBlindnessType.none,
  ColorBlindnessType.protanopia,
  ColorBlindnessType.deuteranopia,
  ColorBlindnessType.tritanopia,
  ColorBlindnessType.achromatopsia,
];

/// Twelve hues around the iris, starting at red on top.
final List<Color> _wheel = [
  for (var i = 0; i < 12; i++)
    HSLColor.fromAHSL(1, i * 30.0, 0.82, 0.56).toColor(),
];

/// Three of the example app's seed presets: crimson, emerald, indigo.
final List<ColorScheme> _apps = [
  for (final (seed, brightness) in [
    (const Color(0xFFC62828), Brightness.light),
    (const Color(0xFF006C51), Brightness.dark),
    (const Color(0xFF3949AB), Brightness.light),
  ])
    ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ),
];

// Typography ------------------------------------------------------------------

typedef _Span = (String, TextStyle);

TextStyle _serif(double size, Color color) => TextStyle(
  fontFamily: 'Serif',
  fontSize: size,
  color: color,
  letterSpacing: -size * 0.01,
);

TextStyle _sans(double size, Color color, {double weight = 450}) => TextStyle(
  fontFamily: 'Sans',
  fontSize: size,
  color: color,
  fontWeight: FontWeight.values[(weight / 100).round() - 1],
  fontVariations: [FontVariation('wght', weight)],
);

enum _Anchor { start, center, end }

void _text(
  Canvas canvas,
  List<_Span> spans, {
  required double x,
  required double baseline,
  _Anchor anchor = _Anchor.start,
}) {
  final painter = TextPainter(
    text: TextSpan(
      children: [
        for (final (text, style) in spans) TextSpan(text: text, style: style),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final baselineOffset = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  final dx = switch (anchor) {
    _Anchor.start => x,
    _Anchor.center => x - painter.width / 2,
    _Anchor.end => x - painter.width,
  };
  painter.paint(canvas, Offset(dx, baseline - baselineOffset));
  painter.dispose();
}

// Motion ----------------------------------------------------------------------

double _ease(double x) {
  final t = x.clamp(0.0, 1.0);
  return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
}

// Brand -----------------------------------------------------------------------

/// The icon's almond outline in its 108-unit artboard, centered on (54, 54).
Path _eyeOutline(Offset center, double scale) {
  Offset p(double x, double y) =>
      center + Offset((x - 54) * scale, (y - 54) * scale);
  final a = p(25, 54);
  final path = Path()..moveTo(a.dx, a.dy);
  void cubic(List<double> v) {
    final c1 = p(v[0], v[1]);
    final c2 = p(v[2], v[3]);
    final end = p(v[4], v[5]);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }

  cubic([32.5, 39, 43, 34.5, 54, 34.5]);
  cubic([65, 34.5, 75.5, 39, 83, 54]);
  cubic([75.5, 69, 65, 73.5, 54, 73.5]);
  cubic([43, 73.5, 32.5, 69, 25, 54]);
  return path..close();
}

/// The app icon exactly as `doc/brand/app-icon.svg` draws it.
void _paintAppIcon(Canvas canvas, Rect rect) {
  final scale = rect.width / 72;
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(16 * scale)));
  canvas.drawRect(rect, Paint()..color = _ink);
  final center = rect.center;
  canvas.drawPath(
    _eyeOutline(center, scale),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeJoin = StrokeJoin.round
      ..color = _paper,
  );
  final iris = Rect.fromCircle(center: center, radius: 14.5 * scale);
  canvas.drawArc(iris, math.pi / 2, math.pi, true, Paint()..color = _irisGreen);
  canvas.drawArc(iris, -math.pi / 2, math.pi, true, Paint()..color = _irisGold);
  canvas.drawCircle(center, 6 * scale, Paint()..color = _ink);
  canvas.drawCircle(
    center + Offset(-3.5 * scale, -4 * scale),
    2 * scale,
    Paint()..color = _paper,
  );
  canvas.restore();
}

/// The icon's eye at poster size, its iris a twelve-hue wheel.
void _paintBigEye(
  Canvas canvas,
  Offset center,
  double scale,
  List<Color> hues,
) {
  canvas.drawPath(
    _eyeOutline(center, scale),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeJoin = StrokeJoin.round
      ..color = _paper,
  );
  final radius = 14.5 * scale;
  final iris = Rect.fromCircle(center: center, radius: radius);
  const sweep = 2 * math.pi / 12;
  for (var i = 0; i < hues.length; i++) {
    canvas.drawArc(
      iris,
      -math.pi / 2 - sweep / 2 + i * sweep,
      sweep,
      true,
      Paint()..color = hues[i],
    );
  }
  final seam = Paint()
    ..color = _ink
    ..strokeWidth = 2.5;
  for (var i = 0; i < hues.length; i++) {
    final angle = -math.pi / 2 - sweep / 2 + i * sweep;
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * (radius + 1),
      seam,
    );
  }
  canvas.drawCircle(center, 6 * scale, Paint()..color = _ink);
  // The icon's catchlight straddles the iris; here it stays inside the pupil
  // so no hue on the wheel is covered.
  canvas.drawCircle(
    center + Offset(-2.3 * scale, -2.6 * scale),
    1.5 * scale,
    Paint()..color = _paper,
  );
}

// Mini phone (shared with random_color_scheme) --------------------------------

void _paintPhone(Canvas canvas, Rect rect, ColorScheme s) {
  final w = rect.width;
  final frame = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.16));
  canvas.drawRRect(frame, Paint()..color = s.surface);
  canvas.save();
  canvas.clipRRect(frame);

  final p = w * 0.09;
  final left = rect.left + p;
  final right = rect.right - p;

  // App bar: title and avatar.
  final barY = rect.top + w * 0.2;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, barY - w * 0.035, w * 0.42, w * 0.07),
      Radius.circular(w * 0.035),
    ),
    Paint()..color = s.onSurface,
  );
  canvas.drawCircle(
    Offset(right - w * 0.07, barY),
    w * 0.07,
    Paint()..color = s.tertiaryContainer,
  );

  // Hero card.
  final hero = Rect.fromLTRB(left, barY + w * 0.14, right, barY + w * 0.66);
  canvas.drawRRect(
    RRect.fromRectAndRadius(hero, Radius.circular(w * 0.09)),
    Paint()..color = s.primaryContainer,
  );
  _text(
    canvas,
    [('Aa', _serif(w * 0.27, s.onPrimaryContainer))],
    x: hero.left + w * 0.07,
    baseline: hero.top + w * 0.3,
  );
  final track = Rect.fromLTRB(
    hero.left + w * 0.07,
    hero.bottom - w * 0.11,
    hero.right - w * 0.07,
    hero.bottom - w * 0.07,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(track, Radius.circular(w * 0.02)),
    Paint()..color = s.onPrimaryContainer.withValues(alpha: 0.18),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(
        track.left,
        track.top,
        track.left + track.width * 0.62,
        track.bottom,
      ),
      Radius.circular(w * 0.02),
    ),
    Paint()..color = s.primary,
  );

  // Chips.
  final chipY = hero.bottom + w * 0.1;
  final chipH = w * 0.13;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, chipY, w * 0.34, chipH),
      Radius.circular(chipH / 2),
    ),
    Paint()..color = s.secondaryContainer,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left + w * 0.38, chipY, w * 0.26, chipH),
      Radius.circular(chipH / 2),
    ),
    Paint()..color = s.tertiaryContainer,
  );

  // List rows.
  for (var i = 0; i < 2; i++) {
    final y = chipY + chipH + w * 0.16 + i * w * 0.22;
    canvas.drawCircle(
      Offset(left + w * 0.07, y),
      w * 0.07,
      Paint()..color = i == 0 ? s.secondary : s.tertiary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + w * 0.19, y - w * 0.05, w * 0.36, w * 0.045),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = s.onSurface.withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + w * 0.19, y + w * 0.015, w * 0.24, w * 0.035),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = s.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }

  // Navigation bar with the active destination.
  final nav = Rect.fromLTRB(
    rect.left,
    rect.bottom - w * 0.26,
    rect.right,
    rect.bottom,
  );
  canvas.drawRect(nav, Paint()..color = s.surfaceContainer);
  for (var i = 0; i < 3; i++) {
    final c = Offset(rect.left + w * (0.22 + i * 0.28), nav.top + w * 0.12);
    if (i == 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: w * 0.24, height: w * 0.12),
          Radius.circular(w * 0.06),
        ),
        Paint()..color = s.secondaryContainer,
      );
    }
    canvas.drawCircle(
      c,
      w * 0.03,
      Paint()..color = i == 0 ? s.onSecondaryContainer : s.onSurfaceVariant,
    );
  }

  // Floating action button.
  final fab = Rect.fromLTWH(
    right - w * 0.24,
    nav.top - w * 0.3,
    w * 0.24,
    w * 0.24,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(fab, Radius.circular(w * 0.07)),
    Paint()..color = s.primary,
  );
  final plus = Paint()
    ..color = s.onPrimary
    ..strokeWidth = w * 0.025
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
    fab.center - Offset(w * 0.05, 0),
    fab.center + Offset(w * 0.05, 0),
    plus,
  );
  canvas.drawLine(
    fab.center - Offset(0, w * 0.05),
    fab.center + Offset(0, w * 0.05),
    plus,
  );

  canvas.restore();
  canvas.drawRRect(
    frame,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _paper.withValues(alpha: 0.14),
  );
}

// Frame -----------------------------------------------------------------------

void _paintFrame(Canvas canvas, int frame) {
  final index = frame ~/ _framesPerType;
  final local = frame % _framesPerType;
  final type = _types[index];
  final next = _types[(index + 1) % _types.length];
  // Each beat holds its type first, then hands over to the next one.
  final change = local - (_framesPerType - 30);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, _width, _height),
      const Radius.circular(28),
    ),
    Paint()..color = _ink,
  );

  _paintAppIcon(canvas, const Rect.fromLTWH(32, 26, 40, 40));
  _text(canvas, [('Color Blindness', _serif(32, _paper))], x: 86, baseline: 57);

  // The eye: hues hand over one wedge at a time, clockwise from the top.
  final hues = [
    for (var i = 0; i < _wheel.length; i++)
      Color.lerp(
        _wheel[i].simulateColorBlindness(type),
        _wheel[i].simulateColorBlindness(next),
        _ease((change - i) / _wedgeFrames),
      )!,
  ];
  const eyeCenter = Offset(206, 218);
  _paintBigEye(canvas, eyeCenter, 5.0, hues);

  final labelOut = _ease((change - 4) / 7);
  final labelIn = _ease((change - 11) / 8);
  for (final (shown, alpha, dy) in [
    (type, 1 - labelOut, -8 * labelOut),
    (next, labelIn, 8 * (1 - labelIn)),
  ]) {
    if (alpha <= 0.001) continue;
    final name = shown == ColorBlindnessType.none
        ? 'Normal vision'
        : shown.label;
    final note = shown == ColorBlindnessType.none
        ? 'Full trichromatic color'
        : shown.shortDescription;
    _text(
      canvas,
      [(name, _serif(34, _paper.withValues(alpha: alpha)))],
      x: eyeCenter.dx,
      baseline: 374 + dy,
      anchor: _Anchor.center,
    );
    _text(
      canvas,
      [(note, _sans(13, _muted.withValues(alpha: alpha)))],
      x: eyeCenter.dx,
      baseline: 396 + dy,
      anchor: _Anchor.center,
    );
  }

  // Three themed apps, seen through the same eyes.
  const phoneWidth = 100.0;
  const phoneHeight = 214.0;
  const gap = 16.0;
  const phonesLeft = _width - 32 - phoneWidth * 3 - gap * 2;
  for (var i = 0; i < _apps.length; i++) {
    final t = _ease((change - 8 - i * 4) / _phoneFrames);
    final scheme = ColorScheme.lerp(
      _apps[i].simulateColorBlindness(type),
      _apps[i].simulateColorBlindness(next),
      t,
    );
    final rise = i == 1 ? -18.0 : 0.0;
    _paintPhone(
      canvas,
      Rect.fromLTWH(
        phonesLeft + i * (phoneWidth + gap),
        eyeCenter.dy - phoneHeight / 2 + rise + 14,
        phoneWidth,
        phoneHeight,
      ),
      scheme,
    );
  }
}

// Rendering -------------------------------------------------------------------

Future<void> _loadFonts() async {
  Future<void> load(String family, String file) async {
    final font = File('build/readme_fonts/$file');
    if (!font.existsSync()) {
      throw StateError(
        'Missing ${font.path}. Run ./tool/generate_assets.sh to fetch fonts.',
      );
    }
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
    await loader.load();
  }

  await load('Serif', 'InstrumentSerif-Regular.ttf');
  await load('Sans', 'InstrumentSans.ttf');
}

void main() {
  test('render color_blindness README hero', () async {
    await _loadFonts();
    final frames = _types.length * _framesPerType;
    for (var frame = 0; frame < frames; frame++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(_dpr, _dpr);
      _paintFrame(canvas, frame);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (_width * _dpr).round(),
        (_height * _dpr).round(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final name = frame.toString().padLeft(4, '0');
      File('build/readme_frames/hero/frame_$name.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  }, timeout: Timeout.none);
}
