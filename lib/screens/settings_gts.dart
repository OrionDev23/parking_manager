import 'package:easy_localization/easy_localization.dart' as eas;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/page.dart';
import '../widgets/page_header.dart';



enum GtsTheme{
  gtsDark,
  gtsLight,
}

bool get kIsWindowEffectsSupported {
  return !kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
}

class SettingsGTS extends ScrollablePage {
  final SharedPreferences prefs;

  SettingsGTS(this.prefs, {super.key});

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
      RadioGroup<GtsTheme>(
        groupValue: appTheme.mode == ThemeMode.dark ? GtsTheme.gtsDark : GtsTheme.gtsLight,
        onChanged: (value) {
          if (value != null) {
            appTheme.mode = value == GtsTheme.gtsDark ? ThemeMode.dark : ThemeMode.light;
            prefs.setInt('themeMode', value.index);
          }
        },
        child: Column(
          children: GtsTheme.values.map((mode) => Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: RadioButton<GtsTheme>(
              value: mode,
              content: Text('$mode'.replaceAll('GtsTheme.', '')).tr(),
            ),
          )).toList(),
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
          children: PaneDisplayMode.values.map((mode) => Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: RadioButton<PaneDisplayMode>(
              value: mode,
              content: Text(mode.toString().replaceAll('PaneDisplayMode.', '')).tr(),
            ),
          )).toList(),
        ),
      ),
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
              child: RadioButton<Locale>(value: locale, content: Text(label)),
            );
          }).toList(),
        ),
      ),
    ];
  }

}
