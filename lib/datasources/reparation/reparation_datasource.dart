import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import '../../screens/reparation/reparation/manager/reparation_tabs.dart';
import '../../screens/reparation/reparation/reparation_order_form/reparation_form.dart';
import '../parcoto_datasource.dart';
import 'reparation_webservice.dart';

import '../../pdf_generation/pdf_preview_custom.dart';
import '../../providers/client_database.dart';
import '../../serializables/reparation/reparation.dart';
import '../../widgets/on_tap_scale.dart';

class ReparationDataSource extends ParcOtoDatasource<Reparation> {
  final bool? archive;

  ReparationDataSource(
      {required super.collectionID,
      this.archive,
      required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC}) {
    repo = ReparationWebService(data, collectionID, 1);
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'supreparation'.tr()} ${c.numero}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Reparation> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');
    final numberFormat = NumberFormat('00000000', 'fr');
    final numberFormat2 =
        NumberFormat.currency(locale: 'fr', symbol: 'DA', decimalDigits: 2);
    return [
      DataCell(SelectableText(
        numberFormat.format(element.value.numero),
        style: rowTextStyle,
      ),
        onDoubleTap: (){
          showPdf(element.value);
        }
      ),
      DataCell(SelectableText(element.value.nchassi ?? '', style: rowTextStyle)),
      DataCell(SelectableText(element.value.vehiculemat ?? '', style: rowTextStyle)),
      DataCell(
          SelectableText(element.value.ficheReceptionNumber!=null? numberFormat.format(element.value.ficheReceptionNumber): '', style: rowTextStyle)),
      DataCell(
          SelectableText(element.value.prestatairenom ?? '', style: rowTextStyle)),
      DataCell(SelectableText(dateFormat2.format(element.value.date),
          style: rowTextStyle)),
      DataCell(SelectableText(
        numberFormat2.format(element.value.getPrixTTC()),
        style: rowTextStyle,
      )),
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
                                    '${"mod".tr()} ${'reparation'.tr().toLowerCase()} ${element.value.numero}'),
                                semanticLabel:
                                    '${'mod'.tr()} ${element.value.numero}',
                                icon: const Icon(f.FluentIcons.edit),
                                body: ReparationForm(
                                  reparation: element.value,
                                  key: UniqueKey(),
                                ),
                                onClosed: () {
                                  ReparationTabsState.tabs.remove(tab);

                                  if (ReparationTabsState.currentIndex.value >
                                      0) {
                                    ReparationTabsState.currentIndex.value--;
                                  }
                                },
                              );
                              final index = ReparationTabsState.tabs.length + 1;
                              ReparationTabsState.tabs.add(tab);
                              ReparationTabsState.currentIndex.value =
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

  void showPdf(Reparation reparation) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) {
          if(current.mounted){
            return f.showDialog(
                context: current,
                barrierDismissible: true,
                builder: (context) {
                  return PdfPreviewPO(reparation:reparation);
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
