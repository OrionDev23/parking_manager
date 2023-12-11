import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/serializables/designation.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
class DesignationReparation extends StatefulWidget {
  final Designation designation;
  const DesignationReparation({super.key, required this.designation});

  @override
  DesignationReparationState createState() => DesignationReparationState();
}

class DesignationReparationState extends State<DesignationReparation> {

  TextEditingController designation=TextEditingController();
  int qte=1;
  TextEditingController tva=TextEditingController();
  TextEditingController prix=TextEditingController();

  @override
  void initState() {
    designation.text=widget.designation.designation;
    qte=widget.designation.qte;
    tva.text=widget.designation.tva.toString();
    prix.text=widget.designation.prix.toString();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return SizedBox(
      height: 40.px,
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: TextBox(
              controller: designation,
              placeholderStyle: placeStyle,
              placeholder: 'desi'.tr(),
              style: appTheme.writingStyle,
              cursorColor: appTheme.color.darker,
              decoration: BoxDecoration(
                color: appTheme.fillColor,
              ),
              onChanged: (s){
                setState(() {
                  widget.designation.designation=s;
                });
              },
            ),
          ),
          smallSpace,
          Flexible(
            flex: 1,
            child: NumberBox<int>(
              value: qte,
              min: 1,
              onChanged: (s)=>setState(() {
                qte=s??1;
                widget.designation.qte=s??1;
              }),
              placeholderStyle: placeStyle,
              placeholder: 'qte'.tr(),
              style: appTheme.writingStyle,
              cursorColor: appTheme.color.darker,
            ),
          ),
          smallSpace,
          Flexible(
            flex: 1,
            child: TextBox(
              controller: tva,
              suffix: Text('%',style: placeStyle,),
              onChanged: (s)=>setState(() {
                tva.text=s;
                widget.designation.tva=double.tryParse(s)??0;
              }),
              placeholderStyle: placeStyle,
              inputFormatters: [FilteringTextInputFormatter.allow(
                  RegExp(r'^(\d+)?\.?\d{0,2}')
              )],
              placeholder: 'TVA'.tr(),
              style: appTheme.writingStyle,
              cursorColor: appTheme.color.darker,
              decoration: BoxDecoration(
                color: appTheme.fillColor,
              ),
            ),
          ),
          smallSpace,
          Flexible(
            flex: 1,
            child: TextBox(
              controller: prix,
              placeholderStyle: placeStyle,
              suffix: Text('DA',style: placeStyle,),

              placeholder: 'prix'.tr(),
              style: appTheme.writingStyle,
              cursorColor: appTheme.color.darker,
              inputFormatters: [FilteringTextInputFormatter.allow(
                  RegExp(r'^(\d+)?\.?\d{0,2}')
              )],
              decoration: BoxDecoration(
                color: appTheme.fillColor,
              ),
              onChanged: (s){
                setState(() {
                  widget.designation.prix=double.tryParse(s)??0;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
