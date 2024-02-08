import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';

class DatabaseCounters {
  Future<int> countVehicles({int etat = -1}) async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehiculeid,
          queries: [
            if (etat != -1) Query.equal('etatactuel', etat),
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        if (kDebugMode) {
          print('total for etat $etat : ${value.total}');
        }
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }

  Future<int> countVehiclesWithCondition(List<String> queries) async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehiculeid,
          queries: [
            ...queries,
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }
    return result;
  }
  Future<int> countChauffeurWithCondition(List<String> queries) async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: chauffeurid,
          queries: [
            ...queries,
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }
    return result;
  }
  Future<int> countChauffeur({int etat = -1}) async {
    int result = 0;
    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: chauffeurid,
          queries: [
            if (etat != -1) Query.equal('etat', etat),
            if (etat == -1) Query.notEqual('etat', 3),
            Query.limit(1),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }
    return result;
  }

  Future<int> countVdocs() async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehicDoc,
          queries: [
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }

  Future<int> countCDocs() async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: chaufDoc,
          queries: [
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }

  Future<int> countReservation() async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: planningID,
          queries: [
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }

  Future<int> countLog() async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: activityId,
          queries: [
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }

  Future<int> countReparation() async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: reparationId,
          queries: [
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }

  Future<int> countPrestataire() async {
    int result = 0;

    bool cont = true;

    while (cont) {
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: prestataireId,
          queries: [
            Query.limit(1),
            Query.offset(result),
          ]).then((value) {
        result += value.total;
        if (value.total < 5000) {
          cont = false;
        }
      }).onError((AppwriteException error, stackTrace) {
        cont = false;
      });
    }

    return result;
  }
}
