import 'package:chip_list/chip_list.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../datasources/parcoto_datasource.dart';
import '../../../../serializables/pieces/part.dart';
import '../../../../serializables/pieces/variation.dart';
import '../../../../theme.dart';

class VariationStorage extends StatefulWidget {
  final VehiclePart part;
  final bool mod;
  final DateTime? expirationDate;
  final bool selected;
  final int qte;

  final Function()? onQteChanged;

  const VariationStorage(
      {super.key,
        this.mod=true,
        this.selected=false,
        required this.part,
        this.onQteChanged,
        this.expirationDate, required this.qte,
        });

  @override
  VariationStorageState createState() => VariationStorageState();
}

class VariationStorageState extends State<VariationStorage> {
  TextEditingController name = TextEditingController();

  Variation? selectedVariation;

  DateTime? selectedDate;

  int qte=1;


  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(
                widget.part.id,
                style: placeStyle,
              ),
            )),
        bigSpace,
        ...designationsDefault(appTheme),
      ],
    );
  }

  List<Widget> designationsDefault(AppTheme appTheme) {
    return [
      VerticalDivider(
        color: placeStyle.color,
      ),
      Flexible(
        flex: 3,
        child: ComboBox(items: List.generate(widget.part.variations?.length??0, (index)=>
            ComboBoxItem(
              onTap:(){
                selectedVariation=widget.part.variations![index];
                setState(() {

                });
              },
              value: widget.part.variations![index],
              child: Text(widget.part.variations![index].name),
            )))
      ),
      smallSpace,
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
     ChipList(
          chipListDisabled: true,
          listOfChipNames: selectedVariation?.optionValues?.map((s,v)
          =>MapEntry(s, v.toString())).values.toList()
              ??[],
          listOfChipIndicesCurrentlySelected: const [],
          style: rowTextStyle,
          borderRadiiList: const [5],
          inactiveBgColorList: [appTheme.color.darkest],
          inactiveTextColorList: [appTheme.writingStyle.color!],
          inactiveBorderColorList: [appTheme.backGroundColor],
          padding: EdgeInsets.zero,
          widgetSpacing: 1,
          showCheckmark: false,
          shouldWrap: false,
          wrapAlignment: WrapAlignment.start,
          wrapCrossAlignment: WrapCrossAlignment.start,
      ),
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
    ];
  }

}