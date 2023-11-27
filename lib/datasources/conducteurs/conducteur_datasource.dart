import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/conducteurs/conducteur_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/chauffeur/chauffeur_form.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../screens/vehicle/documents/document_form.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../serializables/conducteur.dart';

class ConducteurDataSource extends ParcOtoDatasource<Conducteur>{
  ConducteurDataSource({required super.collectionID, super.selectC,super.searchKey,super.appTheme,super.filters,required super.current}){
    repo=ConducteurWebService(data, collectionID, 1);
  }

  @override
  String deleteConfirmationMessage(Conducteur c) {
    return '${'supchauf'.tr()} ${c.name} ${c.prenom}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Conducteur> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );
    return
      [
        DataCell(SelectableText(
          '${element.value.name} ${element.value.prenom}',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.email??'',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.email??'',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.telephone ??'',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.adresse ??'',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.dateNaissance==null?'':
          dateFormat2.format(element.value.dateNaissance!),
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.updatedAt==null?'':
          dateFormat.format(element.value.updatedAt!),
          style: tstyle,
        )),
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
                              text: Text('${"mod".tr()} ${'chauffeur'.tr().toLowerCase()} ${element.value.name}'),
                              semanticLabel: '${'mod'.tr()} ${element.value.name} ${element.value.prenom}',
                              icon: const Icon(Bootstrap.car_front),
                              body: ChauffeurForm(chauf: element.value,),
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
                                  return  const DocumentForm();
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
    ];
  }



}