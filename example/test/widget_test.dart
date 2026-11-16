import 'package:color_blindness/color_blindness.dart';
import 'package:example/main.dart';
import 'package:example/widgets/comparison_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders comparison feed on desktop and mobile cleanly', (
    tester,
  ) async {
    for (final size in const [Size(1280, 900), Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const ColorBlindnessExampleApp());
      await tester.pumpAndSettle();

      expect(find.text('Color Blindness'), findsOneWidget);
      expect(find.text('Original'), findsWidgets);
      expect(find.text('Deuteranopia'), findsWidgets);

      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(find.text('Release Checklist'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('respects user system theme and toggles dark mode cleanly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      tester.binding.setSurfaceSize(null);
    });

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpWidget(const ColorBlindnessExampleApp());
    await tester.pumpAndSettle();

    final darkRow = tester.widget<ComparisonPairRow>(
      find.byType(ComparisonPairRow).first,
    );
    expect(darkRow.original.brightness, Brightness.dark);

    await tester.tap(find.byTooltip('Toggle dark mode'));
    await tester.pumpAndSettle();
    final lightRow = tester.widget<ComparisonPairRow>(
      find.byType(ComparisonPairRow).first,
    );
    expect(lightRow.original.brightness, Brightness.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies hex seeds, shuffles, switches vision and code modal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ColorBlindnessExampleApp());
    await tester.pumpAndSettle();

    final field = find.byType(TextField).first;
    await tester.enterText(field, '#ED735A');
    await tester.pumpAndSettle();
    expect(find.text('#ED735A'), findsOneWidget);

    await tester.enterText(field, 'bad');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Enter six hex digits'), findsOneWidget);

    await tester.tap(find.byTooltip('Crimson · #C62828'));
    await tester.pumpAndSettle();
    final crimsonRow = tester.widget<ComparisonPairRow>(
      find.byType(ComparisonPairRow).first,
    );
    expect(find.text('#C62828'), findsOneWidget);

    await tester.tap(find.text('Shuffle'));
    await tester.pumpAndSettle();
    final shuffledRow = tester.widget<ComparisonPairRow>(
      find.byType(ComparisonPairRow).first,
    );
    expect(shuffledRow.original.primary, isNot(crimsonRow.original.primary));

    await tester.tap(find.byTooltip('Next · Tritanopia'));
    await tester.pumpAndSettle();
    final updated = tester.widget<ComparisonPairRow>(
      find.byType(ComparisonPairRow).first,
    );
    expect(updated.simulation, ColorBlindnessType.tritanopia);

    await tester.tap(find.byTooltip('Previous · Deuteranopia'));
    await tester.pumpAndSettle();
    final steppedBack = tester.widget<ComparisonPairRow>(
      find.byType(ComparisonPairRow).first,
    );
    expect(steppedBack.simulation, ColorBlindnessType.deuteranopia);

    await tester.tap(find.byTooltip('Export Dart code'));
    await tester.pumpAndSettle();
    expect(find.text('CI Test'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
