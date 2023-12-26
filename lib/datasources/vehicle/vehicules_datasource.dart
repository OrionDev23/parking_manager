import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/vehicle/vehicle_webservice.dart';
import 'package:parc_oto/screens/vehicle/documents/document_form.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../screens/vehicle/manager/vehicle_form.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../serializables/vehicle.dart';
import '../parcoto_datasource.dart';

class VehiculesDataSource extends ParcOtoDatasource<Vehicle> {

  VehiculesDataSource({required super.current,super.appTheme,super.filters,super.searchKey,super.selectC, required super.collectionID}){
    repo =VehiculesWebService(data,collectionID,8);
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String,Vehicle> element) {
    final dateFormat=DateFormat('y/M/d HH:mm:ss','fr');
    final tstyle=TextStyle(
      fontSize: 10.sp,
    );
    return [
      DataCell(SelectableText(element.value.matricule,style: tstyle,)),
      DataCell(Row(
        children: [
          Image.asset('assets/images/marques/${element.value.marque ?? 'default'}.webp',width: 4.h,height: 4.h,),
          const SizedBox(width: 5,),
          Text(element.value.type ?? '',style: tstyle),
        ],
      )),
      DataCell(Text(element.value.anneeUtil.toString(),style: tstyle)),
      DataCell(Text(
          dateFormat.format(element.value.updatedAt!)
          ,style: tstyle)),
      DataCell(
    ClientDatabase().isAdmin() || ClientDatabase().isManager()

    ?f.FlyoutTarget(
        controller: element.value.controller,
        child: OnTapScaleAndFade(
            onTap: (){
              element.value.controller.showFlyout(builder: (context){
                return f.MenuFlyout(
                  items: [
                    f.MenuFlyoutItem(
                        text: const Text('mod').tr(),
                        onPressed: (){
                          Navigator.of(current).pop();
                          late f.Tab tab;
                          tab = f.Tab(
                            key: UniqueKey(),
                            text: Text('${"mod".tr()} ${'vehicule'.tr().toLowerCase()} ${element.value.matricule}'),
                            semanticLabel: '${'mod'.tr()} ${element.value.matricule}',
                            icon: const Icon(f.FluentIcons.edit),
                            body: VehicleForm(vehicle: element.value,),
                            onClosed: () {
                              VehicleTabsState.tabs.remove(tab);

                              if (VehicleTabsState.currentIndex.value > 0) {
                                VehicleTabsState.currentIndex.value--;
                              }
                            },
                          );
                          final index = VehicleTabsState.tabs.length + 1;
                          VehicleTabsState.tabs.add(tab);
                          VehicleTabsState.currentIndex.value = index - 1;
                        }
                    ),
                    if(ClientDatabase().isAdmin())
                    f.MenuFlyoutItem(
                        text: const Text('delete').tr(),
                        onPressed: (){
                          showDeleteConfirmation(element.value);
                        }
                    ),
                    const f.MenuFlyoutSeparator(),
                    f.MenuFlyoutItem(
                        text: const Text('nouvdocument').tr(),
                        onPressed: (){
                          f.showDialog(context: current,
                              barrierDismissible: true,
                              builder: (context){
                                return  DocumentForm(ve: element.value,);
                              });
                        }
                    ),
                    f.MenuFlyoutSubItem(
                      text: const Text('chstates').tr(),
                      items: (BuildContext context) {
                        return [
                          f.MenuFlyoutItem(
                              text: const Text('gstate').tr(),
                              onPressed: (){

                              }
                          ),
                          f.MenuFlyoutItem(
                              text: const Text('bstate').tr(),
                              onPressed: (){

                              }
                          ),
                          f.MenuFlyoutItem(
                              text: const Text('rstate').tr(),
                              onPressed: (){

                              }
                          ),
                        ];
                      },
                    ),
                  ],
                );
              });
            },
            child: const Icon(Icons.more_vert_sharp)),
      )
      :const Text(''),
      ),
    ];
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'supvehic'.tr()} ${c.matricule}';
  }


  @override
  Future<void> addToActivity(c) async{
    await ClientDatabase().ajoutActivity(2, c.id,docName: c.matricule);
  }


}






