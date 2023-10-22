
import 'package:easy_localization/easy_localization.dart' as eas;
import 'package:flutter/foundation.dart';

import 'package:fluent_ui/fluent_ui.dart';
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
    return const PageTitle(
        text:'Paramètres');
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
      Text('Theme', style: FluentTheme
          .of(context)
          .typography
          .subtitle),
      spacer,
      ...List.generate(ThemeMode.values.length, (index) {
        final mode = ThemeMode.values[index];
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8.0),
          child: RadioButton(
            checked: appTheme.mode == mode,
            onChanged: (value) {
              if (value) {
                appTheme.mode = mode;
                prefs.setInt('themeMode', mode.index);
              }
            },
            content: Text('$mode'.replaceAll('ThemeMode.', '')),
          ),
        );
      }),
      biggerSpacer,
      Text(
        'Disposition du paneau de navigation',
        style: FluentTheme
            .of(context)
            .typography
            .subtitle,
      ),
      spacer,
      ...List.generate(PaneDisplayMode.values.length, (index) {
        final mode = PaneDisplayMode.values[index];
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8.0),
          child: RadioButton(
            checked: appTheme.displayMode == mode,
            onChanged: (value) {
              if (value) {
                appTheme.displayMode = mode;
                prefs.setInt('display', index);
              }
            },
            content: Text(
              mode.toString().replaceAll('PaneDisplayMode.', ''),
            ),
          ),
        );
      }),
      biggerSpacer,
      Text('Couleur des bouttons',
          style: FluentTheme
              .of(context)
              .typography
              .subtitle),
      spacer,
      Wrap(children: [
        ...List.generate(ThemeColors.accentColors.length, (index) {
          final color = ThemeColors.accentColors[index];
          return Tooltip(
            message: accentColorNames[index ],
            child: _buildColorBlock(appTheme, color,index),
          );
        }),
      ]),
      biggerSpacer,
      biggerSpacer,
      Text('Langue', style: FluentTheme
          .of(context)
          .typography
          .subtitle),
      Wrap(
        spacing: 15.0,
        runSpacing: 10.0,
        children: List.generate(
          supportedLocales.length,
              (index) {
            if (supportedLocales[index].languageCode.toUpperCase() == 'AR' ||
                supportedLocales[index].languageCode.toUpperCase() == 'FR' ||
                supportedLocales[index].languageCode.toUpperCase() == 'EN') {
              final locale = supportedLocales[index];

              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8.0),
                child: RadioButton(
                  checked: currentLocale == locale,
                  onChanged: (value) async {
                    if (value) {
                      await context.setLocale(locale).whenComplete(() {
                        appTheme.locale = locale;
                        prefs.setString('lang', locale.languageCode);
                      });
                    }
                  },
                  content: Text(
                      supportedLocales[index].languageCode.toUpperCase() == 'FR'
                          ? "Français"
                          : supportedLocales[index]
                          .languageCode
                          .toUpperCase() ==
                          'AR'
                          ? "عربية"
                          : "English"),
                ),
              );
            }
            return const Padding(padding: EdgeInsets.all(0));
          },
        ),
      ),
    ];
  }

  Widget _buildColorBlock(AppTheme appTheme, AccentColor color,int index) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Button(
        onPressed: () {
          prefs.setInt('color',index);
          appTheme.color = color;
        },
        style: ButtonStyle(
          padding: ButtonState.all(EdgeInsets.zero),
          backgroundColor: ButtonState.resolveWith((states) {
            if (states.isPressing) {
              return color.light;
            } else if (states.isHovering) {
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
