import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme.dart';

class BigTitleForm extends StatelessWidget {
  const BigTitleForm({
    super.key,
    required this.bigTitle,
    this.littleTitle,
  });

  final String bigTitle;
  final String? littleTitle;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Container(
      height: 7.h,
      width: 80.w,
      decoration: BoxDecoration(
        color: appTheme.color.lightest,
        border: Border.all(),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            bigTitle,
            textAlign: TextAlign.start,
            style: headerStyle,
          ).tr(),
          smallSpace,
          if (littleTitle != null)
            Text(
              littleTitle!,
            ).tr(),
        ],
      ),
    );
  }
}
