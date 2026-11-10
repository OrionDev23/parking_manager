import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:parc_oto/providers/client_database.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'admin_parameters.dart';
import 'main.dart';
import 'utilities/theme_colors.dart';

enum NavigationIndicators { sticky, end }

late final double rowHeight;
TextStyle tstyle = const TextStyle(fontSize: 9, fontWeight: FontWeight.bold);
TextStyle formHintStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.bold,
  color: placeStyle.color,
);
final placeStyle = TextStyle(color: Colors.grey[100]);
const smallSpace = SizedBox(width: 5, height: 5);
const bigSpace = SizedBox(width: 10, height: 10);
final headerStyle = TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold);
final boldStyle = TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold);
final littleStyle = TextStyle(fontSize: 10.sp);
const snackbarShortDuration = Duration(seconds: 2);

enum AppThemePreset {
  obsidian,
  arctic,
  emerald,
  amethyst,
  sunset,
}

class AppThemePalette {
  final String name;
  final String description;
  final Color accent;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkText;
  final Color darkMutedText;
  final Color darkBorder;
  final Color lightBackground;
  final Color lightSurface;
  final Color lightText;
  final Color lightMutedText;
  final Color lightBorder;
  final double cardRadius;
  final double controlRadius;
  final double tableRadius;
  final double shadowBlur;
  final double shadowOpacity;
  final double headerAccentOpacity;

  const AppThemePalette({
    required this.name,
    required this.description,
    required this.accent,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkText,
    required this.darkMutedText,
    required this.darkBorder,
    required this.lightBackground,
    required this.lightSurface,
    required this.lightText,
    required this.lightMutedText,
    required this.lightBorder,
    required this.cardRadius,
    required this.controlRadius,
    required this.tableRadius,
    required this.shadowBlur,
    required this.shadowOpacity,
    required this.headerAccentOpacity,
  });
}

const Map<AppThemePreset, AppThemePalette> appThemePalettes = {
  AppThemePreset.obsidian: AppThemePalette(
    name: 'Obsidian',
    description: 'Noir profond · Cyan électrique',
    accent: Color(0xFF16C7D9),
    darkBackground: Color(0xFF101820),
    darkSurface: Color(0xFF182630),
    darkText: Color(0xFFEAF5F7),
    darkMutedText: Color(0xFF9CB2BA),
    darkBorder: Color(0xFF2B414B),
    lightBackground: Color(0xFFF1F6F7),
    lightSurface: Color(0xFFFFFFFF),
    lightText: Color(0xFF17252B),
    lightMutedText: Color(0xFF60747B),
    lightBorder: Color(0xFFD8E3E6),
    cardRadius: 14,
    controlRadius: 9,
    tableRadius: 14,
    shadowBlur: 24,
    shadowOpacity: .20,
    headerAccentOpacity: .30,
  ),
  AppThemePreset.arctic: AppThemePalette(
    name: 'Arctic',
    description: 'Clair net · Bleu glacier',
    accent: Color(0xFF2878E5),
    darkBackground: Color(0xFF111A2A),
    darkSurface: Color(0xFF1A2940),
    darkText: Color(0xFFEDF3FF),
    darkMutedText: Color(0xFFA5B6D0),
    darkBorder: Color(0xFF30435F),
    lightBackground: Color(0xFFF0F5FC),
    lightSurface: Color(0xFFFFFFFF),
    lightText: Color(0xFF17263D),
    lightMutedText: Color(0xFF62748E),
    lightBorder: Color(0xFFD8E2F0),
    cardRadius: 9,
    controlRadius: 6,
    tableRadius: 10,
    shadowBlur: 12,
    shadowOpacity: .06,
    headerAccentOpacity: .16,
  ),
  AppThemePreset.emerald: AppThemePalette(
    name: 'Emerald',
    description: 'Vert profond · Ambiance premium',
    accent: Color(0xFF18A879),
    darkBackground: Color(0xFF101D1A),
    darkSurface: Color(0xFF192B25),
    darkText: Color(0xFFE9F6EF),
    darkMutedText: Color(0xFFA0BCAF),
    darkBorder: Color(0xFF30483D),
    lightBackground: Color(0xFFF0F7F3),
    lightSurface: Color(0xFFFFFFFF),
    lightText: Color(0xFF193329),
    lightMutedText: Color(0xFF637C70),
    lightBorder: Color(0xFFD8E7DE),
    cardRadius: 17,
    controlRadius: 10,
    tableRadius: 16,
    shadowBlur: 20,
    shadowOpacity: .12,
    headerAccentOpacity: .22,
  ),
  AppThemePreset.amethyst: AppThemePalette(
    name: 'Amethyst',
    description: 'Violet moderne · Contraste marqué',
    accent: Color(0xFF9B72F2),
    darkBackground: Color(0xFF191426),
    darkSurface: Color(0xFF251D36),
    darkText: Color(0xFFF3EDFF),
    darkMutedText: Color(0xFFB7A9D0),
    darkBorder: Color(0xFF403454),
    lightBackground: Color(0xFFF6F2FC),
    lightSurface: Color(0xFFFFFFFF),
    lightText: Color(0xFF2C2140),
    lightMutedText: Color(0xFF77668F),
    lightBorder: Color(0xFFE4DCEF),
    cardRadius: 21,
    controlRadius: 12,
    tableRadius: 18,
    shadowBlur: 26,
    shadowOpacity: .17,
    headerAccentOpacity: .25,
  ),
  AppThemePreset.sunset: AppThemePalette(
    name: 'Sunset',
    description: 'Anthracite · Ambre énergique',
    accent: Color(0xFFFFA33A),
    darkBackground: Color(0xFF201A16),
    darkSurface: Color(0xFF30251D),
    darkText: Color(0xFFFFF3E6),
    darkMutedText: Color(0xFFC8B29C),
    darkBorder: Color(0xFF514031),
    lightBackground: Color(0xFFFAF4ED),
    lightSurface: Color(0xFFFFFFFF),
    lightText: Color(0xFF33271D),
    lightMutedText: Color(0xFF806D5A),
    lightBorder: Color(0xFFEADFD1),
    cardRadius: 9,
    controlRadius: 6,
    tableRadius: 10,
    shadowBlur: 16,
    shadowOpacity: .14,
    headerAccentOpacity: .30,
  ),
};

class AppTheme extends ChangeNotifier {
  AccentColor _color = systemAccentColor;
  AccentColor get color => _color;

  AppThemePreset _preset = AppThemePreset.obsidian;
  AppThemePreset get preset => _preset;
  AppThemePalette get palette => appThemePalettes[_preset]!;

  set preset(AppThemePreset value) {
    if (_preset == value) return;
    _preset = value;
    changeDecorations();
    notifyListeners();
  }

  RadialGradient getRadiantStandard() => _radiant(color);
  RadialGradient getRadiantLight() => _radiant(color.light);
  RadialGradient getRadiantLighter() => _radiant(color.lighter);
  RadialGradient getRadiantLightest() => _radiant(color.lightest);
  RadialGradient getRadiantDarkest() => _radiant(color.darkest);
  RadialGradient getRadiantDarker() => _radiant(color.darker);
  RadialGradient getRadiantDark() => _radiant(color.dark);

  RadialGradient _radiant(Color tone) {
    return RadialGradient(
      radius: 0.6,
      colors: [
        tone,
        tone.withAlpha(200),
        tone.withAlpha(150),
        tone.withAlpha(100),
        tone.withAlpha(50),
        tone.withAlpha(20),
        backGroundColor.withAlpha(10),
        backGroundColor.withAlpha(0),
      ],
    );
  }

  List<Color> colors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.blue.lighter,
    Colors.teal,
    Colors.yellow,
    Colors.orange.darker,
    Colors.blue.darker,
    Colors.orange.lightest,
  ];

  List<Color> getRandomColors(int nbr) {
    if (nbr <= colors.length) return colors;
    return [
      ...colors,
      ...List.generate(nbr - colors.length, (_) => colors.last),
    ];
  }

  set color(AccentColor value) {
    _color = value;
    notifyListeners();
  }

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  late TextStyle writingStyle;
  late TextStyle titleStyle;
  late Color fillColor;
  late Color backGroundColor;
  late Color surfaceColor;
  late Color mutedTextColor;
  late Color borderColor;
  late m.InputDecoration inputDecoration;

  Color get textColor => writingStyle.color ?? Colors.black;
  double get cardRadius => palette.cardRadius;
  double get controlRadius => palette.controlRadius;
  double get tableRadius => palette.tableRadius;

  BoxShadow get surfaceShadow => BoxShadow(
    color: Colors.black.withValues(
      alpha: palette.shadowOpacity * (mode == ThemeMode.dark ? 1.25 : 1),
    ),
    blurRadius: palette.shadowBlur,
    offset: Offset(0, palette.shadowBlur / 3),
  );

  FluentThemeData fluentTheme(Brightness brightness) {
    final foreground = brightness == Brightness.dark
        ? palette.darkText
        : palette.lightText;
    final background = isDark ? palette.darkBackground : palette.lightBackground;
    final surface = isDark ? palette.darkSurface : palette.lightSurface;
    final muted = isDark ? palette.darkMutedText : palette.lightMutedText;
    final fill = isDark
        ? Color.lerp(surface, Colors.white, .055)!
        : Color.lerp(surface, background, .55)!;
    return FluentThemeData(
      brightness: brightness,
      accentColor: color,
      activeColor: foreground,
      inactiveColor: muted,
      inactiveBackgroundColor: fill,
      scaffoldBackgroundColor: background,
      acrylicBackgroundColor: surface,
      micaBackgroundColor: background,
      shadowColor: Colors.black.withValues(
        alpha: palette.shadowOpacity * (isDark ? 1.25 : 1),
      ),
      menuColor: surface,
      cardColor: surface,
      selectionColor: color.withValues(alpha: .24),
      iconTheme: IconThemeData(color: muted),
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: background,
      ),
      visualDensity: VisualDensity.standard,
      focusTheme: const FocusThemeData(glowFactor: 0),
      typography: Typography.fromBrightness(
        brightness: brightness,
        color: foreground,
      ),
    );
  }

  m.ThemeData get materialTheme {
    final isDark = mode == ThemeMode.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final scheme = m.ColorScheme.fromSeed(
      seedColor: color,
      brightness: brightness,
      surface: surfaceColor,
    ).copyWith(
      primary: color,
      onPrimary: isDark ? Colors.black : Colors.white,
      onSurface: textColor,
      outline: borderColor,
      outlineVariant: borderColor,
      surfaceContainer: fillColor,
      surfaceContainerHighest: fillColor,
    );
    final baseTextTheme = m.ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(bodyColor: textColor, displayColor: textColor);
    return m.ThemeData.from(
      colorScheme: scheme,
      textTheme: baseTextTheme,
      useMaterial3: true,
    ).copyWith(
      scaffoldBackgroundColor: backGroundColor,
      canvasColor: surfaceColor,
      cardColor: surfaceColor,
      dividerColor: borderColor,
      iconTheme: m.IconThemeData(color: mutedTextColor),
      visualDensity: m.VisualDensity.standard,
      inputDecorationTheme: m.InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        hintStyle: TextStyle(color: mutedTextColor),
        labelStyle: TextStyle(color: mutedTextColor),
        enabledBorder: m.OutlineInputBorder(
          borderSide: m.BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        focusedBorder: m.OutlineInputBorder(
          borderSide: m.BorderSide(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
    );
  }

  set mode(ThemeMode value) {
    if (_mode == value) return;
    _mode = value;
    changeDecorations();
    notifyListeners();
  }

  PaneDisplayMode _displayMode = PaneDisplayMode.auto;
  PaneDisplayMode get displayMode => _displayMode;

  set displayMode(PaneDisplayMode value) {
    _displayMode = value;
    notifyListeners();
  }

  NavigationIndicators _indicator = NavigationIndicators.sticky;
  NavigationIndicators get indicator => _indicator;

  set indicator(NavigationIndicators value) {
    _indicator = value;
    notifyListeners();
  }

  TextDirection _textDirection = TextDirection.ltr;
  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection value) {
    _textDirection = value;
    notifyListeners();
  }

  Locale? _locale;
  Locale? get locale => _locale;

  set locale(Locale? value) {
    if (value == null) return;
    DatabaseGetter.client?.setLocale(value.languageCode);
    _locale = value;
    notifyListeners();
  }

  AppTheme() {
    final savedSettings = prefs;
    final savedPreset = savedSettings.getInt('appThemePreset');
    if (savedPreset != null &&
        savedPreset >= 0 &&
        savedPreset < AppThemePreset.values.length) {
      _preset = AppThemePreset.values[savedPreset];
    }

    mode = gts
        ? savedSettings.getInt('themeMode') == 0
              ? ThemeMode.dark
              : ThemeMode.light
        : savedSettings.getInt('themeMode') == 0
        ? ThemeMode.system
        : savedSettings.getInt('themeMode') == 1
        ? ThemeMode.light
        : ThemeMode.dark;

    if (!gts) {
      color = savedSettings.get('color') == null
          ? systemAccentColor
          : getColor(savedSettings.get('color')!);
    }

    displayMode = savedSettings.getInt('display') == null
        ? PaneDisplayMode.auto
        : getDisplayMode(savedSettings.getInt('display')!);
    locale = Locale(savedSettings.getString('lang') ?? 'fr');
    rowHeight = 24.px;
    changeDecorations();
  }

  AccentColor _accentFromColor(Color value) {
    return AccentColor.swatch({
      'darkest': Color.lerp(value, Colors.black, .42)!,
      'darker': Color.lerp(value, Colors.black, .30)!,
      'dark': Color.lerp(value, Colors.black, .16)!,
      'normal': value,
      'light': Color.lerp(value, Colors.white, .18)!,
      'lighter': Color.lerp(value, Colors.white, .32)!,
      'lightest': Color.lerp(value, Colors.white, .46)!,
    });
  }

  void changeDecorations() {
    if (gts) {
      final p = palette;
      final isDark = mode == ThemeMode.dark;
      _color = _accentFromColor(p.accent);
      backGroundColor = isDark ? p.darkBackground : p.lightBackground;
      surfaceColor = isDark ? p.darkSurface : p.lightSurface;
      fillColor = isDark
          ? Color.lerp(p.darkSurface, Colors.white, .055)!
          : Color.lerp(p.lightSurface, p.lightBackground, .55)!;
      mutedTextColor = isDark ? p.darkMutedText : p.lightMutedText;
      borderColor = isDark ? p.darkBorder : p.lightBorder;
      final textColor = isDark ? p.darkText : p.lightText;
      writingStyle = TextStyle(color: textColor);
      titleStyle = TextStyle(color: textColor, fontSize: 16.sp);
      inputDecoration = m.InputDecoration(
        fillColor: fillColor,
        labelStyle: TextStyle(color: mutedTextColor),
        hintStyle: TextStyle(color: mutedTextColor),
        filled: true,
        isDense: true,
        enabledBorder: m.OutlineInputBorder(
          borderSide: m.BorderSide(color: borderColor),
          borderRadius: m.BorderRadius.circular(8),
        ),
        focusedBorder: m.OutlineInputBorder(
          borderSide: m.BorderSide(color: p.accent, width: 1.5),
          borderRadius: m.BorderRadius.circular(8),
        ),
      );
      return;
    }

    final isDark = mode == ThemeMode.dark;
    fillColor = isDark ? Colors.grey[150] : Colors.grey[20];
    writingStyle = TextStyle(color: isDark ? Colors.white : Colors.black);
    titleStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontSize: 16.sp,
    );
    backGroundColor = isDark ? Colors.grey : Colors.white;
    surfaceColor = backGroundColor;
    mutedTextColor = isDark ? Colors.grey[80] : Colors.grey[120];
    borderColor = isDark ? Colors.grey[120] : Colors.grey[30];
    inputDecoration = m.InputDecoration(
      fillColor: fillColor,
      labelStyle: TextStyle(color: mutedTextColor),
      hintStyle: TextStyle(color: mutedTextColor),
      filled: true,
      isDense: true,
    );
  }

  AccentColor getColor(dynamic value) {
    try {
      return ThemeColors.accentColors[value];
    } catch (_) {
      return systemAccentColor;
    }
  }

  PaneDisplayMode getDisplayMode(int display) {
    switch (display) {
      case 0:
        return PaneDisplayMode.top;
      case 1:
        return PaneDisplayMode.expanded;
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
      'darkest': ThemeColors.red.darkest,
      'darker': ThemeColors.red.darker,
      'dark': ThemeColors.red.dark,
      'normal': ThemeColors.red,
      'light': ThemeColors.red.light,
      'lighter': ThemeColors.red.lighter,
      'lightest': ThemeColors.red.lightest,
    });
  }
  return Colors.red;
}
