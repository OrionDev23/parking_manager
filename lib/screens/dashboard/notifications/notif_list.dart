import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../theme.dart';
import 'notification_list_tile.dart';

class NotifList extends StatefulWidget {
  const NotifList({super.key});

  @override
  State<NotifList> createState() => _NotifListState();
}

class _NotifListState extends State<NotifList> {

    @override
  Widget build(BuildContext context) {
      var appTheme=context.watch<AppTheme>();
    return ListView(
      children: [

        NotificationTile(id: 'd',title: 'This is a test',type: 0,date: DateTime.now(),),
        NotificationTile(id: 'd',title: 'This is a test',type: 0,date: DateTime.now(),),
        NotificationTile(id: 'd',title: 'This is a test',type: 0,date: DateTime.now(),),
      ],
    );
  }
}
