import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/vehicle/documents/document_form.dart';
import 'package:parc_oto/screens/vehicle/documents/document_tabs.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../screens/sidemenu/sidemenu.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../screens/vehicle/manager/vehicles_table.dart';
import '../../widgets/on_tap_scale.dart';
import 'document_webservice.dart';

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
      DataCell(SelectableText(element.value.vehiclemat ?? '',
          style: tstyle),
          onTap: (){
            showMyVehicule(element.value.vehiclemat);
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
      DataCell(
      ClientDatabase().isAdmin() || ClientDatabase().isManager()
    ? f.FlyoutTarget(
        controller: element.value.controller,
        child: OnTapScaleAndFade(
            onTap: () {
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
                            icon: const Icon(f.FluentIcons.edit),
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
                    if(ClientDatabase().isAdmin())
                    f.MenuFlyoutItem(
                        text: const Text('delete').tr(),
                        onPressed: () {
                          showDeleteConfirmation(element.value);
                        }),
                  ],
                );
              });
            },
            child: const Icon(Icons.more_vert_sharp)),
      )
      :const Text('')
      ),
    ];
  }

  @override
  String deleteConfirmationMessage(c) {
   return '${'suprdoc'.tr()} ${c.nom} ${c.vehiclemat}';
  }

  @override
  Future<void> addToActivity(c) async{
    await ClientDatabase().ajoutActivity(9, c.id,docName: '${c.nom} ${c.vehiclemat}');
  }

}
