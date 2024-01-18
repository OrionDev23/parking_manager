import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../theme.dart';
import '../../../widgets/on_tap_scale.dart';
import 'notification_list_tile.dart';
import 'package:flutter/material.dart' show Badge;

class NotifList extends StatefulWidget {
  const NotifList({super.key});

  @override
  State<NotifList> createState() => NotifListState();
}

class NotifListState extends State<NotifList> {
  static ValueNotifier<int> changes = ValueNotifier(0);

  static List<NotificationTile> tiles = [
    NotificationTile(id: '1', type: 1, date: DateTime.now(), title: 'Test 1'),
    NotificationTile(id: '2', type: 1, date: DateTime.now(), title: 'Test 1'),
    NotificationTile(id: '3', type: 1, date: DateTime.now(), title: 'Test 1'),
  ];

  @override
  void initState() {
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

  FlyoutController flyoutController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();

    return ValueListenableBuilder(
        valueListenable: changes,
        builder: (context, c, w) {
          return FlyoutTarget(
            controller: flyoutController,
            child: OnTapScaleAndFade(
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
                ),
                onTap: () {
                  flyoutController.showFlyout(
                      autoModeConfiguration: FlyoutAutoConfiguration(
                          preferredMode: FlyoutPlacementMode.bottomLeft),
                      builder: (context) {
                        return FlyoutContent(
                          child: SizedBox(
                            height: 30.h,
                            width: 30.w,
                            child: ListView(
                              children: tiles,
                            ),
                          ),
                        );
                      });
                }),
          );
        });
  }
}
