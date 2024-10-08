import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/datasources/prestataire/prestataire_webservice.dart';

import '../../providers/client_database.dart';
import '../../screens/prestataire/prestataire_form.dart';
import '../../screens/prestataire/prestataire_tabs.dart';
import '../../serializables/client.dart';
import '../../widgets/on_tap_scale.dart';

class PrestataireDataSource extends ParcOtoDatasource<Client> {
  final bool archive;

  PrestataireDataSource(
      {required super.collectionID,
      this.archive = false,
      required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC}) {
    repo = PrestataireWebservice(data, collectionID, 1);
  }

  @override
  String deleteConfirmationMessage(Client c) {
    return '${'supprest'.tr()} ${c.nom} ';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Client> element) {
    return [
      DataCell(SelectableText(
        element.value.nom,
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
        element.value.telephone ?? '',
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
        element.value.email ?? '',
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
        element.value.nif ?? '',
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
        element.value.rc ?? '',
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
        dateFormat.format(element.value.updatedAt!),
        style: rowTextStyle,
      )),
      DataCell(
        DatabaseGetter().isAdmin() || DatabaseGetter().isManager()
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
                                        '${"mod".tr()} ${'prestataire'.tr().toLowerCase()} ${element.value.nom}'),
                                    semanticLabel:
                                        '${'mod'.tr()} ${element.value.nom} ',
                                    icon: const Icon(f.FluentIcons.edit),
                                    body: PrestataireForm(
                                      prest: element.value,
                                    ),
                                    onClosed: () {
                                      PrestataireTabsState.tabs.remove(tab);

                                      if (PrestataireTabsState
                                              .currentIndex.value >
                                          0) {
                                        PrestataireTabsState
                                            .currentIndex.value--;
                                      }
                                    },
                                  );
                                  final index =
                                      PrestataireTabsState.tabs.length + 1;
                                  PrestataireTabsState.tabs.add(tab);
                                  PrestataireTabsState.currentIndex.value =
                                      index - 1;
                                }),
                            if (DatabaseGetter().isAdmin())
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
            : const Text(''),
      ),
    ];
  }

  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter().ajoutActivity(15, c.id, docName: c.nom);
  }
}
