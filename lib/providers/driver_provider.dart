import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../main.dart';
import '../serializables/conducteur/disponibilite_chauffeur.dart';
import '../serializables/conducteur/document_chauffeur.dart';
import '../serializables/conducteur/conducteur.dart';
import '../domain/entities/driver.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class DriverProvider extends ChangeNotifier {
  static void invalidateSessionCache() {
    _cacheGeneration++;
    _cacheCompanyId = null;
    conducteurs.clear();
    disponibiliteConducteurs.clear();
    documentConducteurs.clear();
    downloadedConducteurs = false;
    downloadingConducteurs = false;
    downloadedDocuments = false;
    downloadingDocuments = false;
    downloadedDisp = false;
    downloadingDisp = false;
  }


  static Map<String, Conducteur> conducteurs = {};
  static Map<String, DisponibiliteChauffeur> disponibiliteConducteurs = {};
  static Map<String, DocumentChauffeur> documentConducteurs = {};
  static bool downloadedConducteurs = false;
  static bool downloadingConducteurs = false;
  static bool downloadedDocuments = false;
  static bool downloadingDocuments = false;
  static bool downloadedDisp = false;
  static bool downloadingDisp = false;
  static int _cacheGeneration = 0;

  static bool _isCurrentCompany(String companyId, int generation) =>
      vehicleServices.companyId == companyId && _cacheGeneration == generation;

  static String? _cacheCompanyId;

  static void _ensureCompanyCache() {
    final companyId = vehicleServices.companyId;
    if (_cacheCompanyId == companyId) return;
    _cacheGeneration++;
    conducteurs.clear();
    disponibiliteConducteurs.clear();
    documentConducteurs.clear();
    downloadedConducteurs = false;
    downloadingConducteurs = false;
    downloadedDocuments = false;
    downloadingDocuments = false;
    downloadedDisp = false;
    downloadingDisp = false;
    _cacheCompanyId = companyId;
  }

  DriverProvider() {
    _ensureCompanyCache();
    if (!downloadedConducteurs && !downloadingConducteurs) {
      refreshConducteurs();
    }
    if (!downloadedDocuments && !downloadingDocuments) {
      refreshDocuments();
    }
  }
  Future<void> refreshConducteurs() async {
    if (downloadingConducteurs) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingConducteurs = true;
    try {
      final drivers = await driverServices.repository.getDrivers();
      if (!_isCurrentCompany(companyId, generation)) return;
      conducteurs..clear()..addEntries(drivers.map((driver) => MapEntry(driver.id, _toLegacyConducteur(driver))));
      downloadedConducteurs = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) { downloadedConducteurs = false; debugPrint('[ParcOto Drivers] refresh failed: $error'); }
    } finally {
      if (_isCurrentCompany(companyId, generation)) { downloadingConducteurs = false; notifyListeners(); }
    }
  }

  static Conducteur _toLegacyConducteur(Driver driver) {
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

  Future<void> refreshDocuments() async {
    if (downloadingDocuments) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingDocuments = true;
    documentConducteurs.clear();
    try {
      final value = await DatabaseGetter.database!.listRows(
        databaseId: databaseId, tableId: chaufDoc, queries: [Query.limit(5000)],
      );
      if (!_isCurrentCompany(companyId, generation)) return;
      final refreshed = <String, DocumentChauffeur>{};
      for (final row in value.rows) {
        refreshed[row.$id] = row.convertTo((data) => DocumentChauffeur.fromJson(data));
      }
      documentConducteurs..clear()..addAll(refreshed);
      downloadedDocuments = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedDocuments = false;
        debugPrint('[ParcOto Driver documents] refresh failed: $error');
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) {
        downloadingDocuments = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshDisp() async {
    if (downloadingDisp) return;
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    downloadingDisp = true;
    disponibiliteConducteurs.clear();
    try {
      final value = await DatabaseGetter.database!.listRows(
        databaseId: databaseId, tableId: chaufDispID, queries: [Query.limit(5000)],
      );
      if (!_isCurrentCompany(companyId, generation)) return;
      final refreshed = <String, DisponibiliteChauffeur>{};
      for (final row in value.rows) {
        refreshed[row.$id] = row.convertTo((data) => DisponibiliteChauffeur.fromJson(data));
      }
      disponibiliteConducteurs..clear()..addAll(refreshed);
      downloadedDisp = true;
    } catch (error) {
      if (_isCurrentCompany(companyId, generation)) {
        downloadedDisp = false;
        debugPrint('[ParcOto Driver availability] refresh failed: $error');
      }
    } finally {
      if (_isCurrentCompany(companyId, generation)) {
        downloadingDisp = false;
        notifyListeners();
      }
    }
  }

  Future<int> getDriversCount() async {
    if (!downloadedConducteurs && !downloadingConducteurs) {
      await refreshConducteurs();
    } else {
      while (downloadingConducteurs) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return conducteurs.length;
  }

  Future<int> getDriversDocsCount() async {
    if (!downloadedDocuments && !downloadingDocuments) {
      await refreshDocuments();
    } else {
      while (downloadingDocuments) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return documentConducteurs.length;
  }

  Future<int> getDriversStatesCount() async {
    if (!downloadedDisp && !downloadingDisp) {
      await refreshDisp();
    } else {
      while (downloadingDisp) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return disponibiliteConducteurs.length;
  }

  void addConducteur(Conducteur c) {
    conducteurs[c.id] = c;
    notifyListeners();
  }

  void removeConducteur(Conducteur c) {
    conducteurs.remove(c.id);
    notifyListeners();
  }

  static List<String> removedCondDocs = [];

  Future<List<DocumentChauffeur>> getConduDocumentsBeforeTime(
    DateTime expiration,
  ) async {
    List<DocumentChauffeur> result = [];
    removedCondDocs = prefs.getStringList('removedCondDocs') ?? [];
    while (downloadingDocuments) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (downloadedDocuments) {
      for (var element in documentConducteurs.values) {
        if (element.dateExpiration != null &&
            element.dateExpiration!.isBefore(expiration) &&
            !removedCondDocs.contains(element.id)) {
          result.add(element);
        }
      }
    } else {
      await DatabaseGetter.database!
          .listRows(
            databaseId: databaseId,
            tableId: chaufDoc,
            queries: [
              Query.lessThanEqual('date_expiration', dateToIntJson(expiration)),
              if (removedCondDocs.isNotEmpty)
                ...removedCondDocs.map((e) => Query.notEqual(r'$id', e)),
            ],
          )
          .then((value) {
            for (int i = 0; i < value.rows.length; i++) {
              result.add(
                value.rows[i].convertTo((p0) => DocumentChauffeur.fromJson(p0)),
              );
            }
          })
          .onError((AppwriteException error, stackTrace) {
            if (kDebugMode) {
              print(error.message);
              print(error.response);
            }
          });
    }

    return result;
  }

  static String getEtat(int? etat) {
    switch (etat) {
      case 0:
        return 'disponible';
      case 1:
        return 'mission';
      case 2:
        return 'absent';
      case 3:
        return 'quitteentre';
      default:
        return 'disponible';
    }
  }
}
