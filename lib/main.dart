import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'providers/client_database.dart';
import 'screens/sidemenu.dart';
import 'theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';


const appTitle="ParcOto";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initWindow();
  ClientDatabase();
  launchApp();
}

void launchApp() async{
  final prefs = await SharedPreferences.getInstance();

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

class MyApp extends StatelessWidget {
  final SharedPreferences savedSettings;

  const MyApp({super.key, required this.savedSettings});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
  return ResponsiveSizer(builder: (context, orientation, deviceType) {
      return ChangeNotifierProvider(
          create: (_) => AppTheme(savedSettings),
          builder: (context,_){
            final appTheme = context.watch<AppTheme>();
            return FluentApp(
              title: appTitle,
              themeMode: appTheme.mode,
              debugShowCheckedModeBanner: false,
              color: appTheme.color,
              localizationsDelegates: context.localizationDelegates,
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
                return Directionality(
                  textDirection: appTheme.textDirection,
                  child: NavigationPaneTheme(
                    data: const NavigationPaneThemeData(
                      backgroundColor:  null,
                    ),
                    child: child!,
                  ),
                );
              },
              initialRoute: '/',
              routes: {
                '/': (context) => PanesList(
                  prefs: savedSettings,
                )
              },

            );
      },);
    });
  }
}
