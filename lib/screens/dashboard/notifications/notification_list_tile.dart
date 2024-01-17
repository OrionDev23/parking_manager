import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

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
              style: TextStyle(color: appTheme.color.lightest),
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
            child: const Text(
              'oui',
              style: textStyle,
            ).tr(),
            onPressed: () {}),
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
