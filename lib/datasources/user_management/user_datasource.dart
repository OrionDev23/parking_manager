import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/user_management/user_webservice.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../parcoto_datasource.dart';

class UsersManagementDatasource extends ParcOtoDatasourceUsers<User,List<Membership>?>{
  final bool archive;
  UsersManagementDatasource({required super.current,super.appTheme,super.searchKey,super.selectC,this.archive=false}){
    repo=UsersWebservice(data);
  }

  @override
  Future<void> addToActivity(User c) async{
    await ClientDatabase().ajoutActivity(35, c.$id,docName: c.name.isEmpty?c.email:c.name);

  }

  @override
  String deleteConfirmationMessage(User c) {
    return '${'supreuser'.tr()} ${c.name.isEmpty?c.email:c.name}';
  }

  @override
  void deleteRow(c,t) async{
    var client =(repo as UsersWebservice).client;


    await Future.wait([
     Users(client)
        .delete(userId: c.$id).then((value) async{
      await Databases(client).deleteDocument(
          databaseId: databaseId,
          collectionId: userid,
          documentId: c.$id);
      data.remove(MapEntry(c, t));
      refreshDatasource();
    }),
      addToActivity(c),
    ]).onError((error, stackTrace) {
      return [
        f.displayInfoBar(current,builder: (c,s){
          return  f.InfoBar(
              title: const Text('erreur').tr(),
              severity: f.InfoBarSeverity.error
          );
        },
          alignment: Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
        )
      ];});
  }



  @override
  List<DataCell> getCellsToShow(MapEntry<User, List<Membership>?> element) {
    final dateFormat=DateFormat('y/M/d HH:mm:ss','fr');
    final tstyle=TextStyle(
      fontSize: 10.sp,
    );
    String roles='';
    element.value?.forEach((element) {
      if(roles.isNotEmpty){
        roles+=', ';
      }
      roles+=element.teamName.tr();
    });
    return [
      DataCell(SelectableText(element.key.name
          ,style: tstyle)),
      DataCell(SelectableText(element.key.email
          ,style: tstyle)),
      DataCell(SelectableText(element.key.$id
          ,style: tstyle)),
      DataCell(SelectableText((roles).toLowerCase().tr()
          ,style: tstyle)),
      DataCell(SelectableText(
          dateFormat.format(DateTime.parse(element.key.$createdAt))
          ,style: tstyle)),
      DataCell(f.FlyoutTarget(
        controller: controllers[element.key.$id]!,
        child: IconButton(
            splashRadius: 15,
            onPressed: (){
              controllers[element.key.$id]!.showFlyout(builder: (context){
                return f.MenuFlyout(
                  items: [
                    f.MenuFlyoutItem(
                        text: const Text('mod').tr(),
                        onPressed: (){
                          Navigator.of(current).pop();
                        }
                    ),
                    f.MenuFlyoutItem(
                        text: const Text('delete').tr(),
                        onPressed: (){
                          showDeleteConfirmation(element.key,element.value);
                        }
                    ),
                  ],
                );
              });
            },
            icon: const Icon(Icons.more_vert_sharp)),
      )),
    ];
  }

}