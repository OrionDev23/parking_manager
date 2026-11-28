import 'package:flutter/foundation.dart';

import '../../core/database/local_database.dart';
import '../../data/local/parking/local_parking_source.dart';
import '../../data/local/parking/sqlite_parking_source.dart';

/// Current tenant-scoped Parking runtime.
///
/// The Parking local store deliberately shares the same SQLite database as
/// vehicles and drivers. It does not enqueue sync work until the remote
/// Appwrite Parking handlers have been provisioned and deployed.
class ParkingServices {
  static final ValueNotifier<ParkingServices?> active =
      ValueNotifier<ParkingServices?>(null);

  final LocalDatabase localDatabase;
  final LocalParkingSource local;
  final String companyId;

  ParkingServices._({
    required this.localDatabase,
    required this.local,
    required this.companyId,
  });

  static void install({
    required LocalDatabase localDatabase,
    required String companyId,
  }) {
    if (companyId.trim().isEmpty) {
      throw ArgumentError.value(companyId, 'companyId');
    }
    active.value = ParkingServices._(
      localDatabase: localDatabase,
      local: SqliteParkingSource(
        localDatabase,
        companyId: companyId,
      ),
      companyId: companyId,
    );
  }

  static void clear() {
    active.value = null;
  }
}
