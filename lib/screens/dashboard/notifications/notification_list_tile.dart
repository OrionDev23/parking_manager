import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/dashboard/notifications/notif_list.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../sidemenu/pane_items.dart';
import '../../sidemenu/sidemenu.dart';

class NotificationTile extends StatefulWidget {
  final String id;
  final String title;
  final int type;
  final DateTime date;
  const NotificationTile(
      {super.key,
      required this.id,
      required this.type,
      required this.date,
      required this.title});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool toDelete = false;
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ListTile(
      onPressed: toDelete ? null : goThere,
      title: toDelete
          ? deleteNotifWidget()
          : Text(
              widget.title,
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



  void deleteThis() async{
    String recordName=widget.type==0?'removedDocs':widget.type==1?'removedCondDocs':'removedPlanning';

    List<String> storedData=prefs.getStringList(recordName)??[];

    print('stored data : ${storedData.toString()}');

    storedData.add(widget.id);

    await prefs.setStringList(recordName, storedData).then((value) {
      if(widget.type==0){
        ClientDatabase.removedVehiDocs.add(widget.id);
      }
      else if(widget.type==1){
        ClientDatabase.removedCondDocs.add(widget.id);
      }
      else{
        ClientDatabase.removedPlanDocs.add(widget.id);
      }
    }).onError((error, stackTrace) {
      if (kDebugMode) {
        print(stackTrace);
      }
    });

    NotifListState.remove(widget.id);
    NotifListState.changes.value++;

  }

  void goThere() {
    switch (widget.type) {
      case 0:
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
            4;
        break;
      case 1:
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.chauffeurs) +
            9;
        break;
      case 2:
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.planner) +
            10;
        break;
    }
    Navigator.of(context).pop();
  }

}
