import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/document/document_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/vehicle/documents/document_form.dart';
import 'package:parc_oto/screens/vehicle/documents/document_tabs.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../screens/sidemenu/sidemenu.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../screens/vehicle/vehicles_table.dart';

class DocumentsDataSource extends ParcOtoDatasource<DocumentVehicle> {


  DocumentsDataSource({required super.current,super.selectC,required super.collectionID}){
    repo = DocumentWebService(data,collectionID,1);
  }

  void showMyVehicule(String? matricule){
    if(matricule!=null){
      PanesListState.index.value=2;
      VehicleTabsState.currentIndex.value=0;

      VehicleTableState.filterNow=true;
      VehicleTableState.filterVehicule.value=matricule;
    }
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, DocumentVehicle> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );

    return [
      DataCell(SelectableText(
        element.value.nom,
        style: tstyle,
      )),
      DataCell(SelectableText(element.value.vehicle?.matricule ?? '',
          style: tstyle),
          onTap: (){
            showMyVehicule(element.value.vehicle?.matricule);
          }

      ),
      DataCell(SelectableText(
          element.value.dateExpiration!=null?
          dateFormat2.format(ClientDatabase.ref.add(
              Duration(milliseconds: element.value.dateExpiration!))):'',
          style: tstyle)),
      DataCell(SelectableText(
          element.value.updatedAt!=null?
          dateFormat.format(element.value.updatedAt!):'',
          style: tstyle)),
      DataCell(f.FlyoutTarget(
        controller: element.value.controller,
        child: IconButton(
            splashRadius: 15,
            onPressed: () {
              element.value.controller.showFlyout(builder: (context) {
                return f.MenuFlyout(
                  items: [
                    f.MenuFlyoutItem(
                        text: const Text('mod').tr(),
                        onPressed: () {
                          Navigator.of(current).pop();
                          late f.Tab tab;
                          tab = f.Tab(
                            key: UniqueKey(),
                            text: Text(
                                '${"mod".tr()} ${'document'.tr().toLowerCase()} ${element.value.nom}'),
                            semanticLabel:
                            '${'mod'.tr()} ${element.value.nom}',
                            icon: const Icon(Bootstrap.car_front),
                            body: DocumentForm(
                              vd: element.value,
                            ),
                            onClosed: () {
                              DocumentTabsState.tabs.remove(tab);

                              if (DocumentTabsState.currentIndex.value >
                                  0) {
                                DocumentTabsState.currentIndex.value--;
                              }
                            },
                          );
                          final index =
                              DocumentTabsState.tabs.length + 1;
                          DocumentTabsState.tabs.add(tab);
                          DocumentTabsState.currentIndex.value =
                              index - 1;
                        }),
                    f.MenuFlyoutItem(
                        text: const Text('delete').tr(),
                        onPressed: () {
                          showDeleteConfirmation(element.value);
                        }),
                  ],
                );
              });
            },
            icon: const Icon(Icons.more_vert_sharp)),
      )),
    ];
  }

  @override
  String deleteConfirmationMessage(c) {
   return '${'suprdoc'.tr()} ${c.nom} ${c.vehicle?.matricule}';
  }



}
