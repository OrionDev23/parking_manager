/// Web deliberately has no local database. ParcOto Web is online-only.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  factory LocalDatabase() => instance;
  LocalDatabase._();

  dynamic get database => throw UnsupportedError(
    'SQLite is not available in ParcOto Web.',
  );

  Future<void> open() async {}
  bool isStartupMigrationComplete({
    required String companyId,
    required String migrationKey,
  }) => true;
  void markStartupMigrationComplete({
    required String companyId,
    required String migrationKey,
  }) {}
  Set<String> readRemoteSnapshotIds({
    required String companyId,
    required String entity,
  }) => <String>{};
  void replaceRemoteSnapshot({
    required String companyId,
    required String entity,
    required Set<String> entityIds,
  }) {}
  DateTime? readReconciliationTime({
    required String companyId,
    required String entity,
  }) => null;
  void saveReconciliationTime({
    required String companyId,
    required String entity,
    required DateTime reconciledAt,
  }) {}
  DateTime? readSyncCursor({
    required String companyId,
    required String entity,
  }) => null;
  void saveSyncCursor({
    required String companyId,
    required String entity,
    required DateTime cursor,
  }) {}
  List<Map<String, dynamic>> readLegacyCache({
    required String companyId,
    required String entity,
  }) => const [];
  void cacheLegacyRow({
    required String companyId,
    required String entity,
    required String entityId,
    required Map<String, dynamic> payload,
    bool overwrite = true,
  }) {}
  void deleteLegacyRow({
    required String companyId,
    required String entity,
    required String entityId,
  }) {}
  Future<void> close() async {}
}
