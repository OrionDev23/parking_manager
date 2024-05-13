import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Badge, LinearProgressIndicator;
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/planning_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/serializables/conducteur/document_chauffeur.dart';
import 'package:parc_oto/serializables/planning.dart';
import 'package:parc_oto/serializables/vehicle/document_vehicle.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/notification.dart';
import '../../../theme.dart';
import '../../../widgets/on_tap_scale.dart';
import 'notification_list_tile.dart';

class NotifList extends StatefulWidget {
  const NotifList({super.key});

  @override
  State<NotifList> createState() => NotifListState();
}

class NotifListState extends State<NotifList>
    with AutomaticKeepAliveClientMixin {
  static ValueNotifier<int> changes = ValueNotifier(0);

  static List<PNotification> tiles = [];

  static bool loaded = false;

  @override
  void initState() {
    getNotifs();
    super.initState();
  }

  static void remove(String id) {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].id == id) {
        tiles.removeAt(i);
        break;
      }
    }
  }

  bool loading = false;

  List<Planning> plannings = [];
  List<DocumentVehicle> docVehic = [];
  List<DocumentChauffeur> docChauf = [];

  Future<void> getNotifs() async {
    if (!loaded) {
      loading = true;
      tiles.clear();

      if (mounted) {
        setState(() {});
      }
      await Future.wait([getVehicDocs(), getPlanningDocs(), getChaufDocs()]);
      createNotifListFromLists();
      loading = false;
      loaded = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  DateTime beforTime = DateTime.now().add(const Duration(days: 60));

  Future<void> getVehicDocs() async {
    docVehic = await VehicleProvider().getDocumentsBeforeTime(beforTime);
  }

  Future<void> getChaufDocs() async {
    docChauf = await DriverProvider().getConduDocumentsBeforeTime(beforTime);
  }

  Future<void> getPlanningDocs() async {
    plannings = await PlanningProvider().getPlanningBeforeTime(beforTime);
  }

  void createNotifListFromLists() {
    int i;
    for (i = 0; i < docVehic.length; i++) {
      tiles.add(PNotification(
          id: docVehic[i].id,
          title: docVehic[i].nom,
          type: 0,
          date: docVehic[i].dateExpiration!));
    }
    for (i = 0; i < docChauf.length; i++) {
      tiles.add(PNotification(
          id: docChauf[i].id,
          title: docChauf[i].nom,
          type: 1,
          date: docChauf[i].dateExpiration!));
    }
    for (i = 0; i < plannings.length; i++) {
      tiles.add(PNotification(
          id: plannings[i].id,
          title: plannings[i].subject,
          type: 2,
          date: plannings[i].startTime));
    }

    tiles.sort((a, b) => a.date.compareTo(b.date));
  }

  FlyoutController flyoutController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    if (loading) {
      return const Center(
          child: SizedBox(
              width: 64, height: 16, child: LinearProgressIndicator()));
    }
    return ValueListenableBuilder(
        valueListenable: changes,
        builder: (context, c, w) {
          return FlyoutTarget(
            controller: flyoutController,
            child: OnTapScaleAndFade(
                onTap: loading
                    ? null
                    : () {
                        showNotifications();
                      },
                child: Badge(
                  backgroundColor: appTheme.color.lightest,
                  alignment: Alignment.bottomRight,
                  offset: const Offset(5, 5),
                  label: Text(tiles.length.toString()),
                  isLabelVisible: tiles.isNotEmpty,
                  child: tiles.isNotEmpty
                      ? Icon(
                          FluentIcons.ringer_solid,
                          size: 24,
                          color: appTheme.color.darkest,
                        )
                      : Icon(
                          FluentIcons.ringer,
                          size: 24,
                          color: appTheme.color.darkest,
                        ),
                )),
          );
        });
  }

  void showNotifications() {
    flyoutController.showFlyout(
        autoModeConfiguration: FlyoutAutoConfiguration(
            preferredMode: FlyoutPlacementMode.bottomLeft),
        builder: (context) {
          return StatefulBuilder(builder: (context, setS) {
            return FlyoutContent(
              child: SizedBox(
                height: 270.px,
                width: 400.px,
                child: loading
                    ? const ProgressBar()
                    : Column(
                        children: [
                          SizedBox(
                            width: 400.px,
                            height: 40.px,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'notifications'.tr().toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.grey[100],
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                smallSpace,
                                IconButton(
                                    icon: const Icon(FluentIcons.refresh),
                                    onPressed: () {
                                      loaded = false;
                                      getNotifs().then((value) {
                                        setS(() {});
                                      });
                                      setS(() {});
                                    })
                              ],
                            ),
                          ),
                          Flexible(
                            child: ListView(
                              children: tiles
                                  .map((e) => NotificationTile(
                                        pNotification: e,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          });
        });
  }

  @override
  bool get wantKeepAlive => true;
}
