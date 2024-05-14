import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/backup/backup_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/serializables/backup.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/utilities/profil_beautifier.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
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
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');

    return [
      DataCell(
        Text('backupname'.tr(namedArgs: {
          'd': dateTime?.day.toString()??'01',
          'm':dateTime?.month.toString()??'01',
          'y':dateTime?.year.toString()??'2024',
          'h':dateTime?.hour.toString()??'09',
          'M':dateTime?.minute.toString()??'00',
          's':dateTime?.second.toString()??'00'
        })),
        onDoubleTap: ()=>showApplicationConfirmation(element),
      ),
      DataCell(
        SizedBox(
            width: 350.px,
            height: 100.px,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: createCountersWidget(element,appTheme!)),
              ],
            )),
        onDoubleTap: ()=>showApplicationConfirmation(element),
      ),
      DataCell(
        Text(dateFormat.format(element.value.createdAt??DateTime(2024,01,01,09)))
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
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      children: [
        if(element.value.vehicles!=0)
          counterElement('vehiclescount','v',element.value.vehicles,appTheme),
        if(element.value.vehicledocs!=0)
          counterElement('doccount','d',element.value.vehicles,appTheme),
        if(element.value.vehiclesstates!=0)
          counterElement('statecount','s',element.value.vehicles,appTheme),
        if(element.value.drivers!=0)
          counterElement('conducteurcount','c',element.value.vehicles,appTheme),
        if(element.value.driversdocs!=0)
          counterElement('doccount','d',element.value.vehicles,appTheme),
        if(element.value.driversstates!=0)
          counterElement('dispcount','d',element.value.vehicles,appTheme),
        if(element.value.repairs!=0)
          counterElement('reparationcount','r',element.value.vehicles,appTheme),
        if(element.value.providers!=0)
          counterElement('prestcount','p',element.value.vehicles,appTheme),
        if(element.value.plannings!=0)
          counterElement('planningcount','p',element.value.vehicles,appTheme),
        if(element.value.logs!=0)
          counterElement('logcount','l',element.value.vehicles,appTheme),
      ],
    );
  }

  Widget counterElement(String name,String key,int counter,AppTheme appTheme){
    return Row(
      children: [
        Flexible(
          child: Container(
            color: appTheme.color.lightest,
            child: Text(name.tr(namedArgs: {
              key:counter.toString(),
            })),
          ),
        )
      ],
    );
  }

  void showApplicationConfirmation(MapEntry<String,Backup> element) {

  }

}