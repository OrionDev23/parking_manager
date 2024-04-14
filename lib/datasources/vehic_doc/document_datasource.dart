import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/vehicle/documents/document_form.dart';
import 'package:parc_oto/screens/vehicle/documents/document_tabs.dart';

import '../../providers/client_database.dart';
import '../../screens/sidemenu/sidemenu.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../screens/vehicle/manager/vehicles_table.dart';
import '../../serializables/vehicle/document_vehicle.dart';
import '../../widgets/on_tap_scale.dart';
import 'document_webservice.dart';

class DocumentsDataSource extends ParcOtoDatasource<DocumentVehicle> {
  DocumentsDataSource(
      {required super.current, super.selectC, required super.collectionID}) {
    repo = DocumentWebService(data, collectionID, 1);
  }

  void showMyVehicule(String? matricule) {
    if (matricule != null) {
      PanesListState.index.value = PaneItemsAndFooters.originalItems
              .indexOf(PaneItemsAndFooters.vehicles) +
          1;
      VehicleTabsState.currentIndex.value = 0;
      VehicleTableState.filterNow = true;
      VehicleTableState.filterVehicule.value = matricule;
    }
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, DocumentVehicle> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');

    return [
      DataCell(SelectableText(
        element.value.nom,
        style: rowTextStyle,
      )),
      DataCell(SelectableText(element.value.vehiclemat ?? '', style: rowTextStyle),
          onTap: () {
        showMyVehicule(element.value.vehiclemat);
      }),
      DataCell(SelectableText(
          element.value.dateExpiration != null
              ? dateFormat2.format(element.value.dateExpiration!)
              : '',
          style: rowTextStyle)),
      DataCell(SelectableText(
          element.value.updatedAt != null
              ? dateFormat.format(element.value.updatedAt!)
              : '',
          style: rowTextStyle)),
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
                                  body: f.ScaffoldPage(
                                    content: DocumentForm(
                                      vd: element.value,
                                    ),
                                  ),
                                  onClosed: () {
                                    DocumentTabsState.tabs.remove(tab);

                                    if (DocumentTabsState.currentIndex.value >
                                        0) {
                                      DocumentTabsState.currentIndex.value--;
                                    }
                                  },
                                );
                                final index = DocumentTabsState.tabs.length + 1;
                                DocumentTabsState.tabs.add(tab);
                                DocumentTabsState.currentIndex.value =
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
                  child: f.Container(
                      decoration: BoxDecoration(
                        color: appTheme?.color.lightest,
                        boxShadow: kElevationToShadow[2],
                      ),
                      child: Icon(Icons.edit,color: appTheme!
                          .color.darkest,))),
            )
          : const Text('')),
    ];
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'suprdoc'.tr()} ${c.nom} ${c.vehiclemat}';
  }

  @override
  Future<void> addToActivity(c) async {
    await ClientDatabase()
        .ajoutActivity(9, c.id, docName: '${c.nom} ${c.vehiclemat}');
  }
}
