import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

class NotificationTile extends StatefulWidget {

  final String id;
  final String title;
  final int type;
  final DateTime date;
  const NotificationTile({super.key,required this.id,required this.type,required this.date,required this.title});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {


  bool toDelete=false;
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ListTile(
      onPressed: (){},
      title: Text('Nouveau véhicule ajouté!',style: TextStyle(color: appTheme.color.lightest),),
      trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
    );
  }
}
