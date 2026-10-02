import 'package:easy_localization/easy_localization.dart' as eas;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../utilities/theme_colors.dart';
import '../widgets/page.dart';
import '../widgets/page_header.dart';

const List<String> accentColorNames = [
  'Orange',
  'Red',
  'Magenta',
  'Purple',
  'Blue',
  'Green',
];

bool get kIsWindowEffectsSupported {
  return !kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
}

class Settings extends ScrollablePage {
  final SharedPreferences prefs;

  Settings(this.prefs, {super.key});

  @override
  Widget buildHeader(BuildContext context) {
    return PageTitle(text: 'parametres'.tr());
  }

  @override
  List<Widget> buildScrollable(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);

    const supportedLocales = [Locale('fr'), Locale('ar'), Locale('en')];
    final currentLocale =
        appTheme.locale ?? Localizations.maybeLocaleOf(context);

    return [
      Text('theme', style: FluentTheme.of(context).typography.subtitle).tr(),
      spacer,
      RadioGroup<ThemeMode>(
        groupValue: appTheme.mode,
        onChanged: (value) {
          if (value != null) {
            appTheme.mode = value;
            prefs.setInt('themeMode', value.index);
          }
        },
        child: Column(
          children: List.generate(ThemeMode.values.length, (index) {
            final mode = ThemeMode.values[index];
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: RadioButton<ThemeMode>(
                value: mode,
                content: Text('$mode'.replaceAll('ThemeMode.', '')).tr(),
              ),
            );
          }),
        ),
      ),
      biggerSpacer,
      Text('dispositionpaneau', style: FluentTheme.of(context).typography.subtitle).tr(),
      spacer,
      RadioGroup<PaneDisplayMode>(
        groupValue: appTheme.displayMode,
        onChanged: (value) {
          if (value != null) {
            appTheme.displayMode = value;
            prefs.setInt('display', PaneDisplayMode.values.indexOf(value));
          }
        },
        child: Column(
          children: List.generate(PaneDisplayMode.values.length, (index) {
            final mode = PaneDisplayMode.values[index];
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: RadioButton<PaneDisplayMode>(
                value: mode,
                content: Text(mode.toString().replaceAll('PaneDisplayMode.', '')).tr(),
              ),
            );
          }),
        ),
      ),
      biggerSpacer,
      Text('couleurprincipale',
          style: FluentTheme.of(context).typography.subtitle).tr(),
      spacer,
      Wrap(children: [
        ...List.generate(ThemeColors.accentColors.length, (index) {
          final color = ThemeColors.accentColors[index];
          return Tooltip(
            message: accentColorNames[index],
            child: _buildColorBlock(appTheme, color, index),
          );
        }),
      ]),
      biggerSpacer,
      biggerSpacer,
      Text('langue', style: FluentTheme.of(context).typography.subtitle).tr(),
      RadioGroup<Locale>(
        groupValue: currentLocale,
        onChanged: (value) async {
          if (value != null) {
            await context.setLocale(value);
            appTheme.locale = value;
            await prefs.setString('lang', value.languageCode);
          }
        },
        child: Wrap(
          spacing: 15.0,
          runSpacing: 10.0,
          children: supportedLocales.map((locale) {
            final label = locale.languageCode.toUpperCase() == 'FR'
                ? 'Français'
                : locale.languageCode.toUpperCase() == 'AR'
                    ? 'عربية'
                    : 'English';
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: RadioButton<Locale>(
                value: locale,
                content: Text(label),
              ),
            );
          }).toList(),
        ),
      ),
    ];
  }

  Widget _buildColorBlock(AppTheme appTheme, AccentColor color, int index) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Button(
        onPressed: () {
          prefs.setInt('color', index);
          appTheme.color = color;
        },
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return color.light;
            } else if (states.contains(WidgetState.hovered)) {
              return color.lighter;
            }
            return color;
          }),
        ),
        child: Container(
          height: 40,
          width: 40,
          alignment: AlignmentDirectional.center,
          child: appTheme.color == color
              ? Icon(
                  FluentIcons.check_mark,
                  color: color.basedOnLuminance(),
                  size: 22.0,
                )
              : null,
        ),
      ),
    );
  }
}
