import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import '../../../providers/parts_provider.dart';
import '../../../screens/workshop/parts/categories/category_form.dart';
import '../../../providers/client_database.dart';
import '../../../screens/workshop/parts/categories/category_tabs.dart';
import '../../../serializables/pieces/category.dart';
import '../../../widgets/on_tap_scale.dart';
import '../../parcoto_datasource.dart';
import 'category_webservice.dart';

class CategoryDatasource extends ParcOtoDatasource<Category> {
  static CategoryDatasource? instance;
  CategoryDatasource(
      {required super.collectionID,
        required super.current,
        super.appTheme,
        super.filters,
        super.searchKey,
        super.selectC,
        super.sortAscending,
        super.sortColumn}) {
    repo = CategoryWebservice(data, collectionID, 1);
    instance = this;
  }
  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter().ajoutActivity(56, c.id, docName: c.name);
  }

  @override
  String deleteConfirmationMessage(Category c) {
    return '${'supprcategory'.tr()} ${c.code} ${c.name}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Category> element) {
    return [
      DataCell(Text(element.value.code,style: rowTextStyle,)),
      DataCell(Text(element.value.name,style: rowTextStyle,)),
      DataCell(Text(element.value.codeParent==null?'':PartsProvider
          .categories.containsKey(element.value.codeParent)?PartsProvider
          .categories[element.value.codeParent]!.name:element.value
          .codeParent!,style:
      rowTextStyle,)),
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
                                  '${'modcat'.tr()} ${element.value.name}'),
                              semanticLabel:
                              '${'modcat'.tr()} ${element.value.name}',
                              icon: const Icon(f.FluentIcons.edit),
                              body: CategoryForm(
                                category: element.value,
                              ),
                              onClosed: () {
                                CategoryTabsState.tabs.remove(tab);

                                if (CategoryTabsState
                                    .currentIndex.value >
                                    0) {
                                  CategoryTabsState
                                      .currentIndex.value--;
                                }
                              },
                            );
                            final index =
                                CategoryTabsState.tabs.length + 1;
                            CategoryTabsState.tabs.add(tab);
                            CategoryTabsState.currentIndex.value =
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
