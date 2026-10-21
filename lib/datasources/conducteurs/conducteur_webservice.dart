import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';
import 'package:parc_oto/main.dart' show driverServices;
import 'package:parc_oto/providers/client_database.dart';

import '../../domain/entities/driver.dart';
import '../../serializables/conducteur/conducteur.dart';

class ConducteurWebService extends ParcOtoWebService<Conducteur> {
  final bool archive;

  ConducteurWebService(super.data, super.collectionID, super.columnForSearch,
      {this.archive = false});

  @override
  Conducteur fromJsonFunction(Map<String, dynamic> json) {
    return Conducteur.fromJson(json);
  }

  Conducteur _toLegacyConducteur(Driver driver) {
    return Conducteur(
      id: driver.id,
      name: driver.lastName,
      prenom: driver.firstName,
      matricule: driver.registration,
      vehicules: driver.vehicleIds,
      filliale: driver.subsidiary,
      direction: driver.direction,
      departement: driver.department,
      profession: driver.profession,
      etat: driver.state,
      etatactuel: driver.currentStateId,
      createdBy: driver.createdBy,
      adresse: driver.address,
      email: driver.email,
      dateNaissance: driver.birthDate,
      service: driver.service,
      telephone: driver.phone,
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt,
    );
  }

  /// Transitional adapter: the legacy table still consumes Conducteur objects,
  /// while the repository owns the read path and local/remote data access.
  ///
  /// Load the matching result set before applying client-side sorting, age
  /// filters and pagination. Applying pagination before sorting/filtering would
  /// produce incorrect pages and totals.
  @override
  Future<ParcOtoWebServiceResponse<Conducteur>> getData(
    int startingAt,
    int count,
    int sortedBy,
    bool sortedAsc, {
    String? searchKey,
    Map<String, String>? filters,
  }) async {
    final drivers = await driverServices.repository.getDrivers(
      search: searchKey,
      limit: 5000,
      offset: 0,
      includeArchived: archive,
    );

    var conducteurs = drivers.map(_toLegacyConducteur).toList(growable: true);
    final activeFilters = filters ?? const <String, String>{};

    final minAge = int.tryParse(activeFilters['agemin'] ?? '');
    final maxAge = int.tryParse(
      activeFilters['agemax'] ?? activeFilters['ageMax'] ?? '',
    );

    if (minAge != null || maxAge != null) {
      final now = DateTime.now();
      conducteurs = conducteurs.where((conducteur) {
        final birthDate = conducteur.dateNaissance;
        if (birthDate == null) return false;

        var age = now.year - birthDate.year;
        final hadBirthday = now.month > birthDate.month ||
            (now.month == birthDate.month && now.day >= birthDate.day);
        if (!hadBirthday) age--;

        if (minAge != null && age < minAge) return false;
        if (maxAge != null && age > maxAge) return false;
        return true;
      }).toList(growable: true);
    }

    final allEntries = conducteurs
        .map((conducteur) => MapEntry(conducteur.id, conducteur))
        .toList(growable: true);

    final comparator = getComparisonFunction(sortedBy, sortedAsc);
    if (comparator != null) {
      allEntries.sort(comparator);
    }

    // Keep the complete sorted result in the legacy datasource cache. Its
    // getRows implementation uses this cache to produce the requested page.
    data
      ..clear()
      ..addAll(allEntries);

    final safeStart = startingAt.clamp(0, allEntries.length);
    final safeEnd = (safeStart + count).clamp(safeStart, allEntries.length);
    final page = allEntries.sublist(safeStart, safeEnd);

    return ParcOtoWebServiceResponse<Conducteur>(allEntries.length, page);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  int Function(
          MapEntry<String, Conducteur> p1, MapEntry<String, Conducteur> p2)?
      getComparisonFunction(int column, bool ascending) {
    final coef = ascending ? 1 : -1;
    int compareNullable<T extends Comparable<dynamic>>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    switch (column) {
      case 0:
        return (a, b) => coef * '${a.value.name} ${a.value.prenom}'
            .compareTo('${b.value.name} ${b.value.prenom}');
      case 1:
        return (a, b) => coef * compareNullable(a.value.email, b.value.email);
      case 2:
        return (a, b) =>
            coef * compareNullable(a.value.telephone, b.value.telephone);
      case 3:
        return (a, b) =>
            coef * compareNullable(a.value.adresse, b.value.adresse);
      case 4:
        return (a, b) =>
            coef * compareNullable(a.value.dateNaissance, b.value.dateNaissance);
      case 5:
        return (a, b) =>
            coef * compareNullable(a.value.updatedAt, b.value.updatedAt);
      case 6:
        return (a, b) => coef * compareNullable(a.value.etat, b.value.etat);
    }

    return null;
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count,
      int startingAt, int sortedBy, bool sortedAsc,
      {int? index}) {
    // Filtering is performed by getData after repository retrieval.
    return [
      if (archive) Query.equal('etat', 3),
      if (!archive) Query.notEqual('etat', 3),
    ];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    // Sorting is performed by getData after repository retrieval.
    return Query.orderDesc(r'$updatedAt');
  }
}
