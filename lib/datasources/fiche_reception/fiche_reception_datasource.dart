import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/screens/reparation/fiche_reception/form/fiche_reception_form.dart';
import '../../screens/reparation/fiche_reception/manager/fiche_reception_tabs.dart';
import 'fiche_reception_webservice.dart';
import '../../serializables/reparation/fiche_reception.dart';
import '../parcoto_datasource.dart';

import '../../pdf_generation/pdf_preview_custom.dart';
import '../../providers/client_database.dart';
import '../../widgets/on_tap_scale.dart';

class FicheReceptionDatasource extends ParcOtoDatasource<FicheReception> {
  final bool? archive;

  FicheReceptionDatasource(
      {required super.collectionID,
        this.archive,
        required super.current,
        super.appTheme,
        super.filters,
        super.searchKey,
        super.selectC}) {
    repo = FicheReceptionWebService(data, collectionID, 1);
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'suprefichereception'.tr()} ${c.numero}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, FicheReception> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');
    final numberFormat = NumberFormat('00000000', 'fr');
    return [
      DataCell(SelectableText(
        numberFormat.format(element.value.numero),
        style: rowTextStyle,
      ),
          onDoubleTap: (){
            showPdf(element.value);
          }
      ),
      DataCell(SelectableText(
        element.value.nchassi??'',
        style: rowTextStyle,
      )),
      DataCell(SelectableText(element.value.vehiculemat ?? '', style: rowTextStyle)),
      DataCell(
          SelectableText(element.value.reparationNumero!=null?numberFormat.format(element.value.reparationNumero):'', style: rowTextStyle)),
      DataCell(SelectableText(dateFormat2.format(element.value.dateEntre),
          style: rowTextStyle)),
      DataCell(SelectableText(element.value.dateSortie!=null?dateFormat2.format(element.value.dateSortie!):'',
          style: rowTextStyle)),
      DataCell(SelectableText(dateFormat.format(element.value.updatedAt!),
          style: rowTextStyle)),
      if (selectC != true)
        DataCell(f.FlyoutTarget(
          controller: element.value.controller,
          child: OnTapScaleAndFade(
              onTap: () {
                element.value.controller.showFlyout(builder: (context) {
                  return f.MenuFlyout(
                    items: [
                      if (DatabaseGetter().isAdmin() ||
                          DatabaseGetter().isManager())
                        f.MenuFlyoutItem(
                            text: const Text('mod').tr(),
                            onPressed: () {
                              Navigator.of(current).pop();
                              late f.Tab tab;
                              tab = f.Tab(
                                key: UniqueKey(),
                                text: Text(
                                    '${"mod".tr()} ${'fichereception'.tr().toLowerCase()} ${element.value.numero}'),
                                semanticLabel:
                                '${'mod'.tr()} ${element.value.numero}',
                                icon: const Icon(f.FluentIcons.edit),
                                body: FicheReceptionForm(
                                  fiche: element.value,
                                  key: UniqueKey(),
                                ),
                                onClosed: () {
                                  FicheReceptionTabsState.tabs.remove(tab);

                                  if (FicheReceptionTabsState.currentIndex.value >
                                      0) {
                                    FicheReceptionTabsState.currentIndex.value--;
                                  }
                                },
                              );
                              final index = FicheReceptionTabsState.tabs.length + 1;
                              FicheReceptionTabsState.tabs.add(tab);
                              FicheReceptionTabsState.currentIndex.value =
                                  index - 1;
                            }),
                      if (DatabaseGetter().isAdmin())
                        f.MenuFlyoutItem(
                            text: const Text('delete').tr(),
                            onPressed: () {
                              showDeleteConfirmation(element.value);
                            }),
                      const f.MenuFlyoutSeparator(),
                      f.MenuFlyoutItem(
                          text: const Text('prevoir').tr(),
                          onPressed: () {
                            showPdf(element.value);
                          }),
                    ],
                  );
                });
              },
              child: f.Container(
                  decoration: BoxDecoration(
                    color: appTheme?.color.lightest,
                    boxShadow: kElevationToShadow[2],
                  ),
                  child: Icon(Icons.edit,color: appTheme!
                      .color.darkest,))),
        )),
    ];
  }

  void showPdf(FicheReception fiche) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) {
          if(current.mounted){
            return f.showDialog(
                context: current,
                barrierDismissible: true,
                builder: (context) {
                  return PdfPreviewPO(fiche:fiche);
                });
          }

        });
  }

  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter()
        .ajoutActivity(12, c.id, docName: c.numero.toString());
  }
}
