import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/datasources/reparation/reparation_webservice.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/reparation_pdf.dart';
import 'package:parc_oto/screens/reparation/reparation_form.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../screens/reparation/reparation_tabs.dart';
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
    repo = ReparationWebService(data, collectionID, 7);
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
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );
    return [
      DataCell(SelectableText(
        numberFormat.format(element.value.numero),
        style: tstyle,
      )),
      DataCell(SelectableText(element.value.vehiculemat ?? '', style: tstyle)),
      DataCell(
          SelectableText(element.value.prestatairenom ?? '', style: tstyle)),
      DataCell(SelectableText(dateFormat2.format(element.value.date),
          style: tstyle)),
      DataCell(SelectableText(
        numberFormat2.format(element.value.getPrixTTC()),
        style: tstyle,
      )),
      DataCell(SelectableText(dateFormat.format(element.value.updatedAt!),
          style: tstyle)),
      if(selectC!=true)
        DataCell(

          f.FlyoutTarget(
        controller: element.value.controller,
        child: OnTapScaleAndFade(
            onTap: () {
              element.value.controller.showFlyout(builder: (context) {
                return f.MenuFlyout(
                  items: [
                    if(ClientDatabase().isAdmin() || ClientDatabase().isManager())
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

                              if (ReparationTabsState.currentIndex.value > 0) {
                                ReparationTabsState.currentIndex.value--;
                              }
                            },
                          );
                          final index = ReparationTabsState.tabs.length + 1;
                          ReparationTabsState.tabs.add(tab);
                          ReparationTabsState.currentIndex.value = index - 1;
                        }),
                    if (ClientDatabase().isAdmin())
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
            child: const Icon(Icons.more_vert_sharp)),
      )),
    ];
  }

  void showPdf(Reparation reparation) {
    Future.delayed(const Duration(milliseconds: 50)).then((value) =>
        f.showDialog(
        context: current,
        builder: (context) {
          return PdfPreview(
            pdfFileName: 'ordre${numberFormat.format(reparation.numero)}',
            initialPageFormat: PdfPageFormat.a4,
            canDebug: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            build: (PdfPageFormat format) {
              return ReparationPdf(reparation: reparation).getDocument();
            },
          );
        }));
  }

  @override
  Future<void> addToActivity(c) async {
    await ClientDatabase()
        .ajoutActivity(12, c.id, docName: c.numero.toString());
  }
}
