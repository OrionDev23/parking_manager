import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_table.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_tabs.dart';
import 'package:parc_oto/serializables/document_chauffeur.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../screens/chauffeur/document/chauf_document_form.dart';
import '../../screens/chauffeur/document/chauf_document_tabs.dart';
import '../../screens/sidemenu/sidemenu.dart';
import '../../widgets/on_tap_scale.dart';
import 'cdocument_webservice.dart';

class ChaufDocumentsDataSource extends ParcOtoDatasource<DocumentChauffeur> {
  ChaufDocumentsDataSource(
      {required super.current, super.selectC, required super.collectionID}) {
    repo = ChaufDocumentWebService(data, collectionID, 2);
  }

  void showMyChauffeur(String? chauffeur) {
    if (chauffeur != null) {
      PanesListState.index.value = 10;
      ChauffeurTabsState.currentIndex.value = 0;

      ChauffeurTableState.filterNow = true;
      ChauffeurTableState.filterDocument.value = chauffeur;
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
      DataCell(SelectableText(element.value.chauffeurNom ?? '', style: tstyle),
          onTap: () {
        showMyChauffeur(element.value.chauffeurNom);
      }),
      DataCell(SelectableText(
          element.value.dateExpiration != null
              ? dateFormat2.format(ClientDatabase.ref
                  .add(Duration(milliseconds: element.value.dateExpiration!)))
              : '',
          style: tstyle)),
      DataCell(SelectableText(
          element.value.updatedAt != null
              ? dateFormat.format(element.value.updatedAt!)
              : '',
          style: tstyle)),
      DataCell(ClientDatabase().isAdmin() || ClientDatabase().isManager()
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
                          if (ClientDatabase().isAdmin())
                            f.MenuFlyoutItem(
                                text: const Text('delete').tr(),
                                onPressed: () {
                                  showDeleteConfirmation(element.value);
                                }),
                        ],
                      );
                    });
                  },
                  child: const Icon(Icons.more_vert_sharp)))
          : const Text('')),
    ];
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'suprdoc'.tr()} ${c.nom} ${c.chauffeurNom}';
  }

  @override
  Future<void> addToActivity(c) async {
    await ClientDatabase().ajoutActivity(25, c.id, docName: c.chauffeurNom);
  }
}
