import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/sidemenu/profil_name_topbar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:window_manager/window_manager.dart';

import '../../admin_parameters.dart';
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

    super.initState();
  }

  void getProfil() async {
    loading = true;
    firstLoading = true;
    if (mounted) {
      setState(() {});
    }
    await DatabaseGetter().getUser();
    if (DatabaseGetter.user != null) {
      signedIn.value = true;
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

  void listenToInternet() async {

    internetListener =
        InternetConnection().onStatusChange.listen((InternetStatus status) {
      switch (status) {
        case InternetStatus.connected:
          if (noConnection) {
            Future.delayed(const Duration(milliseconds: 10)).whenComplete(() {
              displayInfoBar(context,
                  builder: (BuildContext context, void Function() close) {
                return InfoBar(
                  title: const Text('connectionback').tr(),
                  severity: InfoBarSeverity.success,
                );
              }, duration: snackbarShortDuration);
            });
            setState(() {
              noConnection = false;
            });
          }
          break;
        case InternetStatus.disconnected:
          if (!noConnection) {
            Future.delayed(const Duration(milliseconds: 10)).whenComplete(() {
              displayInfoBar(context,
                  builder: (BuildContext context, void Function() close) {
                return InfoBar(
                  title: const Text('noconnection').tr(),
                  severity: InfoBarSeverity.warning,
                );
              }, duration: snackbarShortDuration * 3);
            });
            setState(() {
              noConnection = true;
            });
          }
          break;
      }
    });
  }

  double pwidth = 250.px;

  FlyoutController flyoutController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (firstLoading) {
      return const Center(child: ProgressRing());
    }
    bool portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return ValueListenableBuilder(
        valueListenable: signedIn,
        builder: (BuildContext context, bool value, Widget? child) {
          widget.paneList.initPanes();
          return ValueListenableBuilder(
              valueListenable: index,
              builder: (BuildContext context, int value, Widget? child) {
                return NavigationView(
                  transitionBuilder: (w, d) => DrillInPageTransition(
                    animation: d,
                    child: w,
                  ),
                  appBar: NavigationAppBar(
                    automaticallyImplyLeading: false,
                    title: () {
                      return DragToMoveArea(
                        child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/logo.webp',
                                  width: 80.px,
                                  height: 80.px,
                                ),
                                smallSpace,
                                Text('v${packageInfo.version}'),
                                if (DatabaseGetter.trialDate != null &&
                                    DatabaseGetter.me.value != null)
                                  bigSpace,
                                if (DatabaseGetter.trialDate != null)
                                  const Text('daysremain').tr(namedArgs: {
                                    'days': DatabaseGetter.trialDate!
                                        .difference(DateTime.now())
                                        .inDays
                                        .toString()
                                  }),
                                if (demo && !portrait) bigSpace,
                                if (demo && !portrait)
                                  Text(
                                    'demofor'.tr().toUpperCase(),
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                if (brandt && !portrait) smallSpace,
                                if (brandt && !portrait)
                                  Image.asset(
                                    'assets/images/brandt.png',
                                    width: 60.px,
                                    height: 60.px,
                                  ),
                                const Spacer(),
                                if (!loading &&
                                    signedIn.value &&
                                    DatabaseGetter.trialDate != null)
                                  const NotifList(),
                                if (!loading &&
                                    signedIn.value &&
                                    DatabaseGetter.trialDate != null)
                                  const SizedBox(width: 10),
                                if (!loading &&
                                    signedIn.value &&
                                    DatabaseGetter.trialDate != null)
                                  const ProfilNameTopBar(),
                                smallSpace,
                                if (!kIsWeb)
                                  if (Platform.isMacOS ||
                                      Platform.isLinux ||
                                      Platform.isWindows)
                                    const WindowButtons(),
                              ],
                            )),
                      );
                    }(),
                  ),
                  pane: NavigationPane(
                    selected: value,
                    onChanged: (i) {
                      previousValue = index.value;
                      index.value = i;
                    },
                    size: NavigationPaneSize(
                      openMaxWidth: pwidth,
                    ),
                    displayMode: widget.appTheme.displayMode,
                    items: PaneItemsAndFooters.originalItems,
                    footerItems: PaneItemsAndFooters.footerItems,
                  ),
                );
              });
        });
  }

  @override
  void onWindowClose() {
    windowManager.isPreventClose().then((value) {
      if (value) {
        showDialog<String>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('sur').tr(),
            content: const Text(
              'sauv',
            ).tr(),
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
    });
  }

  @override
  void dispose() {
    internetListener?.cancel();
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
      child: (!kIsWeb &&
              (Platform.isMacOS || Platform.isLinux || Platform.isWindows))
          ? WindowCaption(
              brightness: theme.brightness,
              backgroundColor: Colors.transparent,
            )
          : const SizedBox(),
    );
  }
}
