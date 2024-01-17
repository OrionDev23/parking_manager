import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../theme.dart';

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

        ListTile(
          onPressed: (){},
          title: Text('Nouveau véhicule ajouté!',style: TextStyle(color: appTheme.color.lightest),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
        ListTile(
          leading: Icon(FluentIcons.alert_solid,color: appTheme.color.lightest,),
          title: Text('Vehicule en panne',style: TextStyle(color: appTheme.color.dark),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
        ListTile(
          leading: Icon(FluentIcons.alert_solid,color: appTheme.color.lightest,),
          title: Text('Vehicule en panne',style: TextStyle(color: appTheme.color.dark),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
        ListTile(
          title: Text('Nouveau véhicule ajouté!',style: TextStyle(color: appTheme.color.lightest),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
        ListTile(
          title: Text('Nouveau véhicule ajouté!',style: TextStyle(color: appTheme.color.lightest),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
        ListTile(
          title: Text('Nouveau véhicule ajouté!',style: TextStyle(color: appTheme.color.lightest),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
        ListTile(
          title: Text('Nouveau véhicule ajouté!',style: TextStyle(color: appTheme.color.lightest),),
          trailing: IconButton(icon:Icon(FluentIcons.delete,color: appTheme.color.darkest,),onPressed: (){},),
        ),
      ],
    );
  }
}
