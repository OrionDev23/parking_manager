import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/datasources/vehicle/vehicle_webservice.dart';
import 'package:parc_oto/screens/vehicle/documents/document_form.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../screens/vehicle/manager/vehicle_form.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../serializables/vehicle.dart';
import '../parcoto_datasource.dart';
import '../parcoto_webservice_response.dart';

class VehiculesDataSource extends ParcOtoDatasource<Vehicle> {




  VehiculesDataSource({required super.current,super.appTheme,super.filters,super.searchKey,super.selectC, required super.collectionID}){
    repo =VehiculesWebService(data,collectionID,8);
  }
  @override
  DataRow rowDisplay(int startIndex, int count,dynamic element) {
    final dateFormat=DateFormat('y/M/d HH:mm:ss','fr');
    final tstyle=TextStyle(
      fontSize: 10.sp,
    );
          return DataRow(
            key: ValueKey<String>(element.value.id),
            onSelectChanged: selectC==true? (value) {
              if (value ==true) {
                selectRow(element.value);
              }
            }:null,
            cells: [
              DataCell(SelectableText(element.value.matricule,style: tstyle,)),
              DataCell(Row(
                children: [
                  Image.asset('assets/images/marques/${element.value.marque ?? 'default'}.webp',width: 4.h,height: 4.h,),
                  const SizedBox(width: 5,),
                  SelectableText(element.value.type ?? '',style: tstyle),
                ],
              )),
              DataCell(SelectableText(element.value.anneeUtil.toString(),style: tstyle)),
              DataCell(SelectableText(
                  dateFormat.format(element.value.dateModification!)
                  ,style: tstyle)),
              DataCell(f.FlyoutTarget(
                controller: element.value.controller,
                child: IconButton(
                    splashRadius: 15,
                    onPressed: (){
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
                                  icon: const Icon(Bootstrap.car_front),
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
                                  f.showDialog(context: context,
                                      barrierDismissible: true,
                                      builder: (context){
                                    return  DocumentForm(v: element.value,);
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
                    icon: const Icon(Icons.more_vert_sharp)),
              )),
            ],
          );
  }

  @override
  DataRow rowDisplay(int startIndex,int count,dynamic element){


    return DataRow(
      key: ValueKey<String>(element.value.id),
      onSelectChanged: selectC==true? (value) {
        if (value ==true) {
          selectRow(element.value);
        }
      }:null,
      cells: [
        DataCell(SelectableText(element.value.matricule,style: tstyle,)),
        DataCell(Row(
          children: [
            Image.asset('assets/images/marques/${element.value.marque ?? 'default'}.webp',width: 4.h,height: 4.h,),
            const SizedBox(width: 5,),
            SelectableText(element.value.type ?? '',style: tstyle),
          ],
        )),
        DataCell(SelectableText(element.value.anneeUtil.toString(),style: tstyle)),
        DataCell(SelectableText(
            dateFormat.format(element.value.dateModification!)
            ,style: tstyle)),
        DataCell(f.FlyoutTarget(
          controller: element.value.controller,
          child: IconButton(
              splashRadius: 15,
              onPressed: (){
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
                              icon: const Icon(Bootstrap.car_front),
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
                            f.showDialog(context: context,
                                barrierDismissible: true,
                                builder: (context){
                                  return  DocumentForm(v: element.value,);
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
              icon: const Icon(Icons.more_vert_sharp)),
        )),
      ],
    );
  }


  @override
  void showDeleteConfirmation(Vehicle c){

    f.showDialog(
        context: current,
        builder: (context){
          return f.ContentDialog(
            content: Text('${'supvehic'.tr()} ${c.matricule}'),
            actions: [
              f.FilledButton(onPressed: (){
                Navigator.of(context).pop();
              }, child: const Text('annuler').tr()),
              f.Button(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                deleteRow(c);

              },child: const Text('confirmer').tr(),)
            ],
          );
        }
        );
  }



}






