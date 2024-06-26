import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/planning_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/screens/dashboard/notifications/notif_list.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../../admin_parameters.dart';
import '../../../main.dart';
import '../../../serializables/notification.dart';
import '../../sidemenu/pane_items.dart';
import '../../sidemenu/sidemenu.dart';

class NotificationTile extends StatefulWidget {
  final PNotification pNotification;

  const NotificationTile({super.key, required this.pNotification});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool toDelete = false;

  String typedText = '';

  @override
  void initState() {
    loadText();
    super.initState();
  }

  void loadText() {
    String day = '';
    int differenceInDays =
        widget.pNotification.date.difference(DateTime.now()).inDays;

    if (differenceInDays < 0) {
      day = "a expiré";
    } else if (differenceInDays == 0) {
      day = "expire aujourd'hui";
    } else if (differenceInDays == 1) {
      day = "expire demain";
    } else {
      day = "expire dans $differenceInDays jours";
    }

    if (widget.pNotification.type == 0) {
      typedText = "Le document '${widget.pNotification.title}' $day";
    } else if (widget.pNotification.type == 1) {
      typedText = "Le document '${widget.pNotification.title}' $day";
    } else {
      typedText = "Le planning '${widget.pNotification.title}' $day";
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ListTile(
      onPressed: toDelete ? null : goThere,
      title: toDelete
          ? deleteNotifWidget()
          : Text(
              typedText,
              style: TextStyle(color: appTheme.color.lightest, fontSize: 14),
            ),
      trailing: toDelete
          ? null
          : IconButton(
              icon: Icon(
                FluentIcons.cancel,
                color: appTheme.color.darkest,
              ),
              onPressed: () {
                setState(() {
                  toDelete = true;
                });
              },
            ),
    );
  }

  Widget deleteNotifWidget() {
    const textStyle = TextStyle(fontSize: 13);
    return Row(
      children: [
        const Text(
          'deletenotif',
          style: textStyle,
        ).tr(),
        const Spacer(),
        Button(
            onPressed: deleteThis,
            child: const Text(
              'oui',
              style: textStyle,
            ).tr()),
        bigSpace,
        FilledButton(
          child: const Text(
            'non',
            style: textStyle,
          ).tr(),
          onPressed: () {
            toDelete = false;
            setState(() {});
          },
        ),
      ],
    );
  }

  void deleteThis() async {
    String recordName = widget.pNotification.type == 0
        ? 'removedDocs'
        : widget.pNotification.type == 1
            ? 'removedCondDocs'
            : 'removedPlanning';

    late List<String> storedData;
    if (widget.pNotification.type == 0) {
      VehicleProvider.removedVehiDocs = prefs.getStringList(recordName) ?? [];
      storedData = VehicleProvider.removedVehiDocs;
    } else if (widget.pNotification.type == 1) {
      DriverProvider.removedCondDocs = prefs.getStringList(recordName) ?? [];
      storedData = DriverProvider.removedCondDocs;
    } else {
      PlanningProvider.removedPlanDocs = prefs.getStringList(recordName) ?? [];
      storedData = PlanningProvider.removedPlanDocs;
    }

    storedData.add(widget.pNotification.id);

    await prefs.setStringList(recordName, storedData).then((value) {
      if (widget.pNotification.type == 0) {
        VehicleProvider.removedVehiDocs.add(widget.pNotification.id);
      } else if (widget.pNotification.type == 1) {
        DriverProvider.removedCondDocs.add(widget.pNotification.id);
      } else {
        PlanningProvider.removedPlanDocs.add(widget.pNotification.id);
      }
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      Navigator.pop(context);

      if (kDebugMode) {
        print(stackTrace);
      }
    });

    NotifListState.remove(widget.pNotification.id);
    NotifListState.changes.value++;
  }

  void goThere() {
    switch (widget.pNotification.type) {
      case 0:
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
            PaneItemsAndFooters.vehicles.items.length;
        break;
      case 1:
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.chauffeurs) +

            PaneItemsAndFooters.vehicles.items.length+PaneItemsAndFooters
            .reparations.items.length+(showAtelier?PaneItemsAndFooters
            .atelier.items.length:0)+1;
        break;
      case 2:
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.planner) +

            PaneItemsAndFooters.vehicles.items.length+PaneItemsAndFooters
            .reparations.items.length+(showAtelier?PaneItemsAndFooters
            .atelier.items.length:0)+PaneItemsAndFooters.chauffeurs.items
            .length-2;
        break;
    }
    Navigator.of(context).pop();
  }
}
