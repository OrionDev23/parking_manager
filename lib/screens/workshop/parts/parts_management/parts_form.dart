import 'package:barcode_widget/barcode_widget.dart';
import 'package:chip_list/chip_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons, Material;
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart' hide Trans;
import 'package:parc_oto/screens/workshop/inventory/fournisseurs/fournisseur_table.dart';
import 'package:parc_oto/utilities/form_validators.dart';
import '../../../../serializables/client.dart';
import '../../../../serializables/pieces/part.dart';
import '../../../../serializables/pieces/variation.dart';
import '../../../../widgets/empty_table_widget.dart';
import '../brands/brand_table.dart';
import '../categories/category_table.dart';
import '../../../../serializables/pieces/brand.dart';
import '../../../../serializables/pieces/category.dart';
import '../../../../widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../serializables/pieces/option.dart';
import '../../../../theme.dart';
import '../options/option_table.dart';
import 'variation_widget.dart';

class PartsForm extends StatefulWidget {
  const PartsForm({super.key});

  @override
  State<PartsForm> createState() => _PartsFormState();
}

class _PartsFormState extends State<PartsForm>
    with AutomaticKeepAliveClientMixin<PartsForm> {
  TextEditingController name = TextEditingController();
  TextEditingController description = TextEditingController();
  double prix = 0;
  TextEditingController sku = TextEditingController();
  TextEditingController barcode = TextEditingController();
  int quantity = 1;
  Category? selectedCategory;
  Client? selectedFournisseur;
  List<Option> selectedOptions = [];
  int selectedUnit = 0;
  Brand? selectedBrand;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    bool portrait = context.orientation == Orientation.portrait;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(10),
      children: [
        StaggeredGrid.count(
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          crossAxisCount: portrait ? 1 : 3,
          children: getWidgets(appTheme, portrait),
        ),
      ],
    );
  }

  List<int> selectedOptionsToDelete = [];
  List<Widget> getWidgets(AppTheme appTheme, bool portrait) {
    return [
      generalInformation(appTheme, portrait),
      fournisseurWidget(appTheme, portrait),
      pricingWidget(appTheme, portrait),
      appArtenanceWidget(appTheme, portrait),
      inventoryWidget(appTheme, portrait),
      variationsWidget(appTheme,portrait),
    ];
  }

  Widget generalInformation(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 2,
      child: Container(
        width: 400.px,
        height: 280.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'generalinformations',
            style: appTheme.titleStyle,
          ).tr(),
          smallSpace,
          Flexible(
            flex: 1,
            child: ZoneBox(
              label: 'name'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TextBox(
                  controller: name,
                  placeholder: 'nom'.tr(),
                  onChanged: (s) {
                    setState(() {});
                  },
                  style: appTheme.writingStyle,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  decoration: BoxDecoration(
                    color: appTheme.fillColor,
                  ),
                ),
              ),
            ),
          ),
          smallSpace,
          Flexible(
            flex: 2,
            child: ZoneBox(
              label: 'descr'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TextBox(
                  controller: description,
                  placeholder: 'descr'.tr(),
                  onChanged: (s) {
                    setState(() {});
                  },
                  style: appTheme.writingStyle,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: BoxDecoration(
                    color: appTheme.fillColor,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget fournisseurWidget(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 1,
      child: Container(
        width: 200.px,
        height: 150.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'fournisseur',
            style: appTheme.titleStyle,
          ).tr(),
          smallSpace,
          Flexible(
            flex: 1,
            child: ZoneBox(
              label: 'fournisseur'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: FilledButton(
                    child: Text(selectedFournisseur == null
                        ? 'nonind'.tr()
                        : selectedFournisseur!.nom),
                    onPressed: () async {
                      selectedFournisseur = await showDialog<Client>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return ContentDialog(
                              constraints:
                                  BoxConstraints.tight(Size(700.px, 550.px)),
                              title: const Text('fournselect').tr(),
                              style: ContentDialogThemeData(
                                  titleStyle: appTheme.writingStyle
                                      .copyWith(fontWeight: FontWeight.bold)),
                              content: const FournisseurTable(
                                selectD: true,
                              ),
                              actions: [
                                Button(
                                    child: const Text('fermer').tr(),
                                    onPressed: () {
                                      selectedFournisseur = null;
                                      setState(() {});
                                      Navigator.of(context).pop();
                                    })
                              ],
                            );
                          });
                      setState(() {});
                    }),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget pricingWidget(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 2,
      child: Container(
        width: 400.px,
        height: portrait ? 215.px : 132.5.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'tarification',
            style: appTheme.titleStyle,
          ).tr(),
          smallSpace,
          Flexible(
            child: MasonryGridView.count(
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                itemCount: 2,
                crossAxisCount: portrait ? 1 : 2,
                itemBuilder: (co, ind) {
                  if (ind == 0) {
                    return SizedBox(
                      height: 75.px,
                      child: ZoneBox(
                        label: 'unit'.tr(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: DropDownButton(
                            items: List.generate(units.length, (index) {
                              return MenuFlyoutItem(
                                text: Text(units[index]).tr(),
                                onPressed: () {
                                  setState(() {
                                    selectedUnit = index;
                                  });
                                },
                                selected: selectedUnit == index,
                              );
                            }),
                            leading: Text(
                              'tarificationpar',
                              style: placeStyle,
                            ).tr(),
                            title: Text(units[selectedUnit]).tr(),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox(
                      height: 75.px,
                      child: ZoneBox(
                        label:
                            'prix${units[selectedUnit]}'.tr().uppercaseFirst(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: NumberBox<double>(
                            value: prix,
                            placeholder: 'prix${units[selectedUnit]}'
                                .tr()
                                .uppercaseFirst(),
                            onChanged: (s) {
                              setState(() {});
                            },
                            min: 0,
                            style: appTheme.writingStyle,
                            placeholderStyle: placeStyle,
                            cursorColor: appTheme.color.darker,
                          ),
                        ),
                      ),
                    );
                  }
                }),
          ),
        ]),
      ),
    );
  }

  Widget appArtenanceWidget(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 1,
      child: Container(
        width: 200.px,
        height: 420.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'appartenance',
            style: appTheme.titleStyle,
          ).tr(),
          smallSpace,
          Flexible(
            flex: 1,
            child: ZoneBox(
              label: 'brand'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: FilledButton(
                    child: Text(selectedBrand == null
                        ? 'nonind'.tr()
                        : selectedBrand!.name),
                    onPressed: () async {
                      selectedBrand = await showDialog<Brand>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return ContentDialog(
                              constraints:
                                  BoxConstraints.tight(Size(700.px, 550.px)),
                              title: const Text('brand').tr(),
                              style: ContentDialogThemeData(
                                  titleStyle: appTheme.writingStyle
                                      .copyWith(fontWeight: FontWeight.bold)),
                              content: const BrandTable(
                                selectD: true,
                              ),
                              actions: [
                                Button(
                                    child: const Text('fermer').tr(),
                                    onPressed: () {
                                      selectedBrand = null;
                                      setState(() {});
                                      Navigator.of(context).pop();
                                    })
                              ],
                            );
                          });
                      setState(() {});
                    }),
              ),
            ),
          ),
          smallSpace,
          Flexible(
            flex: 1,
            child: ZoneBox(
              label: 'category'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: FilledButton(
                    child: Text(selectedCategory == null
                        ? 'nonind'.tr()
                        : selectedCategory!.name),
                    onPressed: () async {
                      selectedCategory = await showDialog<Category>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return ContentDialog(
                              constraints:
                                  BoxConstraints.tight(Size(700.px, 550.px)),
                              title: const Text('category').tr(),
                              style: ContentDialogThemeData(
                                  titleStyle: appTheme.writingStyle
                                      .copyWith(fontWeight: FontWeight.bold)),
                              content: const CategoryTable(
                                selectD: true,
                              ),
                              actions: [
                                Button(
                                    child: const Text('fermer').tr(),
                                    onPressed: () {
                                      selectedCategory = null;
                                      setState(() {});
                                      Navigator.of(context).pop();
                                    })
                              ],
                            );
                          });
                      setState(() {});
                    }),
              ),
            ),
          ),
          smallSpace,
          Flexible(
            flex: 3,
            child: ZoneBox(
              label: 'options'.tr(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Button(
                          onPressed: selectedOptionsToDelete.isEmpty
                              ? null
                              : () {
                                  for (int i = 0;
                                      i < selectedOptionsToDelete.length;
                                      i++) {
                                    selectedOptions.removeAt(i);
                                  }
                                  selectedOptionsToDelete.clear();
                                  setState(() {});
                                },
                          child: const Text('delete').tr(),
                        ),
                        smallSpace,
                        FilledButton(
                            child: const Text('addoption').tr(),
                            onPressed: () async {
                              Option? option;
                              option = await showDialog<Option>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return ContentDialog(
                                      constraints: BoxConstraints.tight(
                                          Size(700.px, 550.px)),
                                      title: const Text('addoption').tr(),
                                      style: ContentDialogThemeData(
                                          titleStyle: appTheme.writingStyle
                                              .copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      content: const OptionTable(
                                        selectD: true,
                                      ),
                                      actions: [
                                        Button(
                                            child: const Text('fermer').tr(),
                                            onPressed: () {
                                              option = null;
                                              setState(() {});
                                              Navigator.of(context).pop();
                                            })
                                      ],
                                    );
                                  });
                              if (option != null) {
                                if (!selectedOptions.contains(option)) {
                                  selectedOptions.add(option!);
                                  setState(() {});
                                }
                              }
                            }),
                      ],
                    ),
                    bigSpace,
                    Material(
                      color: appTheme.backGroundColor,
                      child: ChipList(
                        listOfChipNames: selectedOptions
                            .map((o) => '${o.name}'
                                ' (${o.code})')
                            .toList(),
                        supportsMultiSelect: true,
                        listOfChipIndicesCurrentlySelected:
                            selectedOptionsToDelete,
                        borderRadiiList: const [5],
                        extraOnToggle: (s) => setState(() {}),
                        inactiveBgColorList: [appTheme.color.darkest],
                        inactiveTextColorList: [appTheme.writingStyle.color!],
                        inactiveBorderColorList: [appTheme.backGroundColor],
                        padding: EdgeInsets.zero,
                        widgetSpacing: 1,
                        showCheckmark: true,
                        shouldWrap: true,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget inventoryWidget(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
      crossAxisCellCount: 2,
      child: Container(
        width: 400.px,
        height: portrait ? 355.px : 152.5.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'inventaire',
            style: appTheme.titleStyle,
          ).tr(),
          smallSpace,
          Flexible(
              child: MasonryGridView.count(
                  crossAxisCount: portrait ? 1 : 3,
                  itemCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  itemBuilder: (co, ind) {
                    if (ind == 0) {
                      return SizedBox(
                        height: 95.px,
                        child: ZoneBox(
                          label: 'SKU',
                          trailing: IconButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll<Color>(
                                  appTheme.writingStyle.color!),
                              backgroundColor: WidgetStatePropertyAll<Color>(
                                  appTheme.backGroundColor),
                              elevation:
                                  const WidgetStatePropertyAll<double>(10),
                            ),
                            icon:  Icon(Icons.auto_mode,color:appTheme
                                .color.lightest),
                            onPressed: () {},
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextBox(
                              controller: sku,
                              placeholder: 'SKU'.tr(),
                              onChanged: (s) {
                                setState(() {});
                              },
                              style: appTheme.writingStyle,
                              placeholderStyle: placeStyle,
                              cursorColor: appTheme.color.darker,
                              decoration: BoxDecoration(
                                color: appTheme.fillColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if(ind==1){
                      return SizedBox(
                        height: 95.px,
                        child: ZoneBox(
                          label: 'barcode'.tr(),
                          trailing: IconButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll<Color>(
                                  appTheme.writingStyle.color!),
                              backgroundColor: WidgetStatePropertyAll<Color>(
                                  appTheme.backGroundColor),
                              elevation:
                                  const WidgetStatePropertyAll<double>(10),
                            ),
                            icon: Icon(Icons.auto_mode,color:appTheme
                                .color.lightest),
                            onPressed: () {

                            },
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextBox(
                              controller: barcode,
                              placeholder: 'barcode'.tr(),
                              onChanged: (s) {
                                setState(() {});
                              },
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: appTheme.writingStyle,
                              placeholderStyle: placeStyle,
                              cursorColor: appTheme.color.darker,
                              decoration: BoxDecoration(
                                color: appTheme.fillColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    else{
                      return SizedBox(
                        height: 95.px,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5.0,0,0,0),
                              child: Text(sku.text),
                            ),
                            Flexible(
                              child: BarcodeWidget(
                                color: appTheme.writingStyle.color!,
                                style: placeStyle,
                                barcode: Barcode.upcA(),
                                data: barcode.text.isEmpty?'000000000000':upcFormat.format
                                  (int.tryParse(barcode.text+getLastDigitUPC
                                  (barcode.text).toString())??0)
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  })),
        ]),
      ),
    );
  }

  Widget variationsWidget(AppTheme appTheme,bool portrait){
    return StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
        width: 400.px,
        height: 475.px,
        padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    boxShadow: kElevationToShadow[2],
    color: appTheme.backGroundColor,
    ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'variations',
              style: appTheme.titleStyle,
            ).tr(),
            smallSpace,
            designationTable(appTheme),
          ],
        ),
        ));
  }


  List<VariationWidget> variations = List.empty(growable: true);

  void addDesignation() {
    variations.add(VariationWidget(
      key: UniqueKey(),
      variation: Variation(
        id:variations.isEmpty
            ? '1'
            : (int.parse(variations.last.variation.id) + 1).toString(),
        name: '',
        sku: '',
      ),
      onPriceChanged: () {
        setState(() {});
      },
    ));
    setState(() {});
  }

  Widget designationTable(AppTheme appTheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                    onPressed:
                    selectedDesignationsExist() ? deleteAllSelected : null,
                    child: const Text('delete').tr()),
                smallSpace,
                FilledButton(
                    onPressed: addDesignation, child: const Text('add').tr()),
              ],
            ),
          ),
          smallSpace,
          Container(
            decoration: BoxDecoration(
              color: appTheme.color.lightest,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            padding: const EdgeInsets.all(5),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [
                  TableCell(
                      child: const Text(
                        'N°',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'nom',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'options',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'sku',
                        textAlign: TextAlign.center,
                      ).tr()),
                ]),
              ],
            ),
          ),
          variations.isEmpty
              ? Container(
              padding: const EdgeInsets.all(10),
              width: 300.px,
              height: 320.px,
              child: const NoDataWidget())
              : Container(
            decoration: BoxDecoration(
              border: Border.all(color: appTheme.fillColor),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(5)),
            ),
            child: Column(children: getDesignationList(appTheme)),
          ),
        ],
      ),
    );
  }

  bool selectedDesignationsExist() {
    for (int i = 0; i < variations.length; i++) {
      if (variations[i].variation.selected) {
        return true;
      }
    }
    return false;
  }

  void deleteAllSelected() {
    List<VariationWidget> temp = List.from(variations);
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].variation.selected) {
        variations.remove(temp[i]);
      }
    }
    setState(() {});
  }

  List<Widget> getDesignationList(AppTheme appTheme) {
    return List.generate(variations.length, (index) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? appTheme.fillColor : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                    checked: variations[index].variation.selected,
                    onChanged: (s) {
                      setState(() {
                        variations[index].variation.selected = s ?? false;
                      });
                    }),
                smallSpace,
                Flexible(
                  child: SizedBox(
                    height: 35.px,
                    child: variations[index],
                  ),
                ),
              ],
            ),
            smallSpace,
          ],
        ),
      );
    });
  }

  @override
  bool get wantKeepAlive => true;
}