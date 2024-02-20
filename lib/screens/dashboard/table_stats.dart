import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';

class TableStats extends StatelessWidget {
  final String? title;
  final Widget? icon;
  final Widget? content;

  ///to add beside showMore button
  final Widget? additionalWidget;

  final double? height;
  final double? width;
  final void Function()? onTap;

  const TableStats(
      {super.key,
      this.title,
      this.icon,
      this.content,
      this.onTap,
      this.width,
      this.additionalWidget,
      this.height});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Container(
      height: height ?? double.infinity,
      width: width ?? double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          boxShadow: kElevationToShadow[2],
          borderRadius: BorderRadius.circular(5),
          color: appTheme.backGroundColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              makeTransactionsIcon(context),
              bigSpace,
              Text(
                title ?? '',
                style: TextStyle(fontSize: 18.px),
              ),
            ],
          ),
          smallSpace,
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: content ?? const SizedBox(),
            ),
          ),
          smallSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (additionalWidget != null) additionalWidget!,
              if (additionalWidget != null) smallSpace,
              FilledButton(
                  onPressed: onTap, child: const Text('voirplus').tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget makeTransactionsIcon(BuildContext context) {
    final width = 40.0.px;
    var appTheme = context.watch<AppTheme>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: width,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: appTheme.color.light,
              width: 3,
            ),
          ),
          child: icon ??
              Icon(
                FluentIcons.note_pinned,
                color: appTheme.color,
              ),
        ),
      ],
    );
  }
}
