import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/core/business/fleet_dashboard_status.dart';

void main() {
  group('FleetDashboardStatusMapper.fromLegacyCode', () {
    test('normalizes equivalent legacy status ranges', () {
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(0),
        FleetDashboardStatus.available,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(5),
        FleetDashboardStatus.available,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(1),
        FleetDashboardStatus.broken,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(6),
        FleetDashboardStatus.broken,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(2),
        FleetDashboardStatus.workshop,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(7),
        FleetDashboardStatus.workshop,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(3),
        FleetDashboardStatus.onMission,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(8),
        FleetDashboardStatus.onMission,
      );
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(4),
        FleetDashboardStatus.reformed,
      );
    });

    test('treats a missing state as available, matching legacy behavior', () {
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(null),
        FleetDashboardStatus.available,
      );
    });

    test('keeps unsupported state values separate', () {
      expect(
        FleetDashboardStatusMapper.fromLegacyCode(99),
        FleetDashboardStatus.other,
      );
    });
  });

  group('FleetDashboardStatusMapper.fromMetricIndex', () {
    test('maps the five dashboard KPI indices', () {
      expect(
        List<int>.generate(5, (index) => index)
            .map(FleetDashboardStatusMapper.fromMetricIndex)
            .toList(),
        [
          FleetDashboardStatus.available,
          FleetDashboardStatus.broken,
          FleetDashboardStatus.workshop,
          FleetDashboardStatus.onMission,
          FleetDashboardStatus.reformed,
        ],
      );
    });

    test('rejects unsupported KPI indices', () {
      expect(
        () => FleetDashboardStatusMapper.fromMetricIndex(5),
        throwsArgumentError,
      );
    });
  });
}
