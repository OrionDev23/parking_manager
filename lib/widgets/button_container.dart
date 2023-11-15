import 'package:fluent_ui/fluent_ui.dart';
import '../theme.dart';
import '../utilities/color_manip.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
    var textStyle = TextStyle(
        fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white);
    var textStyleButton = TextStyle(fontSize: 10.sp, color: Colors.white);
    return OnTapScaleAndFade(
      onTap: widget.action,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.color ?? appTheme.color,
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
                      ? loadingCount?
                      '- ${widget.text}'
                    :'$count ${widget.text}'
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
    }
    else {
      loadingCount = true;
      if (mounted) {
        setState(() {});
      }

      count = await widget.getCount!();

      if(mounted) {
        setState(() {
        loadingCount = false;
      });
      }
    }
  }
}
