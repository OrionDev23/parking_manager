import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../serializables/pieces/option.dart';
import '../../../../serializables/pieces/variation.dart';
import '../../../../theme.dart';

class VariationWidget extends StatefulWidget {
  final Variation variation;
  final bool mod;
  final List<Option>? options;

  final Function()? onPriceChanged;

  const VariationWidget(
      {super.key,
        this.mod=true,
        required this.variation,
        this.onPriceChanged,
        this.options});

  @override
  VariationWidgetState createState() => VariationWidgetState();
}

class VariationWidgetState extends State<VariationWidget> {
  TextEditingController name = TextEditingController();
  TextEditingController sku = TextEditingController();
  Map<String,dynamic> values={};

  @override
  void initState() {
    name.text = widget.variation.name;
    sku.text = widget.variation.sku;
    values=widget.variation.optionValues??{};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Row(
      children: [
        Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(
                widget.variation.id,
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
      Flexible(
        flex: 2,
        child: TextBox(
          controller: name,
          enabled: widget.mod,
          placeholderStyle: placeStyle,
          placeholder: 'name'.tr(),
          style: appTheme.writingStyle,
          cursorColor: appTheme.color.darker,
          maxLength: 60,
          decoration: BoxDecoration(
            color: appTheme.fillColor,
          ),
          onChanged: (s) {
            setState(() {
              widget.variation.name = s;
            });
          },
        ),
      ),
      smallSpace,
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: getOptions(appTheme),
      ),
      VerticalDivider(
        color: placeStyle.color,
      ),
      smallSpace,
      Flexible(
        flex: 2,
        child: TextBox(
          controller: sku,
          enabled: widget.mod,
          placeholderStyle: placeStyle,
          placeholder: 'SKU',
          style: appTheme.writingStyle,
          cursorColor: appTheme.color.darker,
          maxLength: 60,
          decoration: BoxDecoration(
            color: appTheme.fillColor,
          ),
          onChanged: (s) {
            setState(() {
              widget.variation.name = s;
            });
          },
        ),
      ),
    ];
  }

  List<Widget> getOptions(AppTheme appTheme){
    if(widget.options!=null && widget.options!.isNotEmpty){
      return List.generate(widget.options!.length, (index){

      });
    }
    else{
      return [Text('nooptonadded',style: placeStyle,).tr()];
    }

  }
}