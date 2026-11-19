import 'package:fluent_ui/fluent_ui.dart';

import '../../../serializables/activity.dart';
import '../../../serializables/planning.dart';

class DashboardStatusSegment {
  final String label;
  final int value;
  final Color color;

  const DashboardStatusSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DashboardActivityPoint {
  final DateTime date;
  final double mileageThousands;
  final int interventions;

  const DashboardActivityPoint({
    required this.date,
    required this.mileageThousands,
    required this.interventions,
  });
}

enum DashboardAlertSeverity { danger, warning, info }

class DashboardAlert {
  final String title;
  final String subtitle;
  final String tag;
  final DashboardAlertSeverity severity;
  final DateTime? dueDate;

  const DashboardAlert({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.severity,
    this.dueDate,
  });
}

class DashboardSnapshot {
  final int vehicleCount;
  final int driverCount;
  final int maintenanceCount;
  final int reservationsToday;
  final double monthlyRepairCosts;
  final bool costsVerified;
  final List<DashboardStatusSegment> fleetStatus;
  final List<DashboardActivityPoint> activity;
  final List<Planning> upcoming;
  final List<Activity> recentActivities;
  final List<DashboardAlert> alerts;

  const DashboardSnapshot({
    this.vehicleCount = 0,
    this.driverCount = 0,
    this.maintenanceCount = 0,
    this.reservationsToday = 0,
    this.monthlyRepairCosts = 0,
    this.costsVerified = false,
    this.fleetStatus = const [],
    this.activity = const [],
    this.upcoming = const [],
    this.recentActivities = const [],
    this.alerts = const [],
  });
}
