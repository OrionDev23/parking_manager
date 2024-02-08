import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../screens/vehicle/documents/document_form.dart';
import '../../screens/vehicle/manager/vehicle_form.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../screens/vehicle/states/state_form.dart';
import '../../serializables/vehicle/vehicle.dart';
import '../../utilities/vehicle_util.dart';
import '../../widgets/on_tap_scale.dart';
import '../parcoto_datasource.dart';
import 'vehicle_webservice.dart';

class VehiculeDataSource extends ParcOtoDatasource<Vehicle> {
  VehiculeDataSource(
      {required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC,
      required super.collectionID}) {
    repo = VehiculesWebService(data, collectionID, 1);
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Vehicle> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );
    return [
      DataCell(SelectableText(
        element.value.matricule,
        style: tstyle,
      )),
      DataCell(Row(
        children: [
          Image.asset(
            element.value.marque == null ||
                    element.value.marque!.isEmpty ||
                    element.value.marque!.contains('null')
                ? 'assets/images/marques/default.webp'
                : 'assets/images/marques/${element.value.marque ?? 'default'}.webp',
            width: 3.5.h,
            height: 3.5.h,
          ),
          const SizedBox(
            width: 2,
          ),
          Expanded(
              child: Text(
            element.value.type ?? '',
            style: tstyle,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      )),
      DataCell(Text(element.value.anneeUtil.toString(), style: tstyle)),
      DataCell(Text(
              VehiclesUtilities.getEtatName(element.value.etatactuel ?? 0),
              style: tstyle)
          .tr()),
      DataCell(Text(
          VehiclesUtilities.getPerimetre(element.value.perimetre),
          style: tstyle)
          .tr()),
      DataCell(Text(
          VehiclesUtilities.getAppartenance(element.value.appartenance),
          style: tstyle)
          .tr()),
      DataCell(
          Text(dateFormat.format(element.value.updatedAt!), style: tstyle)),
      if (selectC != true)
        DataCell(
          ClientDatabase().isAdmin() || ClientDatabase().isManager()
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
                                          '${"mod".tr()} ${'vehicule'.tr().toLowerCase()} ${element.value.matricule}'),
                                      semanticLabel:
                                          '${'mod'.tr()} ${element.value.matricule}',
                                      icon: const Icon(f.FluentIcons.edit),
                                      body: VehicleForm(
                                        vehicle: element.value,
                                      ),
                                      onClosed: () {
                                        VehicleTabsState.tabs.remove(tab);

                                        if (VehicleTabsState
                                                .currentIndex.value >
                                            0) {
                                          VehicleTabsState.currentIndex.value--;
                                        }
                                      },
                                    );
                                    final index =
                                        VehicleTabsState.tabs.length + 1;
                                    VehicleTabsState.tabs.add(tab);
                                    VehicleTabsState.currentIndex.value =
                                        index - 1;
                                  }),
                              if (ClientDatabase().isAdmin())
                                f.MenuFlyoutItem(
                                    text: const Text('delete').tr(),
                                    onPressed: () {
                                      showDeleteConfirmation(element.value);
                                    }),
                              const f.MenuFlyoutSeparator(),
                              f.MenuFlyoutItem(
                                  text: const Text('nouvdocument').tr(),
                                  onPressed: () {
                                    Future.delayed(
                                            const Duration(milliseconds: 50))
                                        .then((value) => f.showDialog(
                                            context: current,
                                            barrierDismissible: true,
                                            builder: (context) {
                                              return f.ContentDialog(
                                                title: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text('nouvdocument')
                                                        .tr(),
                                                    f.Button(
                                                        child: const Icon(f
                                                            .FluentIcons
                                                            .cancel),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        }),
                                                  ],
                                                ),
                                                constraints:
                                                    BoxConstraints.loose(
                                                        Size(420.px, 450.px)),
                                                content: DocumentForm(
                                                  vehicle: element.value,
                                                ),
                                              );
                                            }));
                                  }),
                              f.MenuFlyoutSubItem(
                                text: const Text('chstates').tr(),
                                items: (BuildContext context) {
                                  return [
                                    f.MenuFlyoutItem(
                                        text: const Text('gstate').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          showStateForm(element.value, 0);
                                        }),
                                    f.MenuFlyoutItem(
                                        text: const Text('bstate').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();

                                          showStateForm(element.value, 1);
                                        }),
                                    f.MenuFlyoutItem(
                                        text: const Text('rstate').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();

                                          showStateForm(element.value, 2);
                                        }),
                                    f.MenuFlyoutItem(
                                        text: const Text('ostate').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();

                                          showStateForm(element.value, 3);
                                        }),
                                    f.MenuFlyoutItem(
                                        text: const Text('restate').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();

                                          showStateForm(element.value, 4);
                                        }),
                                  ];
                                },
                              ),
                            ],
                          );
                        });
                      },
                      child: const Icon(Icons.more_vert_sharp)),
                )
              : const Text(''),
        ),
    ];
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'supvehic'.tr()} ${c.matricule}';
  }

  @override
  Future<void> addToActivity(c) async {
    await ClientDatabase().ajoutActivity(2, c.id, docName: c.matricule);
  }

  void showStateForm(Vehicle v, int type) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) => f.showDialog(
            context: current,
            barrierDismissible: true,
            builder: (c) {
              return f.ContentDialog(
                title: const Text("nouvetat").tr(),
                constraints: BoxConstraints.loose(f.Size(800.px, 500.px)),
                content: StateForm(
                  vehicle: v,
                  type: type,
                  vehicleDatasource: this,
                ),
              );
            }));
  }
}
