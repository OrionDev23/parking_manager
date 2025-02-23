import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/serializables/pieces/storage_variations.dart';
import 'package:provider/provider.dart';

import '../../../../serializables/pieces/part.dart';
import '../../../../serializables/pieces/variation.dart';
import '../../../../theme.dart';

class VariationStorageWidget extends StatefulWidget {
  final VehiclePart part;
  final StorageVariation variation;
  final bool mod;
  final double maxQte;
  final Function(double qte)? onQteChanged;
  final Function(DateTime date)? onDateChanged;
  final Function(Map<String,dynamic> options)? onOptionsChanged;

  const VariationStorageWidget({
    super.key,
    this.mod = true,
    required this.part,
    this.onQteChanged,
    required this.maxQte,
    this.onOptionsChanged,
    this.onDateChanged,
    required this.variation
  });

  @override
  VariationStorageWidgetState createState() => VariationStorageWidgetState();
}

class VariationStorageWidgetState extends State<VariationStorageWidget> {
  TextEditingController name = TextEditingController();

  Variation? selectedVariation;

  DateTime? selectedDate;

  double qte = 1;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                textAlign: TextAlign.start,
                widget.variation.id,
                style: placeStyle,
              ),
            )),
        Flexible(
            flex: 10,
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
          flex: 8,
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

                if(widget.onOptionsChanged!=null && selectedVariation!=null){
                  widget.onOptionsChanged!(selectedVariation!.optionValues!);
                }
              },

          )),
      smallSpace,
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
      Flexible(
        flex: 6,
        child: DatePicker(
            selected: selectedDate,
            onChanged: (d){
              setState(() {
                selectedDate=d;
              });
              if(widget.onDateChanged!=null){
                widget.onDateChanged!(d);
              }
            },

        )
      ),
      smallSpace,
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
      Flexible(
          flex: 3,
          child: Text(
          '${widget.part.price??0} DZD',style: placeStyle,
          ),
      ),
      smallSpace,
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
      Flexible(
        flex: 5,
        child: widget.part.unitType==0?NumberBox<int>(
          value: qte.toInt(),
          onChanged: (int? value) {
            setState(() {
              qte=value?.toDouble()??0;
            });
            if(widget.onQteChanged!=null){
              widget.onQteChanged!(value?.toDouble()??0);
            }
          },
          min: 0,
          max: widget.maxQte.toInt()+qte.toInt(),
        )
            :NumberBox<double>(
            value: qte,
            onChanged: (s){
          setState(() {
            qte=s??0;
          });
          if(widget.onQteChanged!=null){
            widget.onQteChanged!(s??0);

          }
        },
            min: 0,
          max: widget.maxQte+qte,

        ),
      )
    ];
  }


  String getVariationOptions(){
    String res="";

    widget.variation.optionValues?.forEach((s,v){
      res+="$v ";
    });

    return res;
  }
}
