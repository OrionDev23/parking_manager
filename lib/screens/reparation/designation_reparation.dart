import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
class DesignationReparation extends StatefulWidget {
  const DesignationReparation({super.key});

  @override
  DesignationReparationState createState() => DesignationReparationState();
}

class DesignationReparationState extends State<DesignationReparation> {

  TextEditingController designation=TextEditingController();
  int qte=1;
  TextEditingController tva=TextEditingController();
  TextEditingController prix=TextEditingController();
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
              onChanged: (s)=>setState(() {
                tva.text=s;
              }),
              placeholderStyle: placeStyle,
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
              placeholder: 'prix'.tr(),
              style: appTheme.writingStyle,
              cursorColor: appTheme.color.darker,
              decoration: BoxDecoration(
                color: appTheme.fillColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
