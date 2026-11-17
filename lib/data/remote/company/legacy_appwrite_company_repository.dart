import 'package:appwrite/appwrite.dart';

import '../../../domain/entities/company.dart';
import '../../../domain/repositories/company_repository.dart';
import '../../../providers/client_database.dart';
import '../../../serializables/entreprise.dart';

class LegacyAppwriteCompanyRepository implements CompanyRepository {
  const LegacyAppwriteCompanyRepository();

  @override
  Future<Company?> getCurrent() async {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database is not initialized.');
    }

    final companyId = DatabaseGetter.activeCompanyId;
    if (companyId == null) return null;

    try {
      final result = await database.listRows(
        databaseId: databaseId,
        tableId: entrepriseid,
        queries: [
          Query.equal('companyId', companyId),
          Query.limit(1),
        ],
      );
      if (result.rows.isEmpty) return null;
      final row = result.rows.first;
      return _fromLegacy(
        row.convertTo((data) => Entreprise.fromJson(data)),
      );
    } on AppwriteException {
      return null;
    }
  }

  @override
  Future<Company> update(Company company) async {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database is not initialized.');
    }

    final legacy = Entreprise(
      id: company.id,
      nom: company.name,
      adresse: company.address,
      telephone: company.phone,
      email: company.email,
      description: company.description,
      nif: company.nif,
      nis: company.nis,
      rc: company.rc,
      art: company.art,
      logo: company.logo,
      filiales: List<String>.from(company.subsidiaries),
      directions: List<String>.from(company.directions),
      departments: List<String>.from(company.departments),
    );

    final companyId = DatabaseGetter.activeCompanyId;
    if (companyId == null) {
      throw StateError('No active company context is selected.');
    }
    final data = legacy.toJson()..['companyId'] = companyId;
    final row = await database.updateRow(
      databaseId: databaseId,
      tableId: entrepriseid,
      rowId: company.id,
      data: data,
    );

    return _fromLegacy(row.convertTo((data) => Entreprise.fromJson(data)));
  }

  Company _fromLegacy(Entreprise company) {
    return Company(
      id: company.id,
      name: company.nom,
      address: company.adresse,
      phone: company.telephone,
      email: company.email,
      description: company.description,
      nif: company.nif,
      nis: company.nis,
      rc: company.rc,
      art: company.art,
      logo: company.logo,
      subsidiaries: List.unmodifiable(company.filiales ?? const []),
      directions: List.unmodifiable(company.directions ?? const []),
      departments: List.unmodifiable(company.departments ?? const []),
    );
  }
}
