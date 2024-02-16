import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_randomcolor/flutter_randomcolor.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'main.dart';
import 'utilities/theme_colors.dart';

enum NavigationIndicators { sticky, end }

late final double rowHeight;
TextStyle tstyle = const TextStyle(fontSize:9, fontWeight:
FontWeight.bold);
TextStyle formHintStyle = TextStyle(fontSize:10, fontWeight:
FontWeight.bold,color: placeStyle.color);
final placeStyle = TextStyle(color: Colors.grey[100]);
const smallSpace = SizedBox(
  width: 5,
  height: 5,
);
const bigSpace = SizedBox(
  width: 10,
  height: 10,
);
final headerStyle = TextStyle(
  fontSize: 14.sp,
  fontWeight: FontWeight.bold,
);
final boldStyle = TextStyle(
  fontSize: 12.sp,
  fontWeight: FontWeight.bold,
);
final littleStyle = TextStyle(fontSize: 10.sp);
const snackbarShortDuration = Duration(seconds: 2);

class AppTheme extends ChangeNotifier {
  AccentColor _color = systemAccentColor;

  AccentColor get color => _color;

  RadialGradient getRadiantStandard() {
    return RadialGradient(radius: 0.6, colors: [
      color,
      color.withAlpha(200),
      color.withAlpha(150),
      color.withAlpha(100),
      color.withAlpha(50),
      color.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }


  List<Color> getRandomColors(int nbr){
    Options options = Options(
        format: Format.rgbArray,
        colorType: getColorType(),
        luminosity: Luminosity.bright,
        alpha: 1,
        count: nbr
    );
    var colors=RandomColor.getColor(options);
    return getColorsFromString(colors.toString());
  }

  List<Color> getColorsFromString(String colors){
    List<String> s=colors.toString().replaceAll('[', '').replaceAll(']','')
        .replaceAll(' ', '').split(',');
    List<Color> result=[];

    for(int i=0;i<s.length;i+=3){
      result.add(Color.fromARGB(255, int.tryParse(s[i])??255, int.tryParse
        (s[i+1])??255, int.tryParse(s[i+2])??255));
    }

    return result;
  }


  List<ColorType> getColorType(){
      if(ThemeColors.orange.value==color.value){
        return [ColorType.orange,ColorType.red,];
      }
      else if(ThemeColors.red.value==color.value){
        return [ColorType.orange,ColorType.pink,ColorType.red,];
      }
      else if(ThemeColors.green.value==color.value){
        return [ColorType.orange,ColorType.green,ColorType.red,];
      }
      else if(ThemeColors.blue.value==color.value){
        return [ColorType.blue,ColorType.purple,];
      }
      else {
        return [ColorType.orange,ColorType.green,ColorType.red,];
      }

  }

  RadialGradient getRadiantLight() {
    return RadialGradient(radius: 0.6, colors: [
      color.light,
      color.light.withAlpha(200),
      color.light.withAlpha(150),
      color.light.withAlpha(100),
      color.light.withAlpha(50),
      color.light.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }

  RadialGradient getRadiantLighter() {
    return RadialGradient(radius: 0.6, colors: [
      color.lighter,
      color.lighter.withAlpha(200),
      color.lighter.withAlpha(150),
      color.lighter.withAlpha(100),
      color.lighter.withAlpha(50),
      color.lighter.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }

  RadialGradient getRadiantLightest() {
    return RadialGradient(radius: 0.6, colors: [
      color.lightest,
      color.lightest.withAlpha(200),
      color.lightest.withAlpha(150),
      color.lightest.withAlpha(100),
      color.lightest.withAlpha(50),
      color.lightest.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }

  RadialGradient getRadiantDarkest() {
    return RadialGradient(radius: 0.6, colors: [
      color.darkest,
      color.darkest.withAlpha(200),
      color.darkest.withAlpha(150),
      color.darkest.withAlpha(100),
      color.darkest.withAlpha(50),
      color.darkest.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }

  RadialGradient getRadiantDarker() {
    return RadialGradient(radius: 0.6, colors: [
      color.darker,
      color.darker.withAlpha(200),
      color.darker.withAlpha(150),
      color.darker.withAlpha(100),
      color.darker.withAlpha(50),
      color.darker.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }

  RadialGradient getRadiantDark() {
    return RadialGradient(radius: 0.6, colors: [
      color.dark,
      color.dark.withAlpha(200),
      color.dark.withAlpha(150),
      color.dark.withAlpha(100),
      color.dark.withAlpha(50),
      color.dark.withAlpha(20),
      backGroundColor.withAlpha(10),
      backGroundColor.withAlpha(0),
    ]);
  }

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

  AppTheme() {
    final savedSettings = prefs;
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
    locale = Locale(savedSettings.getString('lang') ?? 'fr');
    rowHeight = 24.px;

    changeDecorations();
  }

  void changeDecorations() {
    fillColor = mode == ThemeMode.dark
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

    backGroundColor = mode == ThemeMode.dark
        ? Colors.grey
        : mode == ThemeMode.light
            ? Colors.white
            : ThemeMode.system == ThemeMode.light
                ? Colors.white
                : Colors.grey;

    inputDecoration = m.InputDecoration(
        fillColor: fillColor,
        labelStyle: TextStyle(color: Colors.grey[100]),
        filled: true,
        isDense: true);
  }

  AccentColor getColor(dynamic color) {
    try {
      return ThemeColors.accentColors[color];
    } catch (e) {
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
        return PaneDisplayMode.auto;
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
      'darkest': ThemeColors.orange.darkest,
      'darker': ThemeColors.orange.darker,
      'dark': ThemeColors.orange.dark,
      'normal': ThemeColors.orange,
      'light': ThemeColors.orange.light,
      'lighter': ThemeColors.orange.lighter,
      'lightest': ThemeColors.orange.lightest,
    });
  }
  return Colors.orange;
}
