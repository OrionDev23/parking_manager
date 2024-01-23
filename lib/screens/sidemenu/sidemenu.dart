import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/sidemenu/profil_name_topbar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../dashboard/notifications/notif_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme.dart';

const defaultUserPic =
    "https://upload.wikimedia.org/wikipedia/commons/7/72/Default-welcomer.png";

const demo=true;
const brandt=true;
class PanesList extends StatefulWidget {
  final PaneItemsAndFooters paneList;
  final Widget? widget;
  const PanesList({
    super.key,
    required this.paneList, this.widget,
  });

  @override
  State<PanesList> createState() => PanesListState();
}

class PanesListState extends State<PanesList> with WindowListener {
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

  static bool firstLoading=true;

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
    if (mounted) {
      setState(() {});
    }
    await ClientDatabase().getUser();
    if(ClientDatabase.user!=null) {
      signedIn.value=true;
    }
      widget.paneList.initPanes();
    loading = false;
    firstLoading=false;
    if (mounted) {
      setState(() {});
    }
  }


  bool noConnection=false;
  StreamSubscription<InternetStatus>? listener;
  void listenToInternet(){
     listener = InternetConnection().onStatusChange.listen((InternetStatus status) {
      switch (status) {
        case InternetStatus.connected:

          if(noConnection){
            displayInfoBar(context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('connectionback').tr(),
                    severity: InfoBarSeverity.success,
                  );
                },
                duration: snackbarShortDuration);
            setState(() {
              noConnection=false;
            });
          }
          break;
        case InternetStatus.disconnected:
          setState(() {
            noConnection=true;
          });
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
                return InfoBar(
                    title: const Text('noconnection').tr(),
                    severity: InfoBarSeverity.warning,
                );
              },
              duration: snackbarShortDuration*3);
          break;
      }
    });
  }

  double pwidth = 250.px;


  FlyoutController flyoutController = FlyoutController();
  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    if (loading) {
      return const Center(child: ProgressRing());
    }
    return ValueListenableBuilder(
        valueListenable: signedIn,
        builder: (BuildContext context, bool value, Widget? child) {
          widget.paneList.initPanes();
          return ValueListenableBuilder(
              valueListenable: index,
              builder: (BuildContext context, int value, Widget? child) {
                return NavigationView(
                  key: UniqueKey(),
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
                                if(demo && ClientDatabase.me.value!=null)
                                  bigSpace,
                                if(demo && ClientDatabase.trialDate!=null)
                                  const Text('daysremain').tr(namedArgs: {'days':ClientDatabase.trialDate!.difference(DateTime.now()).inDays.toString()}),
                                if(demo)
                                  bigSpace,
                                if(demo)
                                  Text('demofor'.tr().toUpperCase(),style: TextStyle(fontStyle:FontStyle.italic,color: Colors.red,fontSize: 14,),),
                                if(brandt)
                                  smallSpace,
                                if(brandt)
                                  Image.asset(
                                    'assets/images/brandt.png',
                                    width: 60.px,
                                    height: 60.px,
                                  ),

                                const Spacer(),
                                if (!loading && signedIn.value)
                                  const NotifList(),
                                if (!loading && signedIn.value)
                                  const SizedBox(width: 10),
                                if (!loading && signedIn.value)
                                  const ProfilNameTopBar(),

                                smallSpace,
                                if(!kIsWeb)
                                if(Platform.isMacOS || Platform.isLinux || Platform.isWindows)
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
                    displayMode: appTheme.displayMode,
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
    listener?.cancel();
    super.dispose();
  }
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
