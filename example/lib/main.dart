import 'package:color_blindness/color_blindness.dart';
import 'package:material_ui/material_ui.dart';

import 'studio_model.dart';
import 'widgets/comparison_feed.dart';
import 'widgets/dart_code_view.dart';
import 'widgets/studio_controls.dart';

void main() => runApp(const ColorBlindnessExampleApp());

class ColorBlindnessExampleApp extends StatefulWidget {
  const ColorBlindnessExampleApp({super.key});

  @override
  State<ColorBlindnessExampleApp> createState() =>
      _ColorBlindnessExampleAppState();
}

class _ColorBlindnessExampleAppState extends State<ColorBlindnessExampleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeData _buildStudioTheme(Brightness brightness, StudioPalette palette) {
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.ink,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ),
      scaffoldBackgroundColor: palette.paper,
    );
  }

  void _toggleTheme(Brightness currentBrightness) {
    setState(() {
      _themeMode = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Blindness Simulator',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: kStudioEaseOut,
      theme: _buildStudioTheme(Brightness.light, StudioPalette.light),
      darkTheme: _buildStudioTheme(Brightness.dark, StudioPalette.dark),
      home: SimulatorHome(onToggleDarkMode: _toggleTheme),
    );
  }
}

class SimulatorHome extends StatefulWidget {
  const SimulatorHome({super.key, required this.onToggleDarkMode});

  final ValueChanged<Brightness> onToggleDarkMode;

  @override
  State<SimulatorHome> createState() => _SimulatorHomeState();
}

class _SimulatorHomeState extends State<SimulatorHome> {
  static final _hexPattern = RegExp(r'^[0-9a-fA-F]{6}$');

  Color _seedColor = seedPresets.first.color;
  late final TextEditingController _seedController = TextEditingController(
    text: encodeHex(_seedColor),
  );
  String? _seedError;
  int _shuffleIndex = 0;

  ColorBlindnessType _simulation = ColorBlindnessType.deuteranopia;
  ComparisonView _comparisonView = ComparisonView.both;

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _applySeedInput(String value, {bool validate = false}) {
    final normalized = value.trim().replaceFirst('#', '');
    if (_hexPattern.hasMatch(normalized)) {
      setState(() {
        _seedColor = Color(0xFF000000 | int.parse(normalized, radix: 16));
        _seedError = null;
      });
    } else if (validate || _seedError != null) {
      setState(() => _seedError = 'Enter six hex digits');
    }
  }

  void _selectPreset(Color color) {
    setState(() {
      _seedColor = color;
      _seedController.text = encodeHex(color);
      _seedError = null;
    });
  }

  void _shuffle() {
    setState(() {
      _shuffleIndex++;
      _seedColor = HSLColor.fromAHSL(
        1.0,
        (155 + _shuffleIndex * 137.5) % 360,
        0.68,
        0.44,
      ).toColor();
      _seedController.text = encodeHex(_seedColor);
      _seedError = null;
    });
  }

  Future<void> _openCodeDialog(Brightness activeBrightness) {
    var tab = 0;
    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final palette = StudioPalette.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final snippet = tab == 0
              ? buildSchemeSnippet(
                  seedColor: _seedColor,
                  brightness: activeBrightness,
                  type: _simulation,
                )
              : buildContrastSnippet(
                  seedColor: _seedColor,
                  brightness: activeBrightness,
                );

          return AlertDialog(
            backgroundColor: palette.surface,
            title: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  _simulation.label,
                  style: TextStyle(
                    fontFamily: 'Instrument Serif',
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: palette.ink,
                  ),
                ),
                StudioPillSelector<int>(
                  value: tab,
                  options: const [
                    (value: 0, label: 'Theme'),
                    (value: 1, label: 'CI Test'),
                  ],
                  onChanged: (next) => setState(() => tab = next),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(child: DartCodeView(code: snippet)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.ink,
                  foregroundColor: isDark ? palette.paper : Colors.white,
                ),
                onPressed: () =>
                    copyWithFeedback(context, snippet, label: 'Dart snippet'),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Copy'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showGuideDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final palette = StudioPalette.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(
            'How it works',
            style: TextStyle(
              fontFamily: 'Instrument Serif',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: palette.ink,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GuideRow(
                    title: 'Compare side by side',
                    body: 'Pick any Material 3 seed color dot or custom hex code and preview how components shift under eight color vision deficiencies.',
                  ),
                  _GuideRow(
                    title: 'Inspect palette roles',
                    body: 'Hover or tap the overlapping dot cluster on any card to fan out semantic accents and copy hex codes.',
                  ),
                  _GuideRow(
                    title: 'Ready for CI checks',
                    body: 'Open the code dialog to copy ready-to-use simulateColorBlindness and colorBlindnessAssertContrast snippets.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.ink,
                foregroundColor: isDark ? palette.paper : Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = StudioPalette.of(context);
    final activeBrightness = Theme.of(context).brightness;
    final original = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: activeBrightness,
    );
    final simulated = original.simulateColorBlindness(_simulation);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limits) {
            final compact = limits.maxWidth < 680;
            final horizontal = compact ? 16.0 : 28.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        compact ? 12 : 16,
                        horizontal,
                        12,
                      ),
                      child: StudioTopBar(
                        simulation: _simulation,
                        comparisonView: _comparisonView,
                        seedColor: _seedColor,
                        seedController: _seedController,
                        seedError: _seedError,
                        isDarkMode: activeBrightness == Brightness.dark,
                        onSimulationChanged: (value) =>
                            setState(() => _simulation = value),
                        onComparisonViewChanged: (value) =>
                            setState(() => _comparisonView = value),
                        onSelectPreset: _selectPreset,
                        onSeedChanged: _applySeedInput,
                        onSeedSubmitted: (value) =>
                            _applySeedInput(value, validate: true),
                        onShuffle: _shuffle,
                        onOpenCode: () => _openCodeDialog(activeBrightness),
                        onToggleDarkMode: () =>
                            widget.onToggleDarkMode(activeBrightness),
                        onShowGuide: _showGuideDialog,
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: palette.border),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          16,
                          horizontal,
                          36,
                        ),
                        children: [
                          for (final kind in SpecimenKind.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ComparisonPairRow(
                                kind: kind,
                                original: original,
                                simulated: simulated,
                                simulation: _simulation,
                                comparisonView: _comparisonView,
                                onOpenCode: () =>
                                    _openCodeDialog(activeBrightness),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = StudioPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: palette.ink),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: palette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
