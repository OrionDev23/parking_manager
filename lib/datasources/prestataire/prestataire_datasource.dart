
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/datasources/prestataire/prestataire_webservice.dart';
import 'package:parc_oto/serializables/prestataire.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../screens/prestataire/prestataire_form.dart';
import '../../screens/prestataire/prestataire_tabs.dart';

class PrestataireDataSource extends ParcOtoDatasource<Prestataire>{
  final bool archive;
  PrestataireDataSource({required super.collectionID, this.archive=false,required super.current,super.appTheme,super.filters,super.searchKey,super.selectC}){
    repo=PrestataireWebservice(data, collectionID, 1);
  }

  @override
  String deleteConfirmationMessage(Prestataire c) {
    return '${'supprest'.tr()} ${c.nom} ';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Prestataire> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );
    return [
      DataCell(SelectableText(
        element.value.nom,
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.telephone??'',
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.email??'',
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.nif??'',
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.rc??'',
        style: tstyle,
      )),
      DataCell(SelectableText(
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
                            text: Text('${"mod".tr()} ${'prestataire'.tr().toLowerCase()} ${element.value.nom}'),
                            semanticLabel: '${'mod'.tr()} ${element.value.nom} ',
                            icon: const Icon(f.FluentIcons.edit),
                            body: PrestataireForm(prest: element.value,),
                            onClosed: () {
                              PrestataireTabsState.tabs.remove(tab);

                              if (PrestataireTabsState.currentIndex.value > 0) {
                                PrestataireTabsState.currentIndex.value--;
                              }
                            },
                          );
                          final index = PrestataireTabsState.tabs.length + 1;
                          PrestataireTabsState.tabs.add(tab);
                          PrestataireTabsState.currentIndex.value = index - 1;
                        }
                    ),
                    f.MenuFlyoutItem(
                        text: const Text('delete').tr(),
                        onPressed: (){
                          showDeleteConfirmation(element.value);
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

  @override
  Future<void> addToActivity(c) async{
    await ClientDatabase().ajoutActivity(15, c.id,docName: c.nom);
  }

}