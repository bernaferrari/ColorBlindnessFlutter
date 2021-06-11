import 'package:color_blindness/color_blindness.dart';
import 'package:color_blindness/color_blindness_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:random_color_scheme/random_color_scheme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'preview/chat_preview.dart';
import 'preview/social_preview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Blindness',
      home: const RefreshableHome(),
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xffC2410C),
        ),
      ),
    );
  }
}

class RefreshableHome extends StatelessWidget {
  const RefreshableHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ThemeScreen(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Color Blindness Color Scheme",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.code_rounded,
              color: Colors.black,
            ),
            tooltip: "Source",
            onPressed: () async {
              await launch(
                  "https://github.com/bernaferrari/ColorBlindnessFlutter");
            },
          )
        ],
        elevation: 0,
      ),
    );
  }
}

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  _ThemeScreenState createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  double sliderValue = 0;
  ColorBlindnessType typeSelected = ColorBlindnessType.none;
  int seed = 0;

  Theme customThemeChild({required int i, required bool isDark}) {
    return Theme(
      data: ThemeData(
        colorScheme: colorBlindnessColorScheme(
          randomColorScheme(seed: i + seed, isDark: isDark, shouldPrint: false),
          typeSelected,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      child: const ThemeItem(),
    );
  }

  String typesToStr() {
    final str = typeSelected.toString().substring(19);
    return str[0].toUpperCase() + str.substring(1);
  }

  String affectedToStr() {
    const m = "of males";
    const f = "of females";
    const p = "of population";

    switch (typeSelected) {
      case ColorBlindnessType.none:
        return "most of the population";
      case ColorBlindnessType.protanomaly:
        return "1% $m, 01% $f";
      case ColorBlindnessType.deuteranomaly:
        return "6% $m, 0.4% $f";
      case ColorBlindnessType.tritanomaly:
        return "01% $p";
      case ColorBlindnessType.protanopia:
        return "1% $m";
      case ColorBlindnessType.deuteranopia:
        return "1% $m";
      case ColorBlindnessType.tritanopia:
        return "less than 1% $p";
      case ColorBlindnessType.achromatopsia:
        return "003% $p";
      case ColorBlindnessType.achromatomaly:
        return "001% $p";
      default:
        // this should never be called.
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final condition = MediaQuery.of(context).size.width > 950;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: const Color(0xffFFF7ED),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 2, color: Color(0xffFED7AA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  """
This is the sample for a library.
The idea is for you to plug colorBlindnessColorScheme() into your apps.""",
                  style: Theme.of(context).textTheme.subtitle2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              typesToStr(),
              style: Theme.of(context).textTheme.headline6?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              affectedToStr(),
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Slider(
                min: 0,
                max: 7,
                divisions: 7,
                value: sliderValue,
                onChanged: (value) {
                  setState(() {
                    sliderValue = value;
                    typeSelected =
                        ColorBlindnessType.values[sliderValue.toInt()];
                  });
                },
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: const Text("Randomize Themes"),
              icon: const Icon(Icons.shuffle_rounded, size: 16),
              onPressed: () {
                setState(() {
                  seed += 4;
                });
              },
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < 3; i++)
              Flex(
                direction: condition ? Axis.horizontal : Axis.vertical,
                children: [
                  Flexible(
                    flex: condition ? 1 : 0,
                    child: customThemeChild(i: i, isDark: true),
                  ),
                  Flexible(
                    flex: condition ? 1 : 0,
                    child: customThemeChild(i: i, isDark: false),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ThemeItem extends StatelessWidget {
  const ThemeItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.background,
      elevation: 0,
      child: Row(
        children: const [
          Expanded(child: SocialPreview()),
          Expanded(child: ChatPreview()),
        ],
      ),
    );
  }
}
