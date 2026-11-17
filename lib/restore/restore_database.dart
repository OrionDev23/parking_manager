import 'package:dart_appwrite/dart_appwrite.dart' hide Client;
import 'package:dart_appwrite/models.dart';
import 'package:parc_oto/providers/client_database.dart';

import '../serializables/activity.dart';
import '../serializables/conducteur/conducteur.dart';
import '../serializables/conducteur/disponibilite_chauffeur.dart';
import '../serializables/conducteur/document_chauffeur.dart';
import '../serializables/planning.dart';
import '../serializables/client.dart';
import '../serializables/reparation/reparation.dart';
import '../serializables/vehicle/document_vehicle.dart';
import '../serializables/vehicle/state.dart';
import '../serializables/vehicle/vehicle.dart';

class RestoreDatabase {
  final Map<String, Vehicle>? vehicles;
  final Map<String, DocumentVehicle>? vehiclesDocs;

  final Map<String, Etat>? vehiclesStates;

  final Map<String, Reparation>? repairs;
  final Map<String, Client>? providers;
  final Map<String, Conducteur>? drivers;
  final Map<String, DocumentChauffeur>? driversDocs;
  final Map<String, DisponibiliteChauffeur>? driversStates;
  final Map<String, Planning>? plannings;
  final Map<String, Activity>? logs;
  final TablesDB databases;

  RestoreDatabase({
    required this.databases,
    this.vehicles,
    this.vehiclesDocs,
    this.vehiclesStates,
    this.repairs,
    this.providers,
    this.drivers,
    this.driversDocs,
    this.driversStates,
    this.plannings,
    this.logs,
  });

  Future<void> deleteThenAddData() async {
    await _deleteAllCurrentData();
    await addNewData();
  }

  Future<void> _deleteAllCurrentData() async {
    await Future.wait([
      _deleteAllDocuments(vehiculeid),
      _deleteAllDocuments(vehicDoc),
      _deleteAllDocuments(etatId),
      _deleteAllDocuments(chauffeurid),
      _deleteAllDocuments(chaufDoc),
      _deleteAllDocuments(chaufDispID),
      _deleteAllDocuments(reparationId),
      _deleteAllDocuments(prestataireId),
      _deleteAllDocuments(activityId),
      _deleteAllDocuments(planningID),
    ]);
  }

  Future<void> _deleteAllDocuments(String collectionID) async {
    // Never restore by deleting a whole shared table. listDocuments applies
    // the active companyId filter before any deletion is attempted.
    final rows = await DatabaseGetter().listDocuments(collectionID);
    await Future.wait(
      rows.map((row) => _deleteDocument(row.$id, collectionID)),
    );
  }

  Future<void> _deleteDocument(String docID, String collectionID) async {
    await databases.deleteRow(
      databaseId: databaseId,
      tableId: collectionID,
      rowId: docID,
    );
  }

  Future<void> addNewData() async {
    await Future.wait([
      if (vehicles != null && vehicles!.isNotEmpty)
        _addAllDocuments(vehicles!, vehiculeid),
      if (vehiclesDocs != null && vehiclesDocs!.isNotEmpty)
        _addAllDocuments(vehiclesDocs!, vehicDoc),
      if (vehiclesStates != null && vehiclesStates!.isNotEmpty)
        _addAllDocuments(vehiclesStates!, etatId),
      if (drivers != null && drivers!.isNotEmpty)
        _addAllDocuments(drivers!, chauffeurid),
      if (driversDocs != null && driversDocs!.isNotEmpty)
        _addAllDocuments(driversDocs!, chaufDoc),
      if (driversStates != null && driversStates!.isNotEmpty)
        _addAllDocuments(driversStates!, chaufDispID),
      if (repairs != null && repairs!.isNotEmpty)
        _addAllDocuments(repairs!, reparationId),
      if (providers != null && providers!.isNotEmpty)
        _addAllDocuments(providers!, prestataireId),
      if (logs != null && logs!.isNotEmpty) _addAllDocuments(logs!, activityId),
      if (plannings != null && plannings!.isNotEmpty)
        _addAllDocuments(plannings!, planningID),
    ]);
  }

  Future<void> _addAllDocuments(
    Map<String, dynamic> data,
    String collectionID,
  ) async {
    List<Future<void>> toDo = [];
    data.forEach((key, value) {
      toDo.add(_addDocument(key, collectionID, value.toJson()));
    });

    await Future.wait(toDo);
  }

  Future<void> _addDocument(
    String docID,
    String collectionID,
    Map<String, dynamic> data,
  ) async {
    await DatabaseGetter().addDocument(
      collectionId: collectionID,
      documentId: docID,
      data: data,
    );
  }

  Future<void> addOrUpdateNewData() async {
    await Future.wait([
      if (vehicles != null && vehicles!.isNotEmpty)
        _addOrUpdateAllDocuments(vehicles!, vehiculeid),
      if (vehiclesDocs != null && vehiclesDocs!.isNotEmpty)
        _addOrUpdateAllDocuments(vehiclesDocs!, vehicDoc),
      if (vehiclesStates != null && vehiclesStates!.isNotEmpty)
        _addOrUpdateAllDocuments(vehiclesStates!, etatId),
      if (drivers != null && drivers!.isNotEmpty)
        _addOrUpdateAllDocuments(drivers!, chauffeurid),
      if (driversDocs != null && driversDocs!.isNotEmpty)
        _addOrUpdateAllDocuments(driversDocs!, chaufDoc),
      if (driversStates != null && driversStates!.isNotEmpty)
        _addOrUpdateAllDocuments(driversStates!, chaufDispID),
      if (repairs != null && repairs!.isNotEmpty)
        _addOrUpdateAllDocuments(repairs!, reparationId),
      if (providers != null && providers!.isNotEmpty)
        _addOrUpdateAllDocuments(providers!, prestataireId),
      if (logs != null && logs!.isNotEmpty)
        _addOrUpdateAllDocuments(logs!, activityId),
      if (plannings != null && plannings!.isNotEmpty)
        _addOrUpdateAllDocuments(plannings!, planningID),
    ]);
  }

  Future<void> _addOrUpdateAllDocuments(
    Map<String, dynamic> data,
    String collectionID,
  ) async {
    List<Future<void>> toDo = [];
    data.forEach((key, value) {
      toDo.add(_addOrUpdate(key, collectionID, value.toJson()));
    });

    await Future.wait(toDo);
  }

  Future<void> _addOrUpdate(
    String docID,
    String collectionID,
    Map<String, dynamic> data,
  ) async {
    try {
      await DatabaseGetter().addDocument(
        collectionId: collectionID,
        documentId: docID,
        data: data,
      );
    } on AppwriteException catch (error) {
      if (error.code != 409) rethrow;
      await DatabaseGetter().updateDocument(
        collectionId: collectionID,
        documentId: docID,
        data: data,
      );
    }
  }
}
