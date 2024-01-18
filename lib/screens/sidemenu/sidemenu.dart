import 'dart:io';

import 'package:flutter/foundation.dart';

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
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      windowManager.setPreventClose(true);
      windowManager.addListener(this);
    }
    adjustSize();

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

  double pwidth = 20.w;

  void adjustSize() {
    if (kIsWeb) {
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        pwidth = 60.w;
      } else {
        pwidth = 20.w;
      }
    }
  }

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
                                  width: 80,
                                  height: 80,
                                ),
                                const Spacer(),
                                if (!loading && signedIn.value)
                                  const NotifList(),
                                if (!loading && signedIn.value)
                                  const SizedBox(width: 10),
                                if (!loading && signedIn.value)
                                  const ProfilNameTopBar(),
                                smallSpace,
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
