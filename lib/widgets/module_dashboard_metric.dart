import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';

/// A compact business KPI card with explicit loading, failure and retry states.
class ModuleDashboardMetric extends StatefulWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Future<int> Function() loadValue;
  final double width;

  const ModuleDashboardMetric({
    super.key,
    required this.label,
    required this.detail,
    required this.icon,
    required this.loadValue,
    this.width = 225,
  });

  @override
  State<ModuleDashboardMetric> createState() => _ModuleDashboardMetricState();
}

class _ModuleDashboardMetricState extends State<ModuleDashboardMetric> {
  late Future<int> _value;

  @override
  void initState() {
    super.initState();
    _value = _load();
  }

  Future<int> _load() => Future<int>.sync(widget.loadValue);

  @override
  void didUpdateWidget(covariant ModuleDashboardMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadValue != widget.loadValue) {
      _value = _load();
    }
  }

  void _retry() {
    setState(() => _value = _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return SizedBox(
      width: widget.width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 94),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: theme.borderColor),
          boxShadow: [theme.surfaceShadow],
        ),
        child: FutureBuilder<int>(
          future: _value,
          builder: (context, snapshot) {
            final failed = snapshot.hasError;
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            final value = loading
                ? null
                : failed
                    ? null
                    : snapshot.data;

            return Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.color.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    color: theme.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: ProgressRing(),
                        )
                      else
                        Text(
                          value?.toString() ?? '—',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        failed ? 'Données indisponibles' : widget.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: failed
                              ? const Color(0xFFE6A23C)
                              : theme.mutedTextColor,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                if (failed)
                  Tooltip(
                    message: 'Réessayer',
                    child: IconButton(
                      icon: const Icon(FluentIcons.refresh, size: 13),
                      onPressed: _retry,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
