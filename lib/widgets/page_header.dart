import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class PageTitle extends StatefulWidget {

  final String text;

  final Widget? trailing;

  const PageTitle({super.key, required this.text,this.trailing});

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 2.w,
            ),
            Text(
              widget.text,
              style: TextStyle(color: Colors.grey[100], fontSize: 16.sp),
            ).tr(),
            if(widget.trailing!=null)
              const Spacer(),
            if(widget.trailing!=null)
              widget.trailing!,
            if(widget.trailing!=null)
              SizedBox(
                width: 2.w,
              ),
          ],
        ),
        SizedBox(
          height: 2.h,
        ),
        const Divider(),
      ],
    );
  }
}
