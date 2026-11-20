import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../ui/design_system/parcoto_tokens.dart';

/// Responsive section heading shared by the repair and reception forms.
class BigTitleForm extends StatelessWidget {
  const BigTitleForm({
    super.key,
    required this.bigTitle,
    this.littleTitle,
    this.trailing,
  });

  final String bigTitle;
  final String? littleTitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.color.dark,
        borderRadius: BorderRadius.circular(appTheme.controlRadius),
        border: Border.all(color: appTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ParcotoTokens.space4,
        vertical: ParcotoTokens.space3,
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ParcotoTokens.space3,
        runSpacing: ParcotoTokens.space2,
        children: [
          Text(
            bigTitle,
            style: headerStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ).tr(),
          if (littleTitle != null)
            Text(
              littleTitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontSize: 12,
              ),
            ).tr(),
          ?trailing,
        ],
      ),
    );
  }
}
