import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';

import '../theme.dart';

class ThemeColors {
  static List<AccentColor> accentColors = [
    orange,
    red,
    magenta,
    purple,
    blue,
    green
  ];

  static final AccentColor orange = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xff993d07),
    'darker': Color(0xffac4508),
    'dark': Color(0xffd1540a),
    'normal': Color(0xfff7630c),
    'light': Color(0xfff87a30),
    'lighter': Color(0xfff99154),
    'lightest': Color(0xfffa9e68),
  });
  static final AccentColor red = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xff8f0a15),
    'darker': Color(0xffa20b18),
    'dark': Color(0xffb90d1c),
    'normal': Color(0xffe81123),
    'light': Color(0xffec404f),
    'lighter': Color(0xffee5865),
    'lightest': Color(0xfff06b76),
  });
  static final AccentColor magenta = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xff6f0061),
    'darker': Color(0xff7e006e),
    'dark': Color(0xff90007e),
    'normal': Color(0xffb4009e),
    'light': Color(0xffc333b1),
    'lighter': Color(0xffca4cbb),
    'lightest': Color(0xffd060c2),
  });
  static final AccentColor purple = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xff472f68),
    'darker': Color(0xff513576),
    'dark': Color(0xff644293),
    'normal': Color(0xFF744da9),
    'light': Color(0xff8664b4),
    'lighter': Color(0xff9d82c2),
    'lightest': Color(0xffa890c9),
  });
  static final AccentColor blue = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xff004a83),
    'darker': Color(0xff005494),
    'dark': Color(0xff0066b4),
    'normal': Color(0xff0078d4),
    'light': Color(0xff268cda),
    'lighter': Color(0xff4ca0e0),
    'lightest': Color(0xff60abe4),
  });
  static final AccentColor green = AccentColor.swatch(const <String, Color>{
    'darkest': Color(0xff094c09),
    'darker': Color(0xff0c5d0c),
    'dark': Color(0xff0e6f0e),
    'normal': Color(0xff107c10),
    'light': Color(0xff278927),
    'lighter': Color(0xff4b9c4b),
    'lightest': Color(0xff6aad6a),
  });

}
Color getRandomColorFromTheme(AppTheme appTheme,int index){
var options = Options(
    format: Format.hex,
    colorType: appTheme.color

);
return RandomColor.getColor(options);
}
