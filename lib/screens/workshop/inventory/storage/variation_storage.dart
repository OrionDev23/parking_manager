import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  const VariationStorage({
    super.key,
    this.mod = true,
    this.selected = false,
    required this.part,
    this.onQteChanged,
    this.expirationDate,
    required this.qte,
  });

  @override
  VariationStorageState createState() => VariationStorageState();
}

class VariationStorageState extends State<VariationStorage> {
  TextEditingController name = TextEditingController();

  Variation? selectedVariation;

  DateTime? selectedDate;

  int qte = 1;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

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
                '${widget.part.name} ${getVariationOptions()}',
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
          child: ComboBox(
              items: List.generate(
                  widget.part.variations?.length ?? 0,
                  (index) {
                    return ComboBoxItem(
                        onTap: () {
                          selectedVariation = widget.part.variations![index];
                          setState(() {});
                        },
                        value: widget.part.variations![index],
                        child: Text(widget.part.variations![index].name),
                      );
                  }),
              value: selectedVariation,
              onChanged: (s){
                setState(() {
                  selectedVariation=s;
                });
              },

          )),
      smallSpace,
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
    ];
  }


  String getVariationOptions(){
    String res="";

    selectedVariation?.optionValues?.forEach((s,v){
      res+="$v ";
    });

    return res;
  }
}
