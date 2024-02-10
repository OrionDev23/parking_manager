import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/datasources/vehicle_states/vehicle_states_webservice.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../screens/sidemenu/pane_items.dart';
import '../../screens/sidemenu/sidemenu.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../screens/vehicle/manager/vehicles_table.dart';
import '../../screens/vehicle/states/state_form.dart';
import '../../serializables/vehicle/state.dart';
import '../../utilities/vehicle_util.dart';
import '../../widgets/on_tap_scale.dart';

class VStatesDatasource extends ParcOtoDatasource<Etat> {
  VStatesDatasource(
      {required super.collectionID,
      required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC}) {
    repo = VehicleStateWebservice(data, collectionID, 4);
  }

  @override
  Future<void> addToActivity(Etat c) async {
    await ClientDatabase().ajoutActivity(6, c.id, docName: c.vehicleMat);
  }

  @override
  String deleteConfirmationMessage(Etat c) {
    return '${'supretat'.tr()} ${c.vehicleMat}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Etat> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');

    return [
      DataCell(Text(element.value.vehicleMat, style: rowTextStyle), onTap: () {
        showMyVehicule(element.value.vehicleMat);
      }),
      DataCell(SelectableText(
        VehiclesUtilities.getEtatName(element.value.type).tr(),
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
          element.value.date != null
              ? dateFormat.format(element.value.date!)
              : '',
          style: rowTextStyle)),
      DataCell(SelectableText(element.value.remarque ?? '', style: rowTextStyle)),
      DataCell(SelectableText(
          element.value.ordreNum != null
              ? NumberFormat('000000000', 'fr_FR')
                  .format(element.value.ordreNum)
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
                                showStateForm(element.value);
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
                  child: const Icon(Icons.more_vert_sharp)),
            )
          : const Text('')),
    ];
  }

  void showMyVehicule(String? matricule) {
    if (matricule != null) {

      PanesListState.index.value = PaneItemsAndFooters.originalItems
              .indexOf(PaneItemsAndFooters.vehicles) +
          1;
      VehicleTabsState.currentIndex.value = 0;
      VehicleTableState.filterVehicule.value = '"$matricule"';

      VehicleTableState.filterNow = true;

    }
  }

  void showStateForm(Etat e) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) => f.showDialog(
            context: current,
            barrierDismissible: true,
            builder: (c) {
              return f.ContentDialog(
                title: const Text("nouvetat").tr(),
                constraints: BoxConstraints.loose(f.Size(800.px, 500.px)),
                content: StateForm(
                  etat: e,
                  datasource: this,
                ),
              );
            }));
  }
}
