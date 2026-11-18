import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import 'parcoto_tokens.dart';

/// Standard content surface used by cards, panels and grouped form sections.
class ParcotoSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ParcotoSurfaceTone tone;
  final double? radius;
  final bool bordered;
  final bool elevated;
  final Clip clipBehavior;

  const ParcotoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ParcotoTokens.space5),
    this.tone = ParcotoSurfaceTone.elevated,
    this.radius,
    this.bordered = true,
    this.elevated = false,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final background = switch (tone) {
      ParcotoSurfaceTone.canvas => theme.backGroundColor,
      ParcotoSurfaceTone.elevated => theme.surfaceColor,
      ParcotoSurfaceTone.subtle => theme.fillColor,
    };

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          radius ?? ParcotoTokens.radiusLarge,
        ),
        border: bordered
            ? Border.all(
                color: theme.borderColor,
                width: ParcotoTokens.borderThin,
              )
            : null,
        boxShadow: elevated ? [theme.surfaceShadow] : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          radius ?? ParcotoTokens.radiusLarge,
        ),
        clipBehavior: clipBehavior,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Consistent title row for a section inside a page or surface.
class ParcotoSectionHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final Widget? leading;

  const ParcotoSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: ParcotoTokens.space3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.2,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  style: TextStyle(
                    color: theme.mutedTextColor,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: ParcotoTokens.space3),
          trailing!,
        ],
      ],
    );
  }
}
