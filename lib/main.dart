import 'dart:async';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart'
    hide Colors, VisualDensity, ThemeMode;
import 'package:material_ui/material_ui.dart' as mui;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:parc_oto/router.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as td;
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/client_database.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/legacy_appwrite_auth_service.dart';
import 'core/services/company_service.dart';
import 'core/services/access_control_service.dart';
import 'domain/repositories/access_control_repository.dart';
import 'data/remote/access/appwrite_access_control_repository.dart';
import 'core/services/user_profile_service.dart';
import 'core/services/vehicle_services.dart';
import 'core/database/legacy_module_cache_migration.dart';
import 'core/services/driver_services.dart';
import 'core/services/legacy_stock_sync_service.dart';
import 'core/device/shared_preferences_device_identity.dart';
import 'core/sync/appwrite_sync_engine.dart';
import 'core/sync/sync_engine.dart';
import 'data/remote/company/legacy_appwrite_company_repository.dart';
import 'data/remote/users/legacy_appwrite_user_profile_repository.dart';
import 'theme.dart';

const appTitle = "ParcOto";
late final PackageInfo packageInfo;
late final SharedPreferences prefs;
late final VehicleServices vehicleServices;
late final DriverServices driverServices;
late final LegacyStockSyncService legacyStockSyncService;
late final SyncEngine syncEngine;
late final AuthService authService;
late final UserProfileService userProfileService;
late final CompanyService companyService;
late final AccessControlService accessControlService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  packageInfo = await PackageInfo.fromPlatform();
  VideoPlayerMediaKit.ensureInitialized(
    windows: true,
    macOS: true,
    linux: true,
  );
  tz.initializeTimeZones();
  td.initializeDatabase([]);
  usePathUrlStrategy();
  // File path to a file in the current directory
  if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    await initWindow();
  }

  await launchApp();
}

void displayMessage(
  BuildContext context,
  String msg,
  InfoBarSeverity severity,
) {
  displayInfoBar(
    context,
    builder: (BuildContext context, void Function() close) {
      return InfoBar(title: Text(msg).tr(), severity: severity);
    },
    duration: snackbarShortDuration,
  );
}

Future<bool>? _initialSessionRestore;
Future<void>? _backgroundInitialization;

Future<bool> restoreInitialSession() {
  return _initialSessionRestore ??= _restoreInitialSession();
}

Future<bool> _restoreInitialSession() async {
  final session = await authService.restoreSession();
  return session != null;
}

/// Starts remote backfills only after the first frame and after authentication.
/// Completion markers live in SQLite, so a hot restart does not repeat full scans.
void startBackgroundInitialization(String companyId) {
  _backgroundInitialization ??= _initializeBackgroundData(companyId);
}

Future<void> _initializeBackgroundData(String companyId) async {
  final localDatabase = vehicleServices.localDatabase;

  Future<void> runMigration(
    String key,
    Future<void> Function() migration,
  ) async {
    if (localDatabase.isStartupMigrationComplete(
      companyId: companyId,
      migrationKey: key,
    )) {
      debugPrint('[ParcOto Startup] $key already completed; skipped');
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      await migration();
      localDatabase.markStartupMigrationComplete(
        companyId: companyId,
        migrationKey: key,
      );
      debugPrint(
        '[ParcOto Startup] $key completed in ${stopwatch.elapsedMilliseconds} ms',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[ParcOto Startup] $key failed after ${stopwatch.elapsedMilliseconds} ms: $error\\n$stackTrace',
      );
    }
  }

  await Future.wait([
    runMigration('vehicles', () async {
      await vehicleServices.migrateRemoteCache();
    }),
    runMigration('drivers', () async {
      await driverServices.migrateRemoteCache();
    }),
    runMigration('legacy_modules', () async {
      final counts = await LegacyModuleCacheMigration(
        localDatabase: localDatabase,
        companyId: companyId,
      ).migrate();
      if (counts.isEmpty || counts.values.any((count) => count < 0)) {
        throw StateError('One or more legacy module cache tables failed.');
      }
    }),
  ]);

  await syncEngine.start();
}

Future<void> launchApp() async {
  final startupWatch = Stopwatch()..start();
  prefs = await SharedPreferences.getInstance();
  DatabaseGetter();

  authService = LegacyAppwriteAuthService(
    preferences: prefs,
    accessControlRepository: const AppwriteAccessControlRepository(),
  );
  userProfileService = const UserProfileService(
    repository: LegacyAppwriteUserProfileRepository(),
  );
  companyService = const CompanyService(
    repository: LegacyAppwriteCompanyRepository(),
  );
  const AccessControlRepository accessRepository =
      AppwriteAccessControlRepository();
  accessControlService = AccessControlService(repository: accessRepository);

  // SQLite and service construction are local operations. Remote authentication,
  // backfills and synchronization are deliberately deferred until after runApp.
  final activeCompanyId = project ?? 'local';
  vehicleServices = await VehicleServices.create(
    preferences: prefs,
    companyId: activeCompanyId,
  );
  driverServices = await DriverServices.create(
    preferences: prefs,
    companyId: activeCompanyId,
    appwriteProjectId: project ?? 'essais',
  );

  legacyStockSyncService = LegacyStockSyncService(
    localDatabase: vehicleServices.localDatabase,
    queue: vehicleServices.syncQueue,
    deviceIdentity: SharedPreferencesDeviceIdentity(
      Future.value(prefs),
      idFactory: () => 'desktop_${DateTime.now().microsecondsSinceEpoch}',
    ),
    companyId: activeCompanyId,
  );

  syncEngine = AppwriteSyncEngine(
    queue: vehicleServices.syncQueue,
    companyId: activeCompanyId,
    handlers: {
      'vehicle': vehicleServices.applySyncOperation,
      'driver': driverServices.applySyncOperation,
      'part': legacyStockSyncService.applySyncOperation,
      'part_category': legacyStockSyncService.applySyncOperation,
      'part_brand': legacyStockSyncService.applySyncOperation,
      'part_option': legacyStockSyncService.applySyncOperation,
      'supplier': legacyStockSyncService.applySyncOperation,
    },
    pullHandlers: {
      'vehicle': () async {
        await vehicleServices.pullRemoteChanges();
      },
      'driver': () async {
        await driverServices.pullRemoteChanges();
      },
      'stock': () async {
        await legacyStockSyncService.pullRemoteChanges();
      },
    },
  );

  VehiclesUtilities();
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      useOnlyLangCode: true,
      child: MyApp(navigatorKey: GlobalKey<NavigatorState>()),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint(
      '[ParcOto Startup] first Flutter frame rendered after ${startupWatch.elapsedMilliseconds} ms',
    );
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      unawaited(_showMainWindow());
    }
  });
}

Future<void> _showMainWindow() async {
  try {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  } catch (error, stackTrace) {
    debugPrint('[ParcOto Window] show failed: $error\\n$stackTrace');
  }
}

Future<void> initWindow() async {
  final display = await screenRetriever.getPrimaryDisplay();
  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    title: 'ParcOto',
    minimumSize: Size(display.size.width / 2, display.size.height - 50),
    size: Size(display.size.width - 50, display.size.height - 50),
    center: true,
    backgroundColor: Colors.grey,
    fullScreen: false,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // Configure the native window, but keep it hidden until Flutter has painted
  // its first frame. This avoids showing a blank, draggable window at startup.
  await windowManager.waitUntilReadyToShow(windowOptions, () async {});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});

  List<LocalizationsDelegate<dynamic>> getDelegates(BuildContext context) {
    List<LocalizationsDelegate> results = List.from(
      context.localizationDelegates,
    );
    results.addAll([
      // Avoid loading the package's missing i18n JSON assets at startup.
      // Country names in this picker remain English; app UI localization is unchanged.
      CountryLocalizations.getDelegate(enableLocalization: false),
      FluentLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
      SfGlobalLocalizations.delegate,
    ]);
    return results;
  }

  // This is the root widget of the application.
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, deviceType) {
        return ChangeNotifierProvider(
          create: (_) => AppTheme(),
          builder: (context, _) {
            final appTheme = context.watch<AppTheme>();
            bool portrait =
                MediaQuery.of(context).orientation == Orientation.portrait;
            if (portrait) {
              tstyle = tstyle.copyWith(fontSize: 13.sp);
            } else {
              tstyle = tstyle.copyWith(fontSize: 10.sp);
            }
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

                return supportedLocales.first;
              },
              darkTheme: appTheme.fluentTheme(Brightness.dark),
              theme: appTheme.fluentTheme(Brightness.light),
              supportedLocales: const [
                Locale('fr'),
                Locale('en'),
                Locale('ar'),
              ],
              locale: appTheme.locale,
              builder: (context, child) {
                return mui.Theme(
                  data: appTheme.materialUiTheme,
                  child: m.Theme(
                    data: appTheme.materialTheme,
                    child: NavigationPaneTheme(
                      data: NavigationPaneThemeData(
                        backgroundColor: appTheme.backGroundColor,
                      ),
                      child: child!,
                    ),
                  ),
                );
              },
              routerConfig: Routes(appTheme).router,
            );
          },
        );
      },
    );
  }
}
