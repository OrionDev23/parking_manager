import 'dart:io';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:parc_oto/router.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'providers/client_database.dart';
import 'theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as td;


const appTitle="ParcOto";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    td.initializeDatabase([]);
  usePathUrlStrategy();
  if(!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    await initWindow();
  }

  ClientDatabase();
  launchApp();
}

void launchApp() async{
  final prefs = await SharedPreferences.getInstance();
  VehiclesUtilities();
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
  runApp(EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      useOnlyLangCode: true,
      child: MyApp(
        savedSettings: prefs,
      )));
}

Future<void> initWindow() async {
  var pr = await screenRetriever.getPrimaryDisplay();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    title: "ParcOto",
    minimumSize: Size(pr.size.width-50,pr.size.height-50),
    size: Size(pr.size.width-50,pr.size.height-50),
    center: true,
    backgroundColor: Colors.grey,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class MyApp extends StatefulWidget {
  final SharedPreferences savedSettings;

  const MyApp({super.key, required this.savedSettings});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<LocalizationsDelegate<dynamic>> getDelegates(BuildContext context){
    List<LocalizationsDelegate>results=List.from(context.localizationDelegates);
    results.addAll([
      CountryLocalizations.delegate,
      FluentLocalizations.delegate,
      SfGlobalLocalizations.delegate
    ]);
    return results;
  }

  // This widget is the root of your application.
  GlobalKey<NavigatorState> navigatorKey=GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
  return ResponsiveSizer(builder: (context, orientation, deviceType) {
      return ChangeNotifierProvider(
          create: (_) => AppTheme(widget.savedSettings),
          builder: (context,_){
            final appTheme = context.watch<AppTheme>();
            return FluentApp.router(
              key: navigatorKey,
              title: appTitle,
              themeMode: appTheme.mode,
              debugShowCheckedModeBanner: false,
              color: appTheme.color,
              localizationsDelegates: getDelegates(context),
              localeResolutionCallback: (locale, supportedLocales) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale!.languageCode &&
                      supportedLocale.countryCode == locale.countryCode) {
                    return supportedLocale;
                  }
                }

                return supportedLocales
                    .first; // because of this it will always return the first locale from the list
              },
              darkTheme: FluentThemeData(
                brightness: Brightness.dark,
                accentColor: appTheme.color,
                visualDensity: VisualDensity.standard,
                focusTheme: FocusThemeData(
                  glowFactor: is10footScreen(context) ? 2.0 : 0.0,
                ),
              ),
              theme: FluentThemeData(
                accentColor: appTheme.color,
                visualDensity: VisualDensity.standard,
                focusTheme: FocusThemeData(
                  glowFactor: is10footScreen(context) ? 2.0 : 0.0,
                ),
              ),
              supportedLocales: context.supportedLocales,
              locale: appTheme.locale,
              builder: (context, child) {
                return NavigationPaneTheme(
                  data: const NavigationPaneThemeData(
                    backgroundColor:  null,
                  ),
                  child: child!,
                );
              },
              routerConfig: Routes(widget.savedSettings).router,

            );
      },);
    });
  }
}
