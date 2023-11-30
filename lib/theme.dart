
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'utilities/theme_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/material.dart' as m;
enum NavigationIndicators { sticky, end }

const tstyle = TextStyle(fontWeight: FontWeight.bold);
final placeStyle = TextStyle(color: Colors.grey[100]);
const smallSpace = SizedBox(
  width: 5,
  height: 5,
);
const bigSpace=SizedBox(
  width: 10,
  height: 10,
);
const snackbarShortDuration=Duration(seconds: 2);
class AppTheme extends ChangeNotifier {
  AccentColor _color = systemAccentColor;

  AccentColor get color => _color;

  set color(AccentColor color) {
    _color = color;
    notifyListeners();
  }

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  late TextStyle writingStyle;
  late Color fillColor;
  late Color backGroundColor;
  late m.InputDecoration inputDecoration;
  set mode(ThemeMode mode) {
    _mode = mode;
    changeDecorations();
    notifyListeners();
  }

  PaneDisplayMode _displayMode = PaneDisplayMode.auto;

  PaneDisplayMode get displayMode => _displayMode;

  set displayMode(PaneDisplayMode displayMode) {
    _displayMode = displayMode;
    notifyListeners();
  }

  NavigationIndicators _indicator = NavigationIndicators.sticky;

  NavigationIndicators get indicator => _indicator;

  set indicator(NavigationIndicators indicator) {
    _indicator = indicator;
    notifyListeners();
  }


  TextDirection _textDirection = TextDirection.ltr;

  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection direction) {
    _textDirection = direction;
    notifyListeners();
  }

  Locale? _locale;

  Locale? get locale => _locale;

  set locale(Locale? locale) {
    ClientDatabase.client?.setLocale(locale?.languageCode);
    _locale = locale;
    notifyListeners();
  }

  AppTheme(SharedPreferences savedSettings) {
    mode = savedSettings.getInt('themeMode') == 0
        ? ThemeMode.system
        : savedSettings.getInt('themeMode') == 1
        ? ThemeMode.light
        : ThemeMode.dark;
    color = savedSettings.get('color') == null
        ? systemAccentColor
        : getColor(savedSettings.get('color')!);
    displayMode = savedSettings.getInt('display') == null
        ? PaneDisplayMode.auto
        : getDisplayMode(savedSettings.getInt('display')!);
    locale=Locale(savedSettings.getString('lang')??'fr');

    changeDecorations();

  }

  void changeDecorations(){
    fillColor=mode == ThemeMode.dark
        ? Colors.grey[150]
        : mode == ThemeMode.light
        ? Colors.grey[20]
        : ThemeMode.system == ThemeMode.light
        ? Colors.grey[20]
        : Colors.grey[150];


    writingStyle = TextStyle(

        color: mode == ThemeMode.dark
            ? Colors.white
            : mode == ThemeMode.light
            ? Colors.black
            : ThemeMode.system == ThemeMode.light
            ? Colors.black
            : Colors.white);

    backGroundColor=mode == ThemeMode.dark
        ? Colors.grey
        : mode == ThemeMode.light
        ? Colors.white
        : ThemeMode.system == ThemeMode.light
        ? Colors.white
        : Colors.grey;

    inputDecoration= m.InputDecoration(
        fillColor: fillColor,
        labelStyle: TextStyle(color: Colors.grey[100]),
        filled: true,
        isDense: true);
  }

  AccentColor getColor(dynamic color){
    try{
      return ThemeColors.accentColors[color];

    }
    catch(e){
      return systemAccentColor;
    }
  }

  PaneDisplayMode getDisplayMode(int display) {
    switch (display) {
      case 0:
        return PaneDisplayMode.top;
      case 1:
        return PaneDisplayMode.open;
      case 2:
        return PaneDisplayMode.compact;
      case 3:
        return PaneDisplayMode.minimal;
      case 4:
        return PaneDisplayMode.auto ;
      default:
        return PaneDisplayMode.auto;
    }
  }
}
AccentColor get systemAccentColor {
  if ((defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.android) &&
      !kIsWeb) {
    return AccentColor.swatch({
      'darkest': SystemTheme.accentColor.darkest,
      'darker': SystemTheme.accentColor.darker,
      'dark': SystemTheme.accentColor.dark,
      'normal': SystemTheme.accentColor.accent,
      'light': SystemTheme.accentColor.light,
      'lighter': SystemTheme.accentColor.lighter,
      'lightest': SystemTheme.accentColor.lightest,
    });
  }
  return Colors.blue;
}
