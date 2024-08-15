import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import '../../../screens/workshop/parts/brands/brand_form.dart';
import '../../../providers/client_database.dart';
import '../../../screens/workshop/parts/brands/brand_tabs.dart';
import '../../../serializables/pieces/brand.dart';
import '../../../widgets/on_tap_scale.dart';
import '../../parcoto_datasource.dart';
import 'brand_webservice.dart';

class BrandDatasource extends ParcOtoDatasource<Brand> {
  static BrandDatasource? instance;
  BrandDatasource(
      {required super.collectionID,
        required super.current,
        super.appTheme,
        super.filters,
        super.searchKey,
        super.selectC,
        super.sortAscending,
        super.sortColumn}) {
    repo = BrandWebservice(data, collectionID, 1);
    instance = this;
  }
  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter().ajoutActivity(59, c.id, docName: c.name);
  }

  @override
  String deleteConfirmationMessage(Brand c) {
    return '${'supprbrand'.tr()} ${c.code} ${c.name}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Brand> element) {
    return [
      DataCell(Text(element.value.code,style: rowTextStyle,)),
      DataCell(Text(element.value.name,style: rowTextStyle,)),
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
                                  '${'modbrand'.tr()} ${element.value.name}'),
                              semanticLabel:
                              '${'modcat'.tr()} ${element.value.name}',
                              icon: const Icon(f.FluentIcons.edit),
                              body: BrandForm(
                                brand: element.value,
                              ),
                              onClosed: () {
                                BrandTabsState.tabs.remove(tab);

                                if (BrandTabsState
                                    .currentIndex.value >
                                    0) {
                                  BrandTabsState
                                      .currentIndex.value--;
                                }
                              },
                            );
                            final index =
                                BrandTabsState.tabs.length + 1;
                            BrandTabsState.tabs.add(tab);
                            BrandTabsState.currentIndex.value =
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
