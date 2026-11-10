import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';

/// Shared visual header for every ParcOto top-level module dashboard.
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
        final compact = constraints.maxWidth < 760;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.writingStyle.color,
                          fontSize: compact ? 25 : 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.writingStyle.color?.withValues(alpha: .62),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 18 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.color.dark, theme.color, theme.color.light],
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                ),
                borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 9),
                        Text(
                          heroTitle,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 18 : 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                    const SizedBox(width: 20),
                    Icon(
                      icon,
                      size: 54,
                      color: Colors.white.withValues(alpha: .9),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
