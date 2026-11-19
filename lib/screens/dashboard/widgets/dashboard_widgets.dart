import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../providers/client_database.dart';
import '../../../theme.dart';
import '../models/dashboard_models.dart';

class DashboardMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color tone;

  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: appTheme.surfaceColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: appTheme.borderColor),
        boxShadow: [appTheme.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tone, size: 21),
              ),
              const Spacer(),
              Icon(
                FluentIcons.more,
                size: 14,
                color: appTheme.mutedTextColor.withValues(alpha: .7),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appTheme.mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: appTheme.textColor,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tone,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}

/// Shared dashboard card. Its content is kept separate from the heading so
/// responsive layouts can reuse the same surface geometry.
class DashboardPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final double? height;
  final EdgeInsetsGeometry padding;

  const DashboardPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.height,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
        boxShadow: [theme.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: theme.color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 13),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class FleetActivityChart extends StatelessWidget {
  final List<DashboardActivityPoint> points;

  const FleetActivityChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final usable = points
        .where((point) =>
            point.interventions > 0 || point.mileageThousands > 0)
        .toList(growable: false);

    if (usable.isEmpty) {
      return _DashboardEmptyState(
        icon: FluentIcons.chart,
        message: 'Aucun relevé kilométrique ou ordre de réparation sur cette période.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: SfCartesianChart(
            margin: const EdgeInsets.fromLTRB(0, 5, 2, 0),
            plotAreaBorderWidth: 0,
            legend: const Legend(isVisible: false),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: theme.backGroundColor,
              textStyle: theme.writingStyle,
            ),
            primaryXAxis: DateTimeAxis(
              dateFormat: DateFormat('dd MMM'),
              intervalType: DateTimeIntervalType.days,
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: AxisLine(color: theme.borderColor),
              labelStyle: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 10,
              ),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: 'Interventions'),
              minimum: 0,
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              majorGridLines: MajorGridLines(
                color: theme.borderColor.withValues(alpha: .7),
                dashArray: const [3, 4],
              ),
              labelStyle: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 10,
              ),
            ),
            axes: <ChartAxis>[
              NumericAxis(
                name: 'mileageAxis',
                opposedPosition: true,
                minimum: 0,
                title: AxisTitle(text: 'Relevés (milliers km)'),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: TextStyle(
                  color: theme.mutedTextColor,
                  fontSize: 10,
                ),
                numberFormat: NumberFormat('##0.#'),
              ),
            ],
            series: <CartesianSeries<DashboardActivityPoint, DateTime>>[
              SplineSeries<DashboardActivityPoint, DateTime>(
                name: 'Interventions',
                dataSource: usable,
                xValueMapper: (point, _) => point.date,
                yValueMapper: (point, _) => point.interventions,
                color: const Color(0xFF279BFA),
                width: 2.5,
                markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
              ),
              SplineSeries<DashboardActivityPoint, DateTime>(
                name: 'Relevés kilométriques',
                dataSource: usable,
                xValueMapper: (point, _) => point.date,
                yValueMapper: (point, _) => point.mileageThousands,
                yAxisName: 'mileageAxis',
                color: const Color(0xFFB16CF2),
                width: 2.5,
                markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 18,
          runSpacing: 5,
          alignment: WrapAlignment.center,
          children: const [
            _ChartLegend(color: Color(0xFFB16CF2), label: 'Kilométrage relevé'),
            _ChartLegend(color: Color(0xFF279BFA), label: 'Interventions'),
          ],
        ),
      ],
    );
  }
}

class FleetStateDonut extends StatelessWidget {
  final int total;
  final List<DashboardStatusSegment> segments;

  const FleetStateDonut({
    super.key,
    required this.total,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final visible = segments.where((segment) => segment.value > 0).toList();

    if (total == 0 || visible.isEmpty) {
      return const _DashboardEmptyState(
        icon: FluentIcons.car,
        message: 'Aucun véhicule disponible pour établir cette répartition.',
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SfCircularChart(
                margin: EdgeInsets.zero,
                series: <DoughnutSeries<DashboardStatusSegment, String>>[
                  DoughnutSeries<DashboardStatusSegment, String>(
                    dataSource: visible,
                    xValueMapper: (segment, _) => segment.label,
                    yValueMapper: (segment, _) => segment.value,
                    pointColorMapper: (segment, _) => segment.color,
                    innerRadius: '72%',
                    radius: '92%',
                    cornerStyle: CornerStyle.bothCurve,
                    explode: false,
                    dataLabelSettings: const DataLabelSettings(isVisible: false),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toString(),
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Véhicules',
                    style: TextStyle(
                      color: theme.mutedTextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: visible.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final segment = visible[index];
              final percentage =
                  total == 0 ? 0.0 : segment.value * 100 / total;
              return Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: segment.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    segment.value.toString(),
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 43,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecentActivityTimeline extends StatelessWidget {
  final List<Activity> activities;

  const RecentActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _DashboardEmptyState(
        icon: FluentIcons.database_activity,
        message: 'Aucune activité récente enregistrée.',
      );
    }

    final theme = context.watch<AppTheme>();
    return ListView.separated(
      padding: const EdgeInsets.only(top: 2),
      itemCount: activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final date = activity.createdAt ?? activity.updatedAt;
        final label = DatabaseGetter().getActivityType(activity.type).tr();
        final detail = (activity.docName?.trim().isNotEmpty ?? false)
            ? activity.docName!
            : (activity.personName ?? activity.createdBy ?? 'Activité');
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: theme.color.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _activityIcon(activity.type),
                color: theme.color,
                size: 14,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.isEmpty ? 'Activité Parcoto' : label,
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
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.mutedTextColor,
                      fontSize: 10,
                    ),
                  ),
                  if (date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        DateFormat('dd MMM • HH:mm').format(date.toLocal()),
                        style: TextStyle(
                          color: theme.mutedTextColor.withValues(alpha: .8),
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _activityIcon(int type) {
    if (type <= 9) return FluentIcons.car;
    if (type <= 17) return FluentIcons.repair;
    if (type <= 25) return FluentIcons.people;
    return FluentIcons.document;
  }
}

class UpcomingInterventions extends StatelessWidget {
  final List<Planning> items;

  const UpcomingInterventions({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _DashboardEmptyState(
        icon: FluentIcons.event,
        message: 'Aucune réservation ou intervention planifiée à venir.',
      );
    }

    final theme = context.watch<AppTheme>();
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(
        style: DividerThemeData(
          decoration: BoxDecoration(color: theme.borderColor),
        ),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final date = item.startTime.toLocal();
        final now = DateTime.now();
        final today = date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        final dateLabel = today
            ? 'Aujourd’hui'
            : DateFormat('dd MMM', 'fr').format(date);
        final detail = [
          if (item.location?.trim().isNotEmpty ?? false) item.location!,
          if (item.notes?.trim().isNotEmpty ?? false) item.notes!,
        ].join(' • ');

        return Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 65),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: theme.color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(FluentIcons.car, color: theme.mutedTextColor, size: 16),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    detail.isEmpty
                        ? DateFormat('HH:mm').format(date)
                        : '${DateFormat('HH:mm').format(date)} • $detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.mutedTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class VehiclesWatchlist extends StatelessWidget {
  final List<DashboardAlert> alerts;

  const VehiclesWatchlist({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _DashboardEmptyState(
        icon: FluentIcons.shield,
        message: 'Aucun véhicule ne nécessite de suivi immédiat.',
      );
    }

    final theme = context.watch<AppTheme>();
    return ListView.separated(
      itemCount: alerts.length,
      separatorBuilder: (_, _) => Divider(
        style: DividerThemeData(
          decoration: BoxDecoration(color: theme.borderColor),
        ),
      ),
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final color = switch (alert.severity) {
          DashboardAlertSeverity.danger => const Color(0xFFE85D75),
          DashboardAlertSeverity.warning => const Color(0xFFE6A23C),
          DashboardAlertSeverity.info => const Color(0xFF279BFA),
        };
        return Row(
          children: [
            Icon(FluentIcons.car, color: theme.mutedTextColor, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    alert.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.mutedTextColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                alert.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DashboardQuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tone;
  final VoidCallback onPressed;

  const DashboardQuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.tone,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .17),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            FluentIcons.chevron_right,
            color: theme.mutedTextColor,
            size: 11,
          ),
        ],
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DashboardEmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.mutedTextColor.withValues(alpha: .6),
              size: 25,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: theme.mutedTextColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
