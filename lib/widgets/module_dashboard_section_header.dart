import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../ui/design_system/parcoto_tokens.dart';

/// Consistent hierarchy for sections inside module dashboards.
class ModuleDashboardSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ModuleDashboardSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Padding(
      padding: const EdgeInsets.only(bottom: ParcotoTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ParcotoTokens.borderThin * 3,
            height: 36,
            decoration: BoxDecoration(
              color: theme.color,
              borderRadius: BorderRadius.circular(ParcotoTokens.radiusSmall),
            ),
          ),
          const SizedBox(width: ParcotoTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.writingStyle.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ParcotoTokens.space2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
