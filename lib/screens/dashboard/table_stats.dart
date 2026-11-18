import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';

class TableStats extends StatelessWidget {
  final String? title;
  final Widget? icon;
  final Widget? content;
  final Widget? additionalWidget;
  final double? height;
  final double? width;
  final void Function()? onTap;

  const TableStats({
    super.key,
    this.title,
    this.icon,
    this.content,
    this.onTap,
    this.width,
    this.additionalWidget,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appTheme.surfaceColor,
        borderRadius: BorderRadius.circular(appTheme.cardRadius),
        border: Border.all(color: appTheme.borderColor),
        boxShadow: [appTheme.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: appTheme.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: IconTheme(
                  data: IconThemeData(color: appTheme.color, size: 18),
                  child: icon ?? const Icon(FluentIcons.chart),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (additionalWidget != null) additionalWidget!,
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: content == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: content!,
                  ),
          ),
          if (onTap != null) ...[
            Container(height: 1, color: appTheme.borderColor),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Button(
                onPressed: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('voirplus').tr(),
                    const SizedBox(width: 7),
                    const Icon(FluentIcons.arrow_right, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
