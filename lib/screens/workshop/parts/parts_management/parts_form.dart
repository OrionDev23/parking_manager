import 'package:chip_list/chip_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

class PartsForm extends StatefulWidget {
  const PartsForm({super.key});

  @override
  State<PartsForm> createState() => _PartsFormState();
}

class _PartsFormState extends State<PartsForm>
    with AutomaticKeepAliveClientMixin<PartsForm> {
  TextEditingController name = TextEditingController();
  TextEditingController description = TextEditingController();
  Category? selectedCategory;
  List<Option> selectedOptions=[];
  Brand? selectedBrand;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(10),
      children: [
        MasonryGridView.count(
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          shrinkWrap: true,
          crossAxisCount: 2,
          primary: false,
          physics: const ClampingScrollPhysics(),
          itemCount: getWidgets(appTheme).length,
          itemBuilder: (BuildContext context, int index) {
            return getWidgets(appTheme)[index];
          },
        ),
      ],
    );
  }

  List<int> selectedOptionsToDelete=[];
  List<Widget> getWidgets(AppTheme appTheme) {
    return [
      Container(
        width: 400.px,
        height: 280.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(children: [
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
                  decoration: BoxDecoration(
                    color: appTheme.fillColor,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
      Container(
        width: 200.px,
        height: 350.px,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: kElevationToShadow[2],
          color: appTheme.backGroundColor,
        ),
        child: Column(children: [
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
                    onPressed: ()  async{
                      selectedBrand=await showDialog<Brand>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return ContentDialog(
                              constraints: BoxConstraints.tight(
                                  Size(700.px, 550.px)),
                              title: const Text('brand').tr(),
                              style: ContentDialogThemeData(
                                  titleStyle: appTheme.writingStyle
                                      .copyWith(
                                      fontWeight:
                                      FontWeight.bold)),
                              content: const BrandTable(
                                selectD: true,
                              ),
                              actions: [Button(child: const Text('fermer').tr(),
                                  onPressed: (){
                                    selectedBrand=null;
                                    setState(() {

                                    });
                                    Navigator.of(context).pop();
                                  })],
                            );
                          });
                      setState(() {

                      });
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
                    onPressed: () async{
                      selectedCategory=await showDialog<Category>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return ContentDialog(
                              constraints: BoxConstraints.tight(
                                  Size(700.px, 550.px)),
                              title: const Text('category').tr(),
                              style: ContentDialogThemeData(
                                  titleStyle: appTheme.writingStyle
                                      .copyWith(
                                      fontWeight:
                                      FontWeight.bold)),
                              content: const CategoryTable(
                                selectD: true,
                              ),
                              actions: [Button(child: const Text('fermer').tr(),
                                  onPressed: (){
                                    selectedCategory=null;
                                    setState(() {

                                    });
                                    Navigator.of(context).pop();
                                  })],
                            );
                          });
                      setState(() {

                      });
                    }),
              ),
            ),
          ),
          Flexible(
            flex: 2,
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
                          onPressed: selectedOptionsToDelete.isEmpty?null:(){
                            for(int i=0;i<selectedOptionsToDelete.length;i++){
                              selectedOptions.remove(selectedOptions[i]);
                            }
                            selectedOptionsToDelete.clear();
                            setState(() {

                            });
                          },
                          child: const Text('delete').tr(),
                        ),
                        smallSpace,
                        FilledButton(
                            child: const Text('addoption').tr(),
                            onPressed: () async{
                              Option? option;
                              option=await showDialog<Option>(
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
                              fontWeight:
                              FontWeight.bold)),
                              content: const OptionTable(
                              selectD: true,
                              ),
                              actions: [Button(child: const Text('fermer').tr(),
                              onPressed: (){
                                option=null;
                              setState(() {

                              });
                              Navigator.of(context).pop();
                              })],
                              );
                              });
                              if(option!=null){
                                if(!selectedOptions.contains(option)){
                                  selectedOptions.add(option!);
                                  setState(() {

                                  });
                                }
                              }
                            }),
                      ],
                    ),
                    bigSpace,
                    Material(
                      color: appTheme.backGroundColor,
                      child: ChipList(
                        listOfChipNames: selectedOptions.map((o)=>'${o.name}'
                            ' (${o.code})').toList(),
                        supportsMultiSelect: true,
                        listOfChipIndicesCurrentlySelected:selectedOptionsToDelete,
                        borderRadiiList: const [5],
                        extraOnToggle: (s)=>setState(() {

                        }),
                        inactiveBgColorList: [appTheme.color.darkest],
                        inactiveTextColorList: [appTheme.writingStyle.color!],
                        inactiveBorderColorList: [appTheme.backGroundColor],
                        padding: EdgeInsets.zero,
                        widgetSpacing: 1,
                        showCheckmark: true,
                        shouldWrap: false,

                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ]),
      )
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
