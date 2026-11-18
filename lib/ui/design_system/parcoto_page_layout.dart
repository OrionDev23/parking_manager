import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import 'parcoto_tokens.dart';

/// Page composition primitive for the new Parcoto screen architecture.
///
/// Screens provide domain content; this widget owns page width, spacing,
/// heading hierarchy and responsive horizontal padding.
class ParcotoPageLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? actions;
  final List<Widget> children;
  final Widget? bottom;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const ParcotoPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    required this.children,
    this.bottom,
    this.maxWidth = ParcotoTokens.contentMaxWidth,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < ParcotoTokens.mobileBreakpoint
        ? ParcotoTokens.space4
        : width < ParcotoTokens.tabletBreakpoint
            ? ParcotoTokens.space5
            : ParcotoTokens.space8;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: ParcotoTokens.space3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: width < ParcotoTokens.mobileBreakpoint
                            ? 22
                            : 27,
                        fontWeight: FontWeight.w750,
                        letterSpacing: -.8,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: ParcotoTokens.space2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: theme.mutedTextColor,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: ParcotoTokens.space4),
                actions!,
              ],
            ],
          ),
          const SizedBox(height: ParcotoTokens.space6),
          ..._withSpacing(children),
          if (bottom != null) ...[
            const SizedBox(height: ParcotoTokens.space6),
            bottom!,
          ],
        ],
      ),
    );

    return ColoredBox(
      color: theme.backGroundColor,
      child: Padding(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: width < ParcotoTokens.mobileBreakpoint
                  ? ParcotoTokens.space4
                  : ParcotoTokens.space6,
            ),
        child: Align(
          alignment: Alignment.topCenter,
          child: scrollable
              ? SingleChildScrollView(child: content)
              : content,
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets) {
    final result = <Widget>[];
    for (var index = 0; index < widgets.length; index++) {
      if (index > 0) {
        result.add(const SizedBox(height: ParcotoTokens.space5));
      }
      result.add(widgets[index]);
    }
    return result;
  }
}
