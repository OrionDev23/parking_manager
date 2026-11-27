import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/sidemenu/profil_name_topbar.dart';
import 'package:parc_oto/screens/sidemenu/global_search.dart';
import 'package:parc_oto/screens/sidemenu/parcoto_navigation_shell.dart';
import 'package:parc_oto/screens/sidemenu/company_workspace_switcher.dart';
import 'package:parc_oto/ui/design_system/parcoto_tokens.dart';
import 'package:window_manager/window_manager.dart';

import '../../main.dart';
import '../../theme.dart';
import '../dashboard/notifications/notif_list.dart';

class PanesList extends StatefulWidget {
  final PaneItemsAndFooters paneList;
  final Widget? widget;
  final AppTheme appTheme;

  const PanesList({
    super.key,
    required this.paneList,
    this.widget,
    required this.appTheme,
  });

  @override
  State<PanesList> createState() => PanesListState();
}

class PanesListState extends State<PanesList>
    with WindowListener, AutomaticKeepAliveClientMixin {
  static ValueNotifier<int> _index = ValueNotifier(0);

  static ValueNotifier<int> get index => _index;

  static int previousValue = 0;

  static set index(ValueNotifier<int> v) {
    previousValue = _index.value;
    _index = v;
  }

  static ValueNotifier<bool> signedIn = ValueNotifier(false);
  static bool listening = false;

  void listenToSigningChanges() {}

  static bool firstLoading = true;

  bool loading = false;

  @override
  void initState() {
    listenToInternet();
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      windowManager.setPreventClose(true);
      windowManager.addListener(this);
    }
    getProfil();
    _authStateSubscription = authService.stateStream.listen((_) {
      if (!mounted) return;
      // Appwrite session state is the source of truth. Keep navigation and
      // the company switcher synchronized even when a session expires or is
      // ended outside the explicit logout screen.
      final hasSession = authService.session != null;
      if (signedIn.value != hasSession) {
        signedIn.value = hasSession;
      }
      widget.paneList.initPanes();
      setState(() {});
      index.value = 0;
    });

    super.initState();
  }

  Future<void> getProfil() async {
    loading = true;
    firstLoading = true;
    if (mounted) {
      setState(() {});
    }

    try {
      final isSignedIn = await restoreInitialSession();
      signedIn.value = isSignedIn;
      if (isSignedIn) {
        startBackgroundInitialization(
          authService.session!.company.companyId,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[ParcOto Startup] session restore failed: $error\\n$stackTrace');
      signedIn.value = false;
    }

    widget.paneList.initPanes();
    loading = false;
    firstLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  bool noConnection = false;

  StreamSubscription<InternetStatus>? internetListener;
  StreamSubscription<dynamic>? _authStateSubscription;

  void listenToInternet() async {
    internetListener = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      switch (status) {
        case InternetStatus.connected:
          if (noConnection) {
            Future.delayed(const Duration(milliseconds: 10)).whenComplete(() {
              if (!mounted) return;
              displayInfoBar(
                context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('connectionback').tr(),
                    severity: InfoBarSeverity.success,
                  );
                },
                duration: snackbarShortDuration,
              );
            });
            setState(() {
              noConnection = false;
            });
          }
          break;
        case InternetStatus.disconnected:
          if (!noConnection) {
            Future.delayed(const Duration(milliseconds: 10)).whenComplete(() {
              if (!mounted) return;
              displayInfoBar(
                context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('noconnection').tr(),
                    severity: InfoBarSeverity.warning,
                  );
                },
                duration: snackbarShortDuration * 3,
              );
            });
            setState(() {
              noConnection = true;
            });
          }
          break;
      }
    });
  }

  double pwidth = 304;

  FlyoutController flyoutController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (firstLoading) {
      return const Center(child: ProgressRing());
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < ParcotoTokens.tabletBreakpoint;
    pwidth = compact ? 304 : (screenWidth < 1280 ? 276 : 304);
    final session = authService.session;
    final isPlatformCompanyContext =
        session?.isPlatformCompanyContext == true;
    final isPlatformHome =
        session?.isPlatformSuperAdmin == true && !isPlatformCompanyContext;
    return ValueListenableBuilder(
      valueListenable: signedIn,
      builder: (BuildContext context, bool isSignedIn, Widget? child) {
        widget.paneList.initPanes();
        return ValueListenableBuilder(
          valueListenable: index,
          builder: (BuildContext context, int selectedIndex, Widget? child) {
            final activePaneKey =
                PaneItemsAndFooters.paneKeyForIndex(selectedIndex);
            return ParcotoNavigationShell(
              items: PaneItemsAndFooters.originalItems,
              footerItems: PaneItemsAndFooters.footerItems,
              selectedIndex: index,
              onSelected: (i) {
                previousValue = index.value;
                index.value = i;
              },
              appTheme: widget.appTheme,
              search: ContextualSearchLauncher(paneKey: activePaneKey),
              topBar: Container(
                height: (compact
                        ? ParcotoTokens.mobileTopbarHeight
                        : ParcotoTokens.topbarHeight) +
                    (isPlatformCompanyContext ? (compact ? 38 : 42) : 0),
                decoration: BoxDecoration(
                  color: widget.appTheme.surfaceColor,
                  border: Border(
                    bottom: BorderSide(
                      color: widget.appTheme.borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      // Keep a one-pixel layout tolerance between the
                      // draggable header row and its parent container.
                      height: (compact
                              ? ParcotoTokens.mobileTopbarHeight
                              : ParcotoTokens.topbarHeight) -
                          1,
                      child: DragToMoveArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact
                                ? ParcotoTokens.space3
                                : ParcotoTokens.space5,
                          ),
                          child: Row(
                            children: [
                              if (compact) ...[
                                if (isSignedIn) ...[
                                  const Expanded(
                                    child: CompanyWorkspaceSwitcher(
                                      compact: true,
                                    ),
                                  ),
                                  const SizedBox(width: ParcotoTokens.space2),
                                  ContextualSearchLauncher(paneKey: activePaneKey, compact: true),
                                ] else ...[
                                  Image.asset(
                                    'assets/images/logo.webp',
                                    width: 112,
                                    height: 38,
                                    fit: BoxFit.contain,
                                  ),
                                  const Spacer(),
                                ],
                              ] else if (isSignedIn) ...[
                                const SizedBox(
                                  width: 230,
                                  child: CompanyWorkspaceSwitcher(),
                                ),
                                const SizedBox(width: ParcotoTokens.space4),
                                 Expanded(
                                  child: ContextualSearchLauncher(paneKey: activePaneKey),
                                ),
                              ] else ...[
                                Image.asset(
                                  'assets/images/logo.webp',
                                  width: 112,
                                  height: 38,
                                  fit: BoxFit.contain,
                                ),
                                const Spacer(),
                              ],
                              if (!compact && isSignedIn) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Aide',
                                  child: IconButton(
                                    icon: const Icon(FluentIcons.help, size: 17),
                                    onPressed: _openHelp,
                                  ),
                                ),
                                Tooltip(
                                  message: 'Applications',
                                  child: IconButton(
                                    icon: const Icon(
                                      FluentIcons.grid_view_large,
                                      size: 17,
                                    ),
                                    onPressed: _openAppLauncher,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (!compact) const SizedBox(width: 4),
                              if (!loading &&
                                  signedIn.value &&
                                  !isPlatformHome &&
                                  session?.company.companyId != null)
                                Tooltip(
                                  message: 'Notifications',
                                  child: NotifList(
                                    companyId: session!.company.companyId,
                                    userId: session.userId,
                                  ),
                                ),
                              if (!loading &&
                                  signedIn.value &&
                                  !isPlatformHome &&
                                  session?.company.companyId != null)
                                SizedBox(
                                  width: compact
                                      ? ParcotoTokens.space2
                                      : ParcotoTokens.space3,
                                ),
                              if (!loading && signedIn.value)
                                const ProfilNameTopBar(),
                              if (!kIsWeb &&
                                  (Platform.isMacOS ||
                                      Platform.isLinux ||
                                      Platform.isWindows)) ...[
                                SizedBox(
                                  width: compact
                                      ? ParcotoTokens.space2
                                      : ParcotoTokens.space3,
                                ),
                                const WindowButtons(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isPlatformCompanyContext)
                      Container(
                        height: compact ? 38 : 42,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact
                              ? ParcotoTokens.space3
                              : ParcotoTokens.space5,
                        ),
                        color: widget.appTheme.mode == ThemeMode.dark
                            ? const Color(0xFF493515)
                            : const Color(0xFFFFF1D6),
                        child: Row(
                          children: [
                            Icon(
                              FluentIcons.shield,
                              size: compact ? 14 : 16,
                              color: widget.appTheme.mode == ThemeMode.dark
                                  ? const Color(0xFFFFD27A)
                                  : const Color(0xFF8A5700),
                            ),
                            const SizedBox(width: ParcotoTokens.space2),
                            Expanded(
                              child: Text(
                                compact
                                    ? 'SUPERVISION • MODE SUPER ADMIN'
                                    : 'MODE SUPERVISION — Vous consultez une entreprise avec les privilèges Super Admin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.appTheme.mode == ThemeMode.dark
                                      ? const Color(0xFFFFD27A)
                                      : const Color(0xFF704600),
                                ),
                              ),
                            ),
                            const SizedBox(width: ParcotoTokens.space2),
                            Button(
                              onPressed: () async {
                                try {
                                  await authService.returnToPlatformContext();
                                } catch (error) {
                                  if (!context.mounted) return;
                                  displayMessage(
                                    context,
                                    error.toString().replaceFirst('Bad state: ', ''),
                                    InfoBarSeverity.error,
                                  );
                                }
                              },
                              child: Text(
                                compact ? 'Retour' : 'Retour plateforme',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openHelp() {
    if (!PaneItemsAndFooters.selectPane('tutorials')) {
      PaneItemsAndFooters.selectPane('settings');
    }
  }

  void _openAppLauncher() {
    const shortcuts = <({
      String key,
      String label,
      IconData icon,
    })>[
      (key: 'dashboard', label: 'Tableau de bord', icon: FluentIcons.home),
      (key: 'vehicles', label: 'Véhicules', icon: FluentIcons.car),
      (key: 'driver-manager', label: 'Conducteurs', icon: FluentIcons.people),
      (key: 'repairs', label: 'Maintenance', icon: FluentIcons.repair),
      (key: 'planner', label: 'Planning', icon: FluentIcons.event),
      (key: 'workshop-stock', label: 'Stock', icon: FluentIcons.database),
      (key: 'workshop-parts', label: 'Pièces', icon: FluentIcons.repair),
      (key: 'events', label: 'Journal', icon: FluentIcons.database_activity),
      (key: 'company', label: 'Mon entreprise', icon: FluentIcons.company_directory),
      (key: 'user-access-management', label: 'Utilisateurs & accès', icon: FluentIcons.people),
      (key: 'platform-companies', label: 'Entreprises clientes', icon: FluentIcons.cloud),
      (key: 'settings', label: 'Paramètres', icon: FluentIcons.settings),
    ];

    final available = shortcuts
        .where((item) => PaneItemsAndFooters.indexForPaneKey(item.key) != null)
        .toList(growable: false);
    if (available.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Applications'),
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 480,
        ),
        content: SizedBox(
          width: 480,
          height: 320,
          child: GridView.builder(
            itemCount: available.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.22,
            ),
            itemBuilder: (context, index) {
              final item = available[index];
              return Button(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  PaneItemsAndFooters.selectPane(item.key);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: widget.appTheme.color,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          Button(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void onWindowClose() {
    windowManager.isPreventClose().then((value) {
      if (value) {
        if (mounted) {
          showDialog<String>(
            context: context,
            builder: (context) => ContentDialog(
              title: const Text('sur').tr(),
              content: const Text('sauv').tr(),
              actions: [
                Button(
                  child: const Text('oui').tr(),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await windowManager.destroy();
                  },
                ),
                FilledButton(
                  child: const Text('non').tr(),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    internetListener?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child:
          (!kIsWeb &&
              (Platform.isMacOS || Platform.isLinux || Platform.isWindows))
          ? WindowCaption(
              brightness: theme.brightness,
              backgroundColor: Colors.transparent,
            )
          : const SizedBox(),
    );
  }
}
