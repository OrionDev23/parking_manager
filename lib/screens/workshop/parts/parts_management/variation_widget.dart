import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../serializables/pieces/variation.dart';
import '../../../../theme.dart';

class VariationWidget extends StatefulWidget {
  final Variation variation;
  final Function()? onPriceChanged;

  const VariationWidget(
      {super.key,
        required this.variation,
        this.onPriceChanged});

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
        bigSpace,
        ...designationsDefault(appTheme),
      ],
    );
  }

  List<Widget> designationsDefault(AppTheme appTheme) {
    return [
      Flexible(
        flex: 8,
        child: TextBox(
          controller: name,
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


    ];
  }
}