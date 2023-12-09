import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_table.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_tabs.dart';
import 'package:parc_oto/serializables/document_chauffeur.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../screens/chauffeur/document/chauf_document_form.dart';
import '../../screens/chauffeur/document/chauf_document_tabs.dart';
import '../../screens/sidemenu/sidemenu.dart';
import 'cdocument_webservice.dart';

class ChaufDocumentsDataSource extends ParcOtoDatasource<DocumentChauffeur> {


  ChaufDocumentsDataSource({required super.current,super.selectC,required super.collectionID}){
    repo = ChaufDocumentWebService(data,collectionID,2);
  }

  void showMyChauffeur(String? chauffeur){
    if(chauffeur!=null){
      PanesListState.index.value=10;
      ChauffeurTabsState.currentIndex.value=0;

      ChauffeurTableState.filterNow=true;
      ChauffeurTableState.filterDocument.value=chauffeur;
    }
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, DocumentChauffeur> element) {
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
      DataCell(SelectableText(element.value.chauffeurNom ?? '',
          style: tstyle),
          onTap: (){
            showMyChauffeur(element.value.chauffeurNom);
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
                            body: CDocumentForm(
                              dc: element.value,
                            ),
                            onClosed: () {
                              CDocumentTabsState.tabs.remove(tab);

                              if (CDocumentTabsState.currentIndex.value >
                                  0) {
                                CDocumentTabsState.currentIndex.value--;
                              }
                            },
                          );
                          final index =
                              CDocumentTabsState.tabs.length + 1;
                          CDocumentTabsState.tabs.add(tab);
                          CDocumentTabsState.currentIndex.value =
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
   return '${'suprdoc'.tr()} ${c.nom} ${c.chauffeurNom}';
  }



}