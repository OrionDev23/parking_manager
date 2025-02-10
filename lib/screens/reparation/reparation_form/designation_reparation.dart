import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/serializables/reparation/designation.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

class DesignationReparation extends StatefulWidget {
  final Designation designation;

  const DesignationReparation({super.key, required this.designation});

  @override
  DesignationReparationState createState() => DesignationReparationState();
}

class DesignationReparationState extends State<DesignationReparation> {
  TextEditingController designation = TextEditingController();
  int qte = 1;
  TextEditingController tva = TextEditingController();
  TextEditingController prix = TextEditingController();

  @override
  void initState() {
    designation.text = widget.designation.designation;
    qte = widget.designation.qte;
    tva.text = widget.designation.tva.toString();
    prix.text = widget.designation.prix.toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Row(
      children: [
        bigSpace,
        Flexible(
          flex: 3,
          child: TextBox(
            controller: designation,
            placeholderStyle: placeStyle,
            placeholder: 'desi'.tr(),
            style: appTheme.writingStyle,
            cursorColor: appTheme.color.darker,
            maxLength: 60,
            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

            onChanged: (s) {
              setState(() {
                widget.designation.designation = s;
              });
            },
          ),
        ),
        smallSpace,
        VerticalDivider(
          color: placeStyle.color,
        ),
        smallSpace,
        Expanded(
          child: NumberBox<int>(
            value: qte,
            min: 1,
            onChanged: (s) => setState(() {
              qte = s ?? 1;
              widget.designation.qte = s ?? 1;
              setState(() {});
            }),
            max: 99,
            placeholderStyle: placeStyle,
            placeholder: 'qte'.tr(),
            style: appTheme.writingStyle,
            cursorColor: appTheme.color.darker,
          ),
        ),
        smallSpace,
        VerticalDivider(
          color: placeStyle.color,
        ),
        smallSpace,
        Expanded(
          child: TextBox(
            controller: tva,
            suffix: Text(
              '%',
              style: placeStyle,
            ),
            onChanged: (s) => setState(() {
              double value = double.tryParse(s) ?? 0;
              if (value < 0) {
                value = 0;
              } else if (value > 99) {
                value = 99;
              }

              widget.designation.tva = value;

              setState(() {});
            }),
            placeholderStyle: placeStyle,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
            ],
            placeholder: 'TVA'.tr(),
            style: appTheme.writingStyle,
            cursorColor: appTheme.color.darker,
            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

          ),
        ),
        smallSpace,
        VerticalDivider(
          color: placeStyle.color,
        ),
        smallSpace,
        Expanded(
          flex: 1,
          child: TextBox(
            controller: prix,
            placeholderStyle: placeStyle,
            suffix: Text(
              'DA',
              style: placeStyle,
            ),
            placeholder: 'prix'.tr(),
            style: appTheme.writingStyle,
            cursorColor: appTheme.color.darker,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
            ],
            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

            onChanged: (s) {
              setState(() {
                widget.designation.prix = double.tryParse(s) ?? 0;
              });
            },
          ),
        ),
      ],
    );
  }
}
