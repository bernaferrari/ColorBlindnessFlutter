import 'package:color_blindness/color_blindness.dart';
import 'package:color_blindness/color_blindness_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:random_color_scheme/random_color_scheme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'preview/chat_preview.dart';
import 'preview/social_preview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Blindness',
      home: RefreshableHome(),
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xff54120A),
        ),
      ),
    );
  }
}

class RefreshableHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemeScreen(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Color Blindness Color Scheme",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(
              FeatherIcons.github,
              color: Colors.black,
            ),
            tooltip: "GitHub",
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
  @override
  _ThemeScreenState createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  double sliderValue = 0.0;
  ColorBlindnessType typeSelected = ColorBlindnessType.none;
  int seed = 0;

  Theme customTheme({Widget child, int i, bool isDark}) {
    return Theme(
      data: ThemeData(
        colorScheme: colorBlindnessColorScheme(
          randomColorScheme(seed: i + seed, isDark: isDark, shouldPrint: false),
          typeSelected,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      child: ThemeItem(),
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
        return "1% $m, 0.01% $f";
      case ColorBlindnessType.deuteranomaly:
        return "6% $m, 0.4% $f";
      case ColorBlindnessType.tritanomaly:
        return "0.01% $p";
      case ColorBlindnessType.protanopia:
        return "1% $m";
      case ColorBlindnessType.deuteranopia:
        return "1% $m";
      case ColorBlindnessType.tritanopia:
        return "less than 1% $p";
      case ColorBlindnessType.achromatopsia:
        return "0.003% $p";
      case ColorBlindnessType.achromatomaly:
        return "0.001% $p";
      default:
        // this should never be called.
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final condition = MediaQuery.of(context).size.width > 950;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 2, color: Color(0xff083EA7)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  """
This is the sample for a library.
The idea is for you to plug colorBlindnessColorScheme() into your apps.""",
                  style: Theme.of(context).textTheme.subtitle2,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              height: 24,
            ),
            Text(
              typesToStr(),
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center,
            ),
            Text(
              affectedToStr(),
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 8,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
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
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              label: Text("Randomize Themes"),
              icon: Icon(FeatherIcons.shuffle, size: 16),
              onPressed: () {
                setState(() {
                  seed += 4;
                });
              },
            ),
            SizedBox(
              height: 16,
            ),
            for (int i = 0; i < 3; i++)
              Flex(
                direction: condition ? Axis.horizontal : Axis.vertical,
                children: [
                  Flexible(
                    flex: condition ? 1 : 0,
                    child: customTheme(
                      child: ThemeItem(),
                      i: i,
                      isDark: true,
                    ),
                  ),
                  Flexible(
                    flex: condition ? 1 : 0,
                    child: customTheme(
                      child: ThemeItem(),
                      i: i,
                      isDark: false,
                    ),
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
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.background,
      elevation: 0,
      child: Row(
        children: [
          Expanded(child: SocialPreview()),
          Expanded(child: ChatPreview()),
        ],
      ),
    );
  }
}
