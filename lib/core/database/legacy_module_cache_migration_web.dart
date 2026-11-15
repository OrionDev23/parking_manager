/// No SQLite-backed legacy cache is created on Web.
class LegacyModuleCacheMigration {
  LegacyModuleCacheMigration({required dynamic localDatabase, required this.companyId});
  final String companyId;
  Future<Map<String, int>> migrate() async => const {};
}
