import 'dart:math' as math;

import 'package:color_blindness/color_blindness.dart';
import 'package:material_ui/material_ui.dart';

import '../studio_model.dart';
import 'studio_controls.dart';

/// Identifies each side-by-side Material 3 specimen shown in the comparison feed.
enum SpecimenKind(final String title) {
  editorial('Design Journal'),
  player('Midnight Synth'),
  analytics('Weekly Focus'),
  tasks('Release Checklist'),
}

/// Renders one [SpecimenKind] comparing [original] and [simulated] schemes
/// side by side with interruptible reveal transitions for [comparisonView].
class const ComparisonPairRow({
  super.key,
  required final SpecimenKind kind,
  required final ColorScheme original,
  required final ColorScheme simulated,
  required final ColorBlindnessType simulation,
  required final ComparisonView comparisonView,
  required final VoidCallback onOpenCode,
}) extends StatefulWidget {
  @override
  State<ComparisonPairRow> createState() => _ComparisonPairRowState();
}

class _ComparisonPairRowState extends State<ComparisonPairRow>
    with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 260);

  late final AnimationController _origController;
  late final AnimationController _simController;
  late final Animation<double> _origCurve;
  late final Animation<double> _simCurve;

  bool get _wantOrig => widget.comparisonView != ComparisonView.simulated;
  bool get _wantSim => widget.comparisonView != ComparisonView.original;

  @override
  void initState() {
    super.initState();
    _origController = AnimationController(
      vsync: this,
      duration: _duration,
      value: _wantOrig ? 1.0 : 0.0,
    );
    _simController = AnimationController(
      vsync: this,
      duration: _duration,
      value: _wantSim ? 1.0 : 0.0,
    );
    _origCurve = CurvedAnimation(
      parent: _origController,
      curve: kStudioEaseInOut,
    );
    _simCurve = CurvedAnimation(
      parent: _simController,
      curve: kStudioEaseInOut,
    );
  }

  @override
  void didUpdateWidget(covariant ComparisonPairRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comparisonView != widget.comparisonView) {
      final disableMotion = MediaQuery.disableAnimationsOf(context);
      final targetDuration = disableMotion ? Duration.zero : _duration;
      _origController.duration = targetDuration;
      _simController.duration = targetDuration;
      _origController.animateTo(_wantOrig ? 1.0 : 0.0);
      _simController.animateTo(_wantSim ? 1.0 : 0.0);
    }
  }

  @override
  void dispose() {
    _origController.dispose();
    _simController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final sideBySide = maxWidth >= 860;
        const gap = 16.0;

        return AnimatedBuilder(
          animation: Listenable.merge([_origCurve, _simCurve]),
          builder: (context, _) {
            final o = _origCurve.value;
            final s = _simCurve.value;

            final originalCard = _SpecimenCard(
              kind: widget.kind,
              laneLabel: 'Original',
              scheme: widget.original,
              onOpenCode: widget.onOpenCode,
            );
            final simulatedCard = _SpecimenCard(
              kind: widget.kind,
              laneLabel: widget.simulation.label,
              scheme: widget.simulated,
              onOpenCode: widget.onOpenCode,
            );

            if (!sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (o > 0.0)
                    _VerticalRevealSlot(factor: o, child: originalCard),
                  if (o > 0.0 && s > 0.0) SizedBox(height: 12 * o * s),
                  if (s > 0.0)
                    _VerticalRevealSlot(factor: s, child: simulatedCard),
                ],
              );
            }

            final halfWidth = (maxWidth - gap) / 2;
            final activeSum = math.max(1.0, o + s);
            final animatedGap = gap * o * s;
            final available = maxWidth - animatedGap;
            final origWidth = available * (o / activeSum);
            final simWidth = available * (s / activeSum);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (o > 0.0)
                  _HorizontalRevealSlot(
                    slotWidth: origWidth,
                    minLayoutWidth: halfWidth,
                    factor: o,
                    alignment: Alignment.topLeft,
                    child: originalCard,
                  ),
                if (animatedGap > 0.0) SizedBox(width: animatedGap),
                if (s > 0.0)
                  _HorizontalRevealSlot(
                    slotWidth: simWidth,
                    minLayoutWidth: halfWidth,
                    factor: s,
                    alignment: Alignment.topRight,
                    child: simulatedCard,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class const _HorizontalRevealSlot({
  required final double slotWidth,
  required final double minLayoutWidth,
  required final double factor,
  required final Alignment alignment,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final layoutWidth = math.max(slotWidth, minLayoutWidth);
    final widthFactor = (slotWidth / layoutWidth).clamp(0.0, 1.0);
    final scale = 0.96 + 0.04 * factor;

    return ClipRect(
      child: Align(
        alignment: alignment,
        widthFactor: widthFactor,
        child: SizedBox(
          width: layoutWidth,
          child: Opacity(
            opacity: factor.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class const _VerticalRevealSlot({
  required final double factor,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scale = 0.96 + 0.04 * factor;
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: factor.clamp(0.0, 1.0),
        child: Opacity(
          opacity: factor.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        ),
      ),
    );
  }
}

class const _SpecimenCard({
  required final SpecimenKind kind,
  required final String laneLabel,
  required final ColorScheme scheme,
  required final VoidCallback onOpenCode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = scheme.brightness == Brightness.dark;
    final motionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    final canvas = !isDark
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerLowest;
    final cardSurface = isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLowest;
    final canvasInk = readableInk(canvas);
    final swatches = dotSwatchesFor(scheme);

    final previewTheme = ThemeData(
      colorScheme: scheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );

    final specimen = switch (kind) {
      SpecimenKind.editorial => _EditorialSpecimen(
        scheme: scheme,
        surface: cardSurface,
        duration: motionDuration,
      ),
      SpecimenKind.player => _AudioPlayerSpecimen(
        scheme: scheme,
        surface: cardSurface,
        duration: motionDuration,
      ),
      SpecimenKind.analytics => _AnalyticsSpecimen(
        scheme: scheme,
        surface: cardSurface,
        duration: motionDuration,
      ),
      SpecimenKind.tasks => _TasksSpecimen(
        scheme: scheme,
        surface: cardSurface,
        duration: motionDuration,
      ),
    };

    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (context) {
          return AnimatedContainer(
            duration: motionDuration,
            curve: kStudioEaseOut,
            decoration: BoxDecoration(
              color: canvas,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : StudioPalette.of(context).border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: canvasInk.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          laneLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: canvasInk.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kind.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: canvasInk.withValues(alpha: 0.58),
                          ),
                        ),
                      ),
                      _PaletteDots(tokens: swatches, ringColor: canvas),
                      const SizedBox(width: 8),
                      _MiniActionIcon(
                        icon: Icons.code_rounded,
                        tooltip: 'View & copy Dart code',
                        ink: canvasInk,
                        onTap: onOpenCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  specimen,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Specimen 0: Editorial article & reading card.
class const _EditorialSpecimen({
  required final ColorScheme scheme,
  required final Color surface,
  required final Duration duration,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muted = scheme.onSurface.withValues(alpha: 0.68);
    return _SpecimenShell(
      surface: surface,
      borderColor: scheme.onSurface.withValues(alpha: 0.07),
      duration: duration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PillTag(
                    label: 'Design Journal',
                    bg: scheme.secondaryContainer,
                    fg: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '4 min read',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Perceptual color systems',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How tonal surface elevation and balanced accents keep interfaces readable under every vision type.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, height: 1.4, color: muted),
              ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Text(
                  'AL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alfred · Today',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.bookmark_outline_rounded,
                size: 19,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: () {}, child: const Text('Read')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Specimen 1: Media / podcast player card with interactive gapped slider & controls.
class const _AudioPlayerSpecimen({
  required final ColorScheme scheme,
  required final Color surface,
  required final Duration duration,
}) extends StatefulWidget {
  @override
  State<_AudioPlayerSpecimen> createState() => _AudioPlayerSpecimenState();
}

class _AudioPlayerSpecimenState extends State<_AudioPlayerSpecimen> {
  static const _totalSeconds = 218;
  double _progress = 0.61;
  bool _playing = false;

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final muted = scheme.onSurface.withValues(alpha: 0.68);
    final elapsed = (_progress * _totalSeconds).round();

    return _SpecimenShell(
      surface: widget.surface,
      borderColor: scheme.onSurface.withValues(alpha: 0.07),
      duration: widget.duration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: widget.duration,
                curve: kStudioEaseOut,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 26,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Midnight Synth',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ambient Sessions · Ep. 14',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PillTag(
                label: 'Hi-Fi',
                bg: scheme.tertiaryContainer,
                fg: scheme.onTertiaryContainer,
              ),
            ],
          ),
          Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 14,
                  activeTrackColor: scheme.primary,
                  inactiveTrackColor: scheme.secondaryContainer,
                  thumbColor: scheme.primary,
                  overlayColor: scheme.primary.withValues(alpha: 0.12),
                  thumbShape: const HandleThumbShape(),
                  trackShape: const GappedSliderTrackShape(),
                  trackGap: 6,
                  thumbSize: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed)
                        ? const Size(2, 32)
                        : const Size(4, 32),
                  ),
                ),
                child: SizedBox(
                  height: 34,
                  child: Slider(
                    value: _progress,
                    padding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _progress = value),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(elapsed),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                  Text(
                    _formatTime(_totalSeconds),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.queue_music_rounded, size: 17),
                    label: const Text(
                      'Up next',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _progress = 0.0),
                icon: Icon(Icons.skip_previous_rounded, color: muted),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _playing = !_playing),
                  child: AnimatedContainer(
                    duration: widget.duration,
                    curve: kStudioEaseOut,
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: scheme.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _progress = 1.0),
                icon: Icon(Icons.skip_next_rounded, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Specimen 2: Weekly analytics & bar chart card.
class const _AnalyticsSpecimen({
  required final ColorScheme scheme,
  required final Color surface,
  required final Duration duration,
}) extends StatelessWidget {
  static const _bars = [
    ('M', 0.48),
    ('T', 0.65),
    ('W', 0.56),
    ('T', 0.96),
    ('F', 0.72),
    ('S', 0.42),
    ('S', 0.80),
  ];

  @override
  Widget build(BuildContext context) {
    final muted = scheme.onSurface.withValues(alpha: 0.68);
    return _SpecimenShell(
      surface: surface,
      borderColor: scheme.onSurface.withValues(alpha: 0.07),
      duration: duration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weekly focus',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PillTag(
                    label: '+18.4%',
                    bg: scheme.tertiaryContainer,
                    fg: scheme.onTertiaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '24.6 hrs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'vs 20.8 hrs last week',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _bars.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: duration,
                            curve: kStudioEaseOut,
                            height: 52 * _bars[i].$2,
                            decoration: BoxDecoration(
                              color: i == 3
                                  ? scheme.primary
                                  : i == 6
                                  ? scheme.secondary
                                  : scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _bars[i].$1,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: i == 3
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == 3 ? scheme.onSurface : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Specimen 3: Collaborative sprint tasks card.
class const _TasksSpecimen({
  required final ColorScheme scheme,
  required final Color surface,
  required final Duration duration,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muted = scheme.onSurface.withValues(alpha: 0.68);
    return _SpecimenShell(
      surface: surface,
      borderColor: scheme.onSurface.withValues(alpha: 0.07),
      duration: duration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Release checklist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  _PillTag(
                    label: '2 / 3',
                    bg: scheme.primaryContainer,
                    fg: scheme.onPrimaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TaskLine(
                title: 'Verify contrast ratios',
                done: true,
                scheme: scheme,
              ),
              const SizedBox(height: 8),
              _TaskLine(
                title: 'Review dark surface tokens',
                done: true,
                scheme: scheme,
              ),
              const SizedBox(height: 8),
              _TaskLine(
                title: 'Ship updated theme',
                done: false,
                badge: 'Today',
                scheme: scheme,
              ),
            ],
          ),
          Row(
            children: [
              _MiniAvatar(
                text: 'BF',
                bg: scheme.primaryContainer,
                fg: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              _MiniAvatar(
                text: 'AL',
                bg: scheme.secondaryContainer,
                fg: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '2 collaborators',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Share')),
            ],
          ),
        ],
      ),
    );
  }
}

class const _TaskLine({
  required final String title,
  required final bool done,
  required final ColorScheme scheme,
  final String? badge,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muted = scheme.onSurface.withValues(alpha: 0.56);
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: done ? null : Border.all(color: scheme.outline, width: 1.5),
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 13, color: scheme.onPrimary)
              : null,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: done ? muted : scheme.onSurface,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          _PillTag(
            label: badge!,
            bg: scheme.tertiaryContainer,
            fg: scheme.onTertiaryContainer,
          ),
        ],
      ],
    );
  }
}

class const _MiniAvatar({
  required final String text,
  required final Color bg,
  required final Color fg,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class const _SpecimenShell({
  required final Color surface,
  required final Color borderColor,
  required final Duration duration,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: kStudioEaseOut,
      constraints: const BoxConstraints(minHeight: 204),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class const _PillTag({
  required final String label,
  required final Color bg,
  required final Color fg,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class const _PaletteDots({
  required final List<ColorToken> tokens,
  required final Color ringColor,
}) extends StatefulWidget {
  @override
  State<_PaletteDots> createState() => _PaletteDotsState();
}

class _PaletteDotsState extends State<_PaletteDots> {
  static const _dotSize = 18.0;
  static const _collapsedStep = 10.5;
  static const _expandedStep = 21.0;

  bool _fanned = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.tokens.length;
    final step = _fanned ? _expandedStep : _collapsedStep;
    final maxWidth = _dotSize + (count - 1) * _expandedStep;

    return MouseRegion(
      onEnter: (_) => setState(() => _fanned = true),
      onExit: (_) => setState(() => _fanned = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (!_fanned) setState(() => _fanned = true);
        },
        child: SizedBox(
          width: maxWidth,
          height: _dotSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Build in reverse so the leftmost dot paints on top cleanly.
              for (var i = count - 1; i >= 0; i--)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: kStudioEaseOut,
                  top: 0,
                  right: (count - 1 - i) * step,
                  child: Tooltip(
                    message:
                        '${widget.tokens[i].label} · ${encodeHex(widget.tokens[i].color)}',
                    waitDuration: const Duration(milliseconds: 250),
                    child: GestureDetector(
                      onTap: () => copyWithFeedback(
                        context,
                        encodeHex(widget.tokens[i].color),
                      ),
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: widget.tokens[i].color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.ringColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _MiniActionIcon({
  required final IconData icon,
  required final String tooltip,
  required final Color ink,
  required final VoidCallback onTap,
}) extends StatefulWidget {
  @override
  State<_MiniActionIcon> createState() => _MiniActionIconState();
}

class _MiniActionIconState extends State<_MiniActionIcon> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.ink.withValues(
                alpha: _pressed
                    ? 0.16
                    : _hovered
                    ? 0.11
                    : 0.05,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 15,
              color: widget.ink.withValues(alpha: 0.78),
            ),
          ),
        ),
      ),
    );
  }
}
