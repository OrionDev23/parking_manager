class CompanyContext {
  final String companyId;
  final String? teamId;
  final String? profileRowId;
  final String? siteId;

  const CompanyContext({
    required this.companyId,
    this.teamId,
    this.profileRowId,
    this.siteId,
  });
}
