import 'package:fluent_ui/fluent_ui.dart';
import 'package:parking_manager/theme.dart';
import 'package:parking_manager/utilities/color_manip.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ButtonContainer extends StatelessWidget {
  final IconData icon;
  final int? counter;
  final String text;
  final String textList;
  final String textNouveau;

  final bool showBothLN;

  final bool showCounter;
  final Color? color;
  final Function()? action;
  final Function()? actionList;
  final Function()? actionNouveau;
  const ButtonContainer(
      {super.key,
      required this.icon,
      this.action,
      this.actionList,
      this.actionNouveau,
      this.counter,
      required this.text,
      this.color,
      this.textList = "Liste",
      this.textNouveau = "Nouveau",
      this.showBothLN = true,
      this.showCounter = true});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    var textStyle = TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold,color: Colors.white);
    var textStyleButton = TextStyle(fontSize: 10.sp, color: Colors.white);
    return GestureDetector(
      onTap: action,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color ?? appTheme.color,
          borderRadius: BorderRadius.circular(5),
          boxShadow: kElevationToShadow[2],
        ),
        width: 18.w,
        height: 12.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 11.8.h,
              color: ColorManipulation.darken(color ?? appTheme.color),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showCounter == true ? '${counter ?? 0} $text' : text,
                  style: textStyle,
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: actionList,
                      child: Text(
                        textList,
                        style: textStyleButton,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if(showBothLN)
                    Container(
                      color: Colors.grey[100],
                      width: 0.05.w,
                      height: 30,
                    ),
                    if(showBothLN)
                      const SizedBox(width: 5),
                    if(showBothLN)
                      FilledButton(
                      onPressed: actionNouveau,
                      child: Text(
                        textNouveau,
                        style: textStyleButton,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
