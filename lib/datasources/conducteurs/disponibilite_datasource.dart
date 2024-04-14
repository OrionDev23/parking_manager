import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/conducteur/disponibilite_chauffeur.dart';

import '../../widgets/on_tap_scale.dart';
import 'disponibilite_webservice.dart';

class DisponibiliteDataSource
    extends ParcOtoDatasource<DisponibiliteChauffeur> {
  DisponibiliteDataSource(
      {required super.collectionID,
      required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC}) {
    repo = DisponibiliteWebService(data, collectionID, 1);
  }

  @override
  String deleteConfirmationMessage(DisponibiliteChauffeur c) {
    return '${'supdisp'.tr()} ${c.chauffeurNom} ${ClientDatabase.getEtat(c.type)}';
  }

  @override
  List<DataCell> getCellsToShow(
      MapEntry<String, DisponibiliteChauffeur> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    return [
      DataCell(SelectableText(
        element.value.chauffeurNom,
        style: rowTextStyle,
        onTap: () {
          goToChauffeur(element.value.chauffeurNom);
        },
      )),
      DataCell(SelectableText(
        ClientDatabase.getEtat(element.value.type).tr(),
        style: rowTextStyle,
      )),
      DataCell(SelectableText(
        dateFormat.format(element.value.createdAt!),
        style: rowTextStyle,
      )),
      DataCell(
        ClientDatabase().isAdmin()
            ? f.FlyoutTarget(
                controller: element.value.controller,
                child: OnTapScaleAndFade(
                    onTap: () {
                      element.value.controller.showFlyout(builder: (context) {
                        return f.MenuFlyout(
                          items: [
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
                            .color.darkest,))
                )
        )
            : const Text(''),
      ),
    ];
  }

  void goToChauffeur(String chauf) {}

  @override
  Future<void> addToActivity(c) async {
    await ClientDatabase().ajoutActivity(22, c.id, docName: c.chauffeurNom);
  }
}
