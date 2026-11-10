import 'package:easy_localization/easy_localization.dart' as eas;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/page.dart';
import '../widgets/page_header.dart';

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
      RadioGroup<ThemeMode>(
        groupValue: appTheme.mode,
        onChanged: (value) {
          if (value != null) {
            appTheme.mode = value;
            // Preserve the persisted mapping: 0 = dark, 1 = light.
            prefs.setInt('themeMode', value == ThemeMode.dark ? 0 : 1);
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: RadioButton<ThemeMode>(
                value: ThemeMode.light,
                content: const Text('Clair'),
              ),
            ),
            RadioButton<ThemeMode>(
              value: ThemeMode.dark,
              content: const Text('Sombre'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Identité visuelle',
        style: FluentTheme.of(context).typography.subtitle,
      ),
      const SizedBox(height: 6),
      Text(
        'Chaque thème possède sa propre signature : formes, densité, profondeur, contrastes et accents. Le mode clair ou sombre adapte ensuite toute l’interface.',
        style: FluentTheme.of(context).typography.caption,
      ),
      const SizedBox(height: 14),
      RadioGroup<AppThemePreset>(
        groupValue: appTheme.preset,
        onChanged: (value) async {
          if (value != null) {
            appTheme.preset = value;
            await prefs.setInt('appThemePreset', value.index);
          }
        },
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppThemePreset.values.map((preset) {
            final palette = appThemePalettes[preset]!;
            final selected = appTheme.preset == preset;
            final isDark = appTheme.mode == ThemeMode.dark;
            final previewBackground = isDark
                ? palette.darkBackground
                : palette.lightBackground;
            final previewSurface = isDark
                ? palette.darkSurface
                : palette.lightSurface;
            final previewText = isDark ? palette.darkText : palette.lightText;
            return SizedBox(
              width: 245,
              child: RadioButton<AppThemePreset>(
                value: preset,
                content: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: previewBackground,
                    borderRadius: BorderRadius.circular(palette.cardRadius),
                    border: Border.all(
                      color: selected
                          ? palette.accent
                          : (isDark ? palette.darkBorder : palette.lightBorder),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: previewSurface,
                          borderRadius: BorderRadius.circular(palette.tableRadius),
                          border: Border.all(
                            color: isDark
                                ? palette.darkBorder
                                : palette.lightBorder,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              decoration: BoxDecoration(
                                color: palette.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 5,
                                    width: 62,
                                    decoration: BoxDecoration(
                                      color: previewText,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 4,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: previewText.withValues(alpha: .35),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 25,
                              height: 25,
                              decoration: BoxDecoration(
                                color: palette.accent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        palette.name,
                        style: TextStyle(
                          color: previewText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        palette.description,
                        style: TextStyle(
                          color: isDark
                              ? palette.darkMutedText
                              : palette.lightMutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      biggerSpacer,
      Text(
        'dispositionpaneau',
        style: FluentTheme.of(context).typography.subtitle,
      ).tr(),
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
          children: PaneDisplayMode.values
              .map(
                (mode) => Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 8.0),
                  child: RadioButton<PaneDisplayMode>(
                    value: mode,
                    content: Text(
                      mode.toString().replaceAll('PaneDisplayMode.', ''),
                    ).tr(),
                  ),
                ),
              )
              .toList(),
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
