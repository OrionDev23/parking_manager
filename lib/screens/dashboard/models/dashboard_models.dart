import 'package:fluent_ui/fluent_ui.dart';

import '../../../serializables/activity.dart';
import '../../../serializables/planning.dart';
import '../../../serializables/reparation/reparation.dart';

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
  final IconData icon;

  const DashboardAlert({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.severity,
    this.dueDate,
    this.icon = FluentIcons.car,
  });
}

class DashboardDriverStatusSummary {
  final int available;
  final int onMission;
  final int absent;
  final int inactive;

  const DashboardDriverStatusSummary({
    this.available = 0,
    this.onMission = 0,
    this.absent = 0,
    this.inactive = 0,
  });

  int get total => available + onMission + absent + inactive;
  int get active => available + onMission + absent;
}

class DashboardRepairSummary {
  final int waiting;
  final int inProgress;
  final int completed;
  final double activeAmount;
  final List<Reparation> activeRepairs;

  const DashboardRepairSummary({
    this.waiting = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.activeAmount = 0,
    this.activeRepairs = const [],
  });

  int get total => waiting + inProgress + completed;
  int get activeCount => waiting + inProgress;
}

class DashboardStockAlert {
  final String title;
  final String subtitle;
  final String tag;
  final DashboardAlertSeverity severity;
  final DateTime dueDate;

  const DashboardStockAlert({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.severity,
    required this.dueDate,
  });
}

class DashboardInventorySummary {
  final int referenceCount;
  final int lotCount;
  final int expiredLots;
  final int expiringLots;
  final bool verified;
  final List<DashboardStockAlert> alerts;

  const DashboardInventorySummary({
    this.referenceCount = 0,
    this.lotCount = 0,
    this.expiredLots = 0,
    this.expiringLots = 0,
    this.verified = false,
    this.alerts = const [],
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
  final DashboardDriverStatusSummary driverStatus;
  final DashboardRepairSummary repairPipeline;
  final DashboardInventorySummary inventory;

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
    this.driverStatus = const DashboardDriverStatusSummary(),
    this.repairPipeline = const DashboardRepairSummary(),
    this.inventory = const DashboardInventorySummary(),
  });
}
