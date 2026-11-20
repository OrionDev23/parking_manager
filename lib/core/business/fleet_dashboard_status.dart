/// Canonical fleet status used by dashboard charts and KPI counters.
///
/// Parcoto has historical records using two status ranges:
/// - 0–4: free, broken, garage, running, reformed
/// - 5–8: available, broken, repair, mission
///
/// Values with the same operational meaning are deliberately normalized.
enum FleetDashboardStatus {
  available,
  broken,
  workshop,
  onMission,
  reformed,
  other,
}

class FleetDashboardStatusMapper {
  const FleetDashboardStatusMapper._();

  static FleetDashboardStatus fromLegacyCode(int? rawStatus) {
    switch (rawStatus ?? 0) {
      case 0:
      case 5:
        return FleetDashboardStatus.available;
      case 1:
      case 6:
        return FleetDashboardStatus.broken;
      case 2:
      case 7:
        return FleetDashboardStatus.workshop;
      case 3:
      case 8:
        return FleetDashboardStatus.onMission;
      case 4:
        return FleetDashboardStatus.reformed;
      default:
        return FleetDashboardStatus.other;
    }
  }

  /// Resolves the stable 0–4 index exposed by the vehicle dashboard KPIs.
  static FleetDashboardStatus fromMetricIndex(int index) {
    switch (index) {
      case 0:
        return FleetDashboardStatus.available;
      case 1:
        return FleetDashboardStatus.broken;
      case 2:
        return FleetDashboardStatus.workshop;
      case 3:
        return FleetDashboardStatus.onMission;
      case 4:
        return FleetDashboardStatus.reformed;
      default:
        throw ArgumentError.value(
          index,
          'index',
          'Fleet dashboard status index must be between 0 and 4.',
        );
    }
  }
}
