import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/conducteur/disponibilite_chauffeur.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );
    return [
      DataCell(SelectableText(
        element.value.chauffeurNom,
        style: tstyle,
        onTap: () {
          goToChauffeur(element.value.chauffeurNom);
        },
      )),
      DataCell(SelectableText(
        ClientDatabase.getEtat(element.value.type).tr(),
        style: tstyle,
      )),
      DataCell(SelectableText(
        dateFormat.format(element.value.createdAt!),
        style: tstyle,
      )),
      DataCell(
    ClientDatabase().isAdmin()
          ?f.FlyoutTarget(
        controller: element.value.controller,
        child:  OnTapScaleAndFade(
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
                child: const Icon(Icons.more_vert_sharp))

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
