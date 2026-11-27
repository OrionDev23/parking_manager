import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../ui/design_system/parcoto_tokens.dart';

/// Compact module hero. The active screen title is owned by the application
/// topbar; this component only renders contextual hero content.
class ModuleDashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String eyebrow;
  final String heroTitle;
  final String heroDescription;
  final IconData icon;
  final Widget? trailing;

  const ModuleDashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.eyebrow,
    required this.heroTitle,
    required this.heroDescription,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ParcotoTokens.tabletBreakpoint;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            compact ? ParcotoTokens.space4 : ParcotoTokens.space6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.color.dark, theme.color, theme.color.light],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
            borderRadius: BorderRadius.circular(theme.cardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: ParcotoTokens.space2),
                    Text(
                      heroTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: ParcotoTokens.space2),
                    Text(
                      heroDescription,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .88),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: ParcotoTokens.space5),
                Icon(
                  icon,
                  size: 54,
                  color: Colors.white.withValues(alpha: .9),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
