import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/datasources/backup/backup_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/backup/backup_restore.dart';
import 'package:parc_oto/serializables/backup.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/utilities/profil_beautifier.dart';
import '../../providers/client_database.dart';
import '../../theme.dart';
import '../../widgets/on_tap_scale.dart';

class BackupDataSource extends ParcOtoDatasource<Backup>{
  BackupDataSource({required super.collectionID, required super.current,super
      .appTheme,super.filters,super.searchKey,super.selectC,super
      .sortAscending,super.sortColumn}){
    repo=BackupWebService(data, collectionID, 0);
  }

  @override
  Future<void> addToActivity(Backup c) async {

  }

  @override
  String deleteConfirmationMessage(Backup c) {
    return 'deletebackup'.tr();
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Backup> element) {
    DateTime? dateTime=dateFromIntJson(int.tryParse(element.value.id)??0);
    return [
      DataCell(
        Text('backupname'.tr(namedArgs: {
          'd': dateTime?.day.toString()??'01',
          'm':dateTime?.month.toString()??'01',
          'y':dateTime?.year.toString()??'2024',
          'h':dateTime?.hour.toString()??'09',
          'M':dateTime?.minute.toString()??'00',
          's':dateTime?.second.toString()??'00'
        }),style: rowTextStyle,),
        onDoubleTap: ()=>showApplicationConfirmation(element),
      ),
      DataCell(
        Padding(
            padding: const EdgeInsets.all(3),
            child: createCountersWidget(element,appTheme!)),
        onDoubleTap: ()=>showApplicationConfirmation(element),
      ),
      if (selectC != true && ClientDatabase().isAdmin())
        DataCell(f.FlyoutTarget(
            controller: element.value.controller,
            child: f.Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OnTapScaleAndFade(
                    onTap: ()=>showApplicationConfirmation(element),
                    child: f.Container(
                        decoration: BoxDecoration(
                          color: appTheme?.color.lightest,
                          boxShadow: kElevationToShadow[2],
                        ),
                        child: Icon(Icons
                            .check_box,color: appTheme!
                            .color.darkest,
                        ))),
                smallSpace,
                OnTapScaleAndFade(
                    onTap: ()=>showDeleteConfirmation(element.value),
                    child: f.Container(
                        decoration: BoxDecoration(
                          color: appTheme?.color.lightest,
                          boxShadow: kElevationToShadow[2],
                        ),
                        child: Icon(Icons.delete,color: appTheme!
                            .color.darkest,))
                ),
              ],
            ),
          )
        ),
    ];
  }



  Widget createCountersWidget(MapEntry<String,Backup> element,AppTheme
  appTheme){
    List<Widget> tiles= [
      if(element.value.vehicles!=0)
        counterElement('vehiclescount','v',element.value.vehicles,appTheme),
      if(element.value.vehicledocs!=0)
        counterElement('doccount','d',element.value.vehicledocs,appTheme),
      if(element.value.vehiclesstates!=0)
        counterElement('statecount','s',element.value.vehiclesstates,appTheme),
      if(element.value.drivers!=0)
        counterElement('conducteurcount','c',element.value.drivers,appTheme),
      if(element.value.driversdocs!=0)
        counterElement('doccount','d',element.value.driversdocs,appTheme),
      if(element.value.driversstates!=0)
        counterElement('dispcount','d',element.value.driversstates,appTheme),
      if(element.value.repairs!=0)
        counterElement('reparationcount','r',element.value.repairs,appTheme),
      if(element.value.providers!=0)
        counterElement('prestcount','p',element.value.providers,appTheme),
      if(element.value.plannings!=0)
        counterElement('planningcount','p',element.value.plannings,appTheme),
      if(element.value.logs!=0)
        counterElement('logcount','l',element.value.logs,appTheme),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: MasonryGridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            itemCount: tiles.length,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            itemBuilder: (con,index){
              return tiles[index];
            },
          ),
        ),
      ],
    );
  }

  Widget counterElement(String name,String key,int counter,AppTheme appTheme){
    return
        Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: appTheme.color.lightest,
              borderRadius: BorderRadius.circular(5)
            ),
            child: Text(name.tr(namedArgs: {
              key:counter.toString(),
            }),style: rowTextStyle,)
        );
  }

  void showApplicationConfirmation(MapEntry<String,Backup> element) {
    Future.delayed(const Duration(milliseconds: 30)).then((value) {
      f.showDialog(context: current, builder: (con){
        return BackupRestore(backup: element.value);
      });
    });
  }

  @override
  void deleteRow(c) async{
    await ClientDatabase.storage!.deleteFile(bucketId: backupId, fileId: c
        .id).then((value) =>super.deleteRow(c)).onError((error, stackTrace)
    {
      f.displayInfoBar(
        current,
        builder: (c, s) {
          return f.InfoBar(
              title: const Text('erreur').tr(),
              severity: f.InfoBarSeverity.error);
        },
        alignment:
        Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
      );
    });
  }

}