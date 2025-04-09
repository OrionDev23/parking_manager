
import 'package:chip_list/chip_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import '../../parcoto_datasource.dart';
import 'storage_webservice.dart';
import '../../../screens/workshop/inventory/storage/storage_form.dart';

import '../../../providers/client_database.dart';
import '../../../screens/workshop/inventory/storage/storage_tabs.dart';
import '../../../serializables/pieces/storage.dart';
import '../../../widgets/on_tap_scale.dart';

class StorageDatesource extends ParcOtoDatasource<Storage> {
  StorageDatesource({required super.collectionID,
    required super.current,super.appTheme,
    super.filters,super.searchKey,super.selectC,
    super.sortAscending,super.sortColumn}){
    repo=StorageWebservice(data, collectionID, 1);
  }

  @override
  Future<void> addToActivity(Storage c) async{
    await DatabaseGetter().ajoutActivity(65, c.id, docName: c.pieceName);

  }

  @override
  String deleteConfirmationMessage(Storage c) {
    return '${'supstockage'.tr()} ${c.id} ${c.pieceName}';

  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Storage> element) {
    return [
      DataCell(Text(element.value.id,style: rowTextStyle,)),
      DataCell(Text(element.value.pieceName,style: rowTextStyle,)),
      DataCell(Text(element.value.fournisseurName??'',style: rowTextStyle,)),
      DataCell(ChipList(
        chipListDisabled: true,
        listOfChipNames: element.value.variations?.map((e)=>e.name).toList()??[],
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
      DataCell(Text(element.value.qte.toStringAsPrecision(2),style: rowTextStyle,)),

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
                                  '${'modstock'.tr()} ${element.value.pieceName}'),
                              semanticLabel:
                              '${'modstock'.tr()} ${element.value.pieceName}',
                              icon: const Icon(f.FluentIcons.edit),
                              body: StorageForm(
                                storage: element.value,
                              ),
                              onClosed: () {
                                StorageTabsState.tabs.remove(tab);

                                if (StorageTabsState
                                    .currentIndex.value >
                                    0) {
                                  StorageTabsState
                                      .currentIndex.value--;
                                }
                              },
                            );
                            final index =
                                StorageTabsState.tabs.length + 1;
                            StorageTabsState.tabs.add(tab);
                            StorageTabsState.currentIndex.value =
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