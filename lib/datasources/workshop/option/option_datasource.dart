import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/datasources/workshop/option/option_webservice.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/screens/workshop/parts/options/option_form.dart';
import '../../../providers/client_database.dart';
import '../../../screens/workshop/parts/options/option_tabs.dart';
import '../../../utilities/adaptive_container.dart';
import '../../../widgets/on_tap_scale.dart';
import '../../parcoto_datasource.dart';
import '../../../serializables/pieces/option.dart';

class OptionDatasource extends ParcOtoDatasource<Option> {
  static OptionDatasource? instance;
  OptionDatasource(
      {required super.collectionID,
      required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC,
      super.sortAscending,
      super.sortColumn}) {
    repo = OptionWebservice(data, collectionID, 1);
    instance = this;
  }
  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter().ajoutActivity(53, c.id, docName: c.name);
  }

  @override
  String deleteConfirmationMessage(Option c) {
    return '${'supproption'.tr()} ${c.code} ${c.name}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Option> element) {
    return [
      DataCell(Text(element.value.code,style: rowTextStyle,)),
      DataCell(Text(element.value.name,style: rowTextStyle,)),
      DataCell(MasonryGridView.count(
        itemCount: element.value.values?.length??0,
        crossAxisCount: 6,
        shrinkWrap: true,
        primary: false,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        itemBuilder: (con,index){
          return AdaptiveTextContainer(
            text: element.value.values![index],
          );
        },
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
                                '${'modoption'.tr()} ${element.value.name}'),
                              semanticLabel:
                              '${'modoption'.tr()} ${element.value.name}',
                              icon: const Icon(f.FluentIcons.edit),
                              body: OptionForm(
                                option: element.value,
                              ),
                              onClosed: () {
                                OptionTabsState.tabs.remove(tab);

                                if (OptionTabsState
                                    .currentIndex.value >
                                    0) {
                                  OptionTabsState
                                      .currentIndex.value--;
                                }
                              },
                            );
                            final index =
                                OptionTabsState.tabs.length + 1;
                            OptionTabsState.tabs.add(tab);
                            OptionTabsState.currentIndex.value =
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
