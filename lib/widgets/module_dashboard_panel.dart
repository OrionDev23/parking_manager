import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';

/// Shared bordered surface for analytics and activity blocks on module dashboards.
class ModuleDashboardPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const ModuleDashboardPanel({
    super.key,
    required this.title,
    required this.child,
    this.height = 360,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.borderColor),
        boxShadow: [theme.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.writingStyle.color,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
