import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/login.dart';
import 'package:parc_oto/screens/logout.dart';
import 'package:parc_oto/screens/sidemenu/profil_name_topbar.dart';
import 'package:parc_oto/screens/vehicle/brand/brand_list.dart';
import 'package:parc_oto/screens/vehicle/documents/document_tabs.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../chauffeur/chauffeur_tabs.dart';
import '../chauffeur/disponibilite/disponibilite_tabs.dart';
import '../dashboard/dashboard.dart';
import '../dashboard/notif_list.dart';
import '../settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme.dart';
import 'package:flutter/material.dart' as m;

const defaultUserPic =
    "https://upload.wikimedia.org/wikipedia/commons/7/72/Default-welcomer.png";

class PanesList extends StatefulWidget {
  final SharedPreferences prefs;
  const PanesList({
    super.key,
    required this.prefs,
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
    _index=v;
  }

  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  static ValueNotifier<bool> signedIn = ValueNotifier(false);
  static bool listening = false;

  late PaneItem acceuil;
  PaneItemSeparator separator = PaneItemSeparator();
  late PaneItem login;
  late PaneItem logout;
  late PaneItem parametres;

  late PaneItem vehicles;

  late PaneItem chauffeurs;

  late PaneItem evenements;

  late PaneItem reparations;
  void listenToSigningChanges() {}

  static List<NavigationPaneItem> originalItems = List.empty(growable: true);
  late List<NavigationPaneItem> footerItems;

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
    updateOriginalItems();
    listenToSigningChanges();
    loading = false;
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
          updateOriginalItems();
          return ValueListenableBuilder(
              valueListenable: index,
              builder: (BuildContext context, int value, Widget? child) {
                return NavigationView(
                  key: viewKey,
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
                                  FlyoutTarget(
                                    controller: flyoutController,
                                    child: OnTapScaleAndFade(
                                        child: Row(
                                          children: [
                                            const Icon(FluentIcons.ringer),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Text('Alertes'),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            m.Badge(
                                              backgroundColor:
                                                  appTheme.color.darkest,
                                              alignment: Alignment.topLeft,
                                              label: const Text('10'),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          flyoutController.showFlyout(
                                              autoModeConfiguration:
                                                  FlyoutAutoConfiguration(
                                                      preferredMode:
                                                          FlyoutPlacementMode
                                                              .bottomLeft),
                                              builder: (context) {
                                                return FlyoutContent(
                                                  child: SizedBox(
                                                    height: 30.h,
                                                    width: 30.w,
                                                    child: const NotifList(),
                                                  ),
                                                );
                                              });
                                        }),
                                  ),
                                if (!loading && signedIn.value)
                                  const SizedBox(width: 10),
                                if (!loading && signedIn.value)
                                  const ProfilNameTopBar(),
                                const SizedBox(
                                  width: 150,
                                ),
                              ],
                            )),
                      );
                    }(),
                    actions: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          WindowButtons(),
                        ]),
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
                    items: originalItems,
                    footerItems: footerItems,
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

  void updateOriginalItems() {
    acceuil = PaneItem(
        icon: const Icon(FluentIcons.home),
        body: const HomePage(),
        title: const Text('home').tr());
    vehicles = PaneItemExpander(
        icon: const Icon(FluentIcons.car),
        title: const Text('vehicules').tr(),
        items: [
          PaneItem(
              icon: const Icon(FluentIcons.list),
              title: const Text('gestionvehicles').tr(),
              body: const VehicleTabs()),
          PaneItem(
            icon: const Icon(FluentIcons.verified_brand),
            title: const Text('brands').tr(),
            body: const BrandList(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.health),
            title: const Text('vstates').tr(),
            body: const Placeholder(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.document_set),
            title: const Text('documents').tr(),
            body: const DocumentTabs(),
          ),
        ],
        body: const Text(''));
    reparations = PaneItemExpander(
        icon: const Icon(FluentIcons.repair),
        title: const Text('reparations').tr(),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text('greparations').tr(),
            body: const Placeholder(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.service_activity),
            title: const Text('prestataires').tr(),
            body: const Placeholder(),
          ),
        ],
        body: const SizedBox());
    chauffeurs = PaneItemExpander(
        icon: const Icon(FluentIcons.people),
        title: const Text("chauffeurs").tr(),
        body: const Placeholder(),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list),
            body: const ChauffeurTabs(),
            title: const Text('gchauffeurs').tr(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.document_set),
            title: const Text('documents').tr(),
            body: const Placeholder(),
          ),
          PaneItem(
            icon: const Icon(LineAwesome.check_double_solid),
            title: const Text('disponibilite').tr(),
            body: const DisponbiliteTabs(),
          ),
        ]);
    evenements = PaneItemExpander(
        items: [
          PaneItem(
              icon: const Icon(FluentIcons.edit),
              title: const Text("gestionevent").tr(),
              body: const Placeholder()),
          PaneItem(
              icon: const Icon(FluentIcons.reservation_orders),
              title: const Text('planifier').tr(),
              body: const Placeholder()),
          PaneItem(
              icon: const Icon(FluentIcons.parking_solid),
              title: const Text('parking').tr(),
              body: const Placeholder()),
        ],
        icon: const Icon(FluentIcons.event),
        title: const Text('journal').tr(),
        body: const Placeholder());
    login = PaneItem(
        icon: const Icon(FluentIcons.signin),
        title: const Text('seconnecter').tr(),
        body: const LoginScreen());
    logout = PaneItem(
        icon: const Icon(FluentIcons.sign_out),
        title: const Text('decon').tr(),
        body: const LogoutScreen());
    parametres = PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('parametres').tr(),
      body: Settings(widget.prefs),
    );

    if (signedIn.value) {
      originalItems = [
        acceuil,
        vehicles,
        reparations,
        chauffeurs,
        evenements,
      ];
    } else {
      originalItems = [
        login,
      ];
    }

    footerItems = [
      PaneItemSeparator(),
      if (signedIn.value) logout,
      parametres,
    ];
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
