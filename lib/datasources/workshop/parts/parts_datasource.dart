import 'package:chip_list/chip_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import '../../../serializables/pieces/part.dart';
import '../../../providers/client_database.dart';
import '../../../screens/workshop/parts/parts_management/parts_form.dart';
import '../../../screens/workshop/parts/parts_management/parts_tabs.dart';
import '../../../widgets/on_tap_scale.dart';
import '../../parcoto_datasource.dart';
import 'parts_webservice.dart';

class PartsDatasource extends ParcOtoDatasource<VehiclePart> {
  static PartsDatasource? instance;
  PartsDatasource(
      {required super.collectionID,
        required super.current,
        super.appTheme,
        super.filters,
        super.searchKey,
        super.selectC,
        super.sortAscending,
        super.sortColumn}) {
    repo = PartsWebservice(data, collectionID, 1);
    instance = this;
  }
  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter().ajoutActivity(62, c.id, docName: c.name);
  }

  @override
  String deleteConfirmationMessage(VehiclePart c) {
    return '${'suprpart'.tr()} ${c.id} ${c.name}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, VehiclePart> element) {
    return [
      DataCell(Text(element.value.id,style: rowTextStyle,)),
      DataCell(Text(element.value.sku??'',style: rowTextStyle,)),
      DataCell(Text(element.value.barcode??'',style: rowTextStyle,)),
      DataCell(Text(element.value.name,style: rowTextStyle,)),
      DataCell(ChipList(
        chipListDisabled: true,
        listOfChipNames: element.value.variations?.map((e)=>e.name).toList()
            ??[],
        listOfChipIndicesCurrentlySelected: const [],
        style: rowTextStyle,
        borderRadiiList: const [5],
        inactiveBgColorList: [appTheme!.color.darkest],
        inactiveTextColorList: [appTheme!.writingStyle.color!],
        inactiveBorderColorList: [appTheme!.backGroundColor],
        padding: EdgeInsets.zero,
        widgetSpacing: 1,
        showCheckmark: false,
        shouldWrap: false,
        wrapAlignment: WrapAlignment.start,
        wrapCrossAlignment: WrapCrossAlignment.start,

      )),
      DataCell(SelectableText(dateFormat.format(element.value
          .updatedAt??DateTime(2024)),   style: rowTextStyle,),
      ),
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
                                  '${'modpart'.tr()} ${element.value.name}'),
                              semanticLabel:
                              '${'modoption'.tr()} ${element.value.name}',
                              icon: const Icon(f.FluentIcons.edit),
                              body: PartsForm(
                                part: element.value,
                              ),
                              onClosed: () {
                                PartTabsState.tabs.remove(tab);

                                if (PartTabsState
                                    .currentIndex.value >
                                    0) {
                                  PartTabsState
                                      .currentIndex.value--;
                                }
                              },
                            );
                            final index =
                                PartTabsState.tabs.length + 1;
                            PartTabsState.tabs.add(tab);
                            PartTabsState.currentIndex.value =
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
}
