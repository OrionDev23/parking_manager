import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/sidemenu/profil_name_topbar.dart';
import 'package:parc_oto/screens/sidemenu/global_search.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
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
    final compact = screenWidth < 760;\n    pwidth = compact ? 304 : (screenWidth < 1280 ? 276 : 304);
    final session = authService.session;
    final isPlatformCompanyContext =
        session?.isPlatformCompanyContext == true;
    final isPlatformHome =
        session?.isPlatformSuperAdmin == true && !isPlatformCompanyContext;
    return ValueListenableBuilder(
      valueListenable: signedIn,
      builder: (BuildContext context, bool value, Widget? child) {
        widget.paneList.initPanes();
        return ValueListenableBuilder(
          valueListenable: index,
          builder: (BuildContext context, int value, Widget? child) {
            return NavigationView(
              transitionBuilder: (w, d) =>
                  DrillInPageTransition(animation: d, child: w),
              titleBar: Container(
                height: (compact ? 65 : 73.px) +
                    (isPlatformCompanyContext ? (compact ? 40 : 44) : 0),
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
                      height: compact ? 64 : 72.px,
                      child: DragToMoveArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 14 : 24,
                          ),
                          child: Row(
                            children: [
                              if (compact) ...[
                                const PaneToggleButton(),
                                const SizedBox(width: 8),
                              ],
                              Image.asset(
                                'assets/images/logo.webp',
                                width: compact ? 116 : 148,
                                height: 42,
                                fit: BoxFit.contain,
                              ),
                              if (!compact) ...[
                                const SizedBox(width: 18),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: widget.appTheme.borderColor,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPlatformHome
                                          ? 'ADMINISTRATION PLATEFORME'
                                          : isPlatformCompanyContext
                                              ? 'SUPERVISION ENTREPRISE'
                                              : 'ESPACE ENTREPRISE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 1.1,
                                        fontWeight: FontWeight.w700,
                                        color: widget.appTheme.mutedTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isPlatformHome
                                          ? 'Parcoto Control Center'
                                          : isPlatformCompanyContext
                                              ? 'Accès de supervision'
                                              : 'Gestion opérationnelle',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.appTheme.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Spacer(),
                              if (!loading &&
                                  signedIn.value &&
                                  !isPlatformHome &&
                                  DatabaseGetter.trialDate != null)
                                NotifList(
                                  companyId: session?.company.companyId,
                                ),
                              if (!loading &&
                                  signedIn.value &&
                                  !isPlatformHome &&
                                  DatabaseGetter.trialDate != null)
                                SizedBox(width: compact ? 14 : 22),
                              if (!loading && signedIn.value)
                                const ProfilNameTopBar(),
                              if (!kIsWeb &&
                                  (Platform.isMacOS ||
                                      Platform.isLinux ||
                                      Platform.isWindows)) ...[
                                const SizedBox(width: 14),
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
                          horizontal: compact ? 10 : 18,
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
                            const SizedBox(width: 8),
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
                            const SizedBox(width: 8),
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
              pane: NavigationPane(
                header: const GlobalSearchLauncher(),
                selected: value,
                onChanged: (i) {
                  previousValue = index.value;
                  index.value = i;
                },
                size: NavigationPaneSize(openMaxWidth: pwidth),
                // Keep one predictable navigation model: persistent on desktop,
                // overlay drawer on narrow screens. Do not inherit user placement
                // preferences that can leave the menu collapsed unexpectedly.
                displayMode: compact
                    ? PaneDisplayMode.minimal
                    : PaneDisplayMode.open,
                // The app uses a fully custom title bar. Explicitly place the
                // minimal-pane toggle there so mobile users can reach every
                // module instead of relying on the default automatic slot.
                toggleButtonPosition:
                    PaneToggleButtonPreferredPosition.titleBar,
                items: PaneItemsAndFooters.originalItems,
                footerItems: PaneItemsAndFooters.footerItems,
              ),
            );
          },
        );
      },
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
