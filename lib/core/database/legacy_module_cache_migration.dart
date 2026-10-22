import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../database/local_database.dart';
import '../../providers/client_database.dart' show DatabaseGetter, databaseId;

/// Backfills a durable SQLite cache for legacy Appwrite modules that have not
/// yet been migrated to dedicated repositories. This is a staging layer only:
/// legacy screens still need to be switched to read/write through repositories.
class LegacyModuleCacheMigration {
  final LocalDatabase localDatabase;
  final String companyId;

  LegacyModuleCacheMigration({
    required this.localDatabase,
    required this.companyId,
  });

  static const Map<String, String> tables = {
    'planning': 'planning',
    'repair': 'reparation',
    'reception_sheet': 'fichereception',
    'provider': 'prestataire',
    'activity': 'activity',
    'client': 'clients',
    'supplier': 'fournisseurs',
    'part_category': 'categories',
    'part_brand': 'partsbrands',
    'part_option': 'options',
    'part': 'parts',
  };

  Future<Map<String, int>> migrate() async {
    final database = DatabaseGetter.database;
    if (database == null) {
      debugPrint('[ParcOto Migration] legacy cache skipped: Appwrite database unavailable');
      return const {};
    }

    final counts = <String, int>{};
    for (final entry in tables.entries) {
      var offset = 0;
      var inserted = 0;
      try {
        while (true) {
          final result = await database.listRows(
            databaseId: databaseId,
            tableId: entry.value,
            queries: [
              Query.orderAsc(r'$id'),
              Query.limit(100),
              Query.offset(offset),
            ],
          );
          final rows = result.rows;
          for (final row in rows) {
            final data = Map<String, dynamic>.from(row.data);
            final rawCompany = data['companyId']?.toString();
            // Explicitly tenant-scoped rows must never leak into another
            // company's cache. Legacy unscoped tables are retained as the
            // current installation's historical data.
            if (rawCompany != null &&
                rawCompany.isNotEmpty &&
                rawCompany != companyId) {
              continue;
            }
            final payload = jsonEncode({
              ...data,
              r'$id': row.$id,
              r'$createdAt': row.$createdAt,
              r'$updatedAt': row.$updatedAt,
            });
            final existing = localDatabase.database.select(
              'SELECT 1 FROM legacy_module_cache WHERE company_id = ? AND entity = ? AND entity_id = ? LIMIT 1',
              [companyId, entry.key, row.$id],
            );
            if (existing.isNotEmpty) continue;
            localDatabase.database.execute(
              '''INSERT OR IGNORE INTO legacy_module_cache
                (company_id, entity, entity_id, payload, cached_at)
                VALUES (?, ?, ?, ?, ?)''',
              [companyId, entry.key, row.$id, payload, DateTime.now().toUtc().toIso8601String()],
            );
            inserted++;
          }
          offset += rows.length;
          if (rows.length < 100) break;
        }
        counts[entry.key] = inserted;
        debugPrint('[ParcOto Migration] ${entry.key} cached rows inserted: $inserted');
      } catch (error, stackTrace) {
        debugPrint('[ParcOto Migration] ${entry.key} cache failed: $error\n$stackTrace');
        counts[entry.key] = -1;
      }
    }
    return counts;
  }
}
