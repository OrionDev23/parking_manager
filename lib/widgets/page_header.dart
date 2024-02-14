import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme.dart';

class PageTitle extends StatefulWidget {
  final String text;

  final Widget? trailing;

  const PageTitle({super.key, required this.text, this.trailing});

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> {
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Column(
      children: [
        Row(
          children: [
            bigSpace,
            Text(
              widget.text,
              style: TextStyle(color: appTheme.color,fontStyle:FontStyle.italic,
                  fontSize: 16
                  .sp),
            ).tr(),
            if (widget.trailing != null) const Spacer(),
            if (widget.trailing != null) widget.trailing!,
            if (widget.trailing != null)
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
