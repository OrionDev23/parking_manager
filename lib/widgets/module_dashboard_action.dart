import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';

/// Compact quick-action tile shared by all top-level module dashboards.
class ModuleDashboardAction extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onPressed;
  final double width;

  const ModuleDashboardAction({
    super.key,
    required this.label,
    required this.detail,
    required this.icon,
    required this.onPressed,
    this.width = 245,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      width: width,
      child: Button(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: theme.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[100], fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(FluentIcons.chevron_right, size: 12),
          ],
        ),
      ),
    );
  }
}
