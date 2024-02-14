import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme.dart';
import '../utilities/color_manip.dart';
import 'on_tap_scale.dart';

class ButtonContainer extends StatefulWidget {
  final IconData icon;
  final int? counter;
  final String text;
  final String textList;
  final String textNouveau;

  final Future<int> Function()? getCount;

  final bool showBottom;
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
      this.showBottom = true,
      this.showCounter = true,
      this.getCount});

  @override
  State<ButtonContainer> createState() => _ButtonContainerState();
}

class _ButtonContainerState extends State<ButtonContainer> {
  bool loadingCount = true;

  int count = 0;

  @override
  void initState() {
    getCount();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    bool portrait=MediaQuery.of(context).orientation==Orientation.portrait;
    TextStyle textStyle = TextStyle(
        fontSize: portrait?16.sp:12.sp, color:
        appTheme.writingStyle.color,
    );
    TextStyle textStyleButton = TextStyle(fontSize: portrait?14.sp:10.sp,
        color: appTheme.writingStyle.color);

    return OnTapScaleAndFade(
      onTap: widget.action,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: appTheme.color.lightest,
            width: 0.5,
          ),
          boxShadow: kElevationToShadow[2],
        ),
        width: 220.px,
        height: 80.px,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 80.px,
              color: ColorManipulation.darken(widget.color ?? appTheme.color),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Icon(
                  widget.icon,
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
                  widget.showCounter == true
                      ? loadingCount
                          ? '- ${widget.text}'
                          : '$count ${widget.text}'
                      : widget.text,
                  style: textStyle,
                ),
                const SizedBox(
                  height: 10,
                ),
                if (widget.showBottom)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: widget.actionList,
                        child: Text(
                          widget.textList,
                          style: textStyleButton,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (widget.showBothLN)
                        Container(
                          color: Colors.grey[100],
                          width: 0.05.w,
                          height: 30,
                        ),
                      if (widget.showBothLN) const SizedBox(width: 5),
                      if (widget.showBothLN)
                        FilledButton(
                          onPressed: widget.actionNouveau,
                          child: Text(
                            widget.textNouveau,
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

  Future<void> getCount() async {
    if (widget.getCount == null) {
      loadingCount = false;
      count = 0;
    } else {
      loadingCount = true;
      if (mounted) {
        setState(() {});
      }

      count = await widget.getCount!();

      if (mounted) {
        setState(() {
          loadingCount = false;
        });
      }
    }
  }
}
