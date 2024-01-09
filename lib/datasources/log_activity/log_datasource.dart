import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/log_activity/log_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/activity.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;

import '../../widgets/on_tap_scale.dart';

class LogDatasource extends ParcOtoDatasource<Activity> {
  LogDatasource(
      {required super.collectionID,
      required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC}) {
    repo = LogWebService(data, collectionID, 1);
  }

  @override
  Future<void> addToActivity(Activity c) async {

  }

  @override
  String deleteConfirmationMessage(Activity c) {
    return '${'delete'.tr()} LOG ${ClientDatabase().getActivityType(c.type)} ${c.docName}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Activity> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );

    return [
      DataCell(SelectableText(
        ClientDatabase().getActivityType(element.value.type).tr(),
        style: tstyle,
      )),
      DataCell(SelectableText(element.value.docName ?? '', style: tstyle),
          onTap: () {
        showMyDoc(element.value.type, element.value.docID);
      }),
      DataCell(SelectableText(
          element.value.updatedAt != null
              ? dateFormat.format(element.value.updatedAt!)
              : '',
          style: tstyle)),
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
                    child: const Icon(Icons.more_vert_sharp)))
            : const Text(''),
      )
    ];
  }

  void showMyDoc(int type, String docID) {}
}
