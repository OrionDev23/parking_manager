import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../ui/design_system/parcoto_tokens.dart';

/// Shared page title used by legacy module screens.
class PageTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const PageTitle({
    super.key,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < ParcotoTokens.mobileBreakpoint;

        final title = Text(
          text,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: appTheme.color,
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w700,
          ),
        ).tr();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) ...[
              title,
              if (trailing != null) ...[
                const SizedBox(height: ParcotoTokens.space3),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing!,
                ),
              ],
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: title),
                  if (trailing != null) ...[
                    const SizedBox(width: ParcotoTokens.space3),
                    trailing!,
                  ],
                ],
              ),
            const SizedBox(height: ParcotoTokens.space4),
            const Divider(),
          ],
        );
      },
    );
  }
}
