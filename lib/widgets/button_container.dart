import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme.dart';
import 'on_tap_scale.dart';

class ButtonContainer extends StatefulWidget {
  final IconData icon;
  final int? counter;

  final int? maxCounter;
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
        this.maxCounter,
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
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: appTheme.color.lightest,
            width: 1,
          ),
          boxShadow: kElevationToShadow[4],
        ),
        width: 240.px,
        height: 80.px,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 80.px,
              color:widget.color ?? appTheme.color.dark,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Icon(
                  widget.icon,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
            ),
            smallSpace,
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if(widget.showCounter)
                    Text(
                      widget.showCounter == true
                          ? (widget.counter==null&&widget.getCount==null)  ||
                          loadingCount
                          ? '- ${widget.maxCounter!=null ?'/ ${widget
                          .maxCounter}':''}'
                          :widget.counter!=null?
                          '${widget.counter} ${widget.maxCounter!=null
                              ?'/ ${widget
                              .maxCounter}':''}'
                          :'$count ${widget.maxCounter!=null
                          ?'/ ${widget
                          .maxCounter}':''}'
                          : '- ${widget.maxCounter!=null ?'/ ${widget
                          .maxCounter}':''}',
                      style: textStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if(widget.showCounter)
                      smallSpace,
                    Text(
                      widget.text,
                      style: textStyle,
                    ),

                  ],
                ),
                bigSpace,
                if (widget.showBottom)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HyperlinkButton(
                        onPressed: widget.actionList,
                        child: Text(
                          widget.textList,
                          style: textStyleButton,
                        ),
                      ),
                      smallSpace,
                      if (widget.showBothLN)
                        Container(
                          color: Colors.grey[100],
                          width: 0.05.w,
                          height: 30,
                        ),
                      if (widget.showBothLN) smallSpace,
                      if (widget.showBothLN)
                        HyperlinkButton(
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
