import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class PageTitle extends StatelessWidget {

  final String text;

  const PageTitle({super.key, required this.text});

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
              text,
              style: TextStyle(color: Colors.grey[100], fontSize: 16.sp),
            ).tr(),
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
