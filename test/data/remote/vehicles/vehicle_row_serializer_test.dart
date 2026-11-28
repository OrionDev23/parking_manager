import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/data/remote/vehicles/vehicle_row_serializer.dart';
import 'package:parc_oto/domain/entities/vehicle.dart';

void main() {
  group('VehicleRowSerializer', () {
    final now = DateTime.utc(2026, 11, 28);

    test('preserves a 36-character Appwrite user ID without writing the '
        'incompatible legacy user_creation column', () {
      const appwriteUserId = '12345678-1234-1234-1234-123456789012';
      expect(appwriteUserId, hasLength(36));

      final vehicle = Vehicle(
        id: 'vehicle-serializer-test',
        companyId: 'company-serializer-test',
        registration: '12345-123-23',
        foreignRegistration: false,
        createdBy: appwriteUserId,
        createdAt: now,
        updatedAt: now,
      );

      final row = VehicleRowSerializer.toRow(vehicle);
      final payload = jsonDecode(row['payload'] as String) as Map;

      expect(row.containsKey('user_creation'), isFalse);
      expect(payload['createdBy'], appwriteUserId);
      expect(row['companyId'], vehicle.companyId);
    });

    test('keeps the payload valid when no creator is available', () {
      final vehicle = Vehicle(
        id: 'vehicle-serializer-no-creator',
        companyId: 'company-serializer-test',
        registration: '54321-123-23',
        foreignRegistration: false,
        createdAt: now,
        updatedAt: now,
      );

      final row = VehicleRowSerializer.toRow(vehicle);
      final payload = jsonDecode(row['payload'] as String) as Map;

      expect(row.containsKey('user_creation'), isFalse);
      expect(payload['createdBy'], isNull);
    });
  });
}
