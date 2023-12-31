import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/activity.dart';
import 'package:parc_oto/serializables/vehicle/vehicle.dart';

import '../screens/entreprise.dart';
import '../serializables/entreprise.dart';
import '../serializables/parc_user.dart';
import '../serializables/prestataire.dart';

const databaseId = "6531ad112080ae3b14a7";
const userid = "users";
const chauffeurid = "6537d87b492c80f255e8";
const genreid = "6537960246d5b0e1ab77";
const vehiculeid = "6531ad22153b2a49ca2c";
const etatId="etat";
const chaufDispID = "chauf_disponibilite";
const chaufDoc = "doc_chauffeur";
const vehicDoc = "doc_vehic";
const entrepriseid = "entreprise";
const planningID="planning";
const buckedId = "images";
const reparationId = "reparation";
const activityId = "activity";
const prestataireId = "prestataire";
const endpoint = "https://cloud.appwrite.io/v1";
const project = "6531ace99382e496a904";

class ClientDatabase {
  static Client? client;
  static Account? account;
  static User? user;

  static List<Team> myTeams=List.empty(growable: true);
  static Storage? storage;
  static final DateTime ref = DateTime(2023, 11, 01, 12, 13, 15);

  static Databases? database;

  static ValueNotifier<ParcUser?> me = ValueNotifier(null);

  ClientDatabase() {
    client ??= Client()
      ..setEndpoint(endpoint)
      ..setSelfSigned(status: true)
      ..setProject(project);
    account ??= Account(client!);
    database ??= Databases(client!);
    storage ??= Storage(client!);
    getEntreprise();
  }



  bool isManager({List<Team>? teams}){
    for(var element in teams??myTeams){
      if(element.name.toLowerCase()=='managers'){
        return true;
      }
    }
    return false;
  }
  bool isAdmin({List<Team>? teams}){
    for(var element in teams??myTeams){
      if(element.name.toLowerCase()=='admins'){
        return true;
      }
    }
    return false;
  }

  Future<void> getUser() async {
    if (user == null) {
      await account?.get().then((value) async {
        user = value;
        await database!
            .getDocument(
                databaseId: databaseId,
                collectionId: userid,
                documentId: user!.$id)
            .then((result) {
          me.value = ParcUser.fromJson(result.data);
        }).catchError((error) {
          me.value = ParcUser(
            email: user!.email,
            id: user!.$id,
            name: user!.name,
            tel: user!.phone,
          );
          uploadUser(me.value!);
        });
      }).catchError((error) {
        user = null;
      });
    }
    if(user!=null){
      await Teams(client!).list().then((t) {
        myTeams=t.teams;
      });

      if(kDebugMode){
        String roles='';
        for (var element in myTeams) {
          if(roles.isNotEmpty){
            roles+=', ';
          }
          roles+=element.name.tr();
        }
        print('his teams are : $roles');
      }
    }

  }

  Future<void> getEntreprise() async {
    if (MyEntrepriseState.p == null) {
      MyEntrepriseState.downloading = true;
      try {
        await database!
            .getDocument(
                databaseId: databaseId,
                collectionId: entrepriseid,
                documentId: "1")
            .then((value) {
          MyEntrepriseState.p = value.convertTo(
              (p0) => Entreprise.fromJson(p0 as Map<String, dynamic>));
        });
      } catch (e) {
        //
      }
      MyEntrepriseState.downloading = false;
    }
  }

  void uploadUser(ParcUser u) {
    database!.createDocument(
        databaseId: databaseId,
        collectionId: userid,
        documentId: me.value!.id,
        data: me.value!.toJson(),
        permissions: [
          Permission.read(Role.users()),
          Permission.write(Role.user(me.value!.id)),
          Permission.update(Role.user(me.value!.id)),
          Permission.delete(Role.user(me.value!.id)),
        ]);
  }

  Future<int> countVehicles() async {
    int result = 0;

    await database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehiculeid,
        queries: [
          Query.limit(1),
        ]).then((value) {
      result = value.total;
    }).onError((AppwriteException error, stackTrace) {});

    return result;
  }

  Future<int> countChauffeur() async {
    int result = 0;

    await database!.listDocuments(
        databaseId: databaseId,
        collectionId: chauffeurid,
        queries: [
          Query.limit(1),
        ]).then((value) {
      result = value.total;
    }).onError((AppwriteException error, stackTrace) {});

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

  Future<Vehicle?> getVehicle(String docID) async {
    return await database!
        .getDocument(
            databaseId: databaseId, collectionId: vehiculeid, documentId: docID)
        .then((value) {
      return value
          .convertTo((p0) => Vehicle.fromJson(p0 as Map<String, dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(
          Vehicle(id: docID, matricule: '', matriculeEtrang: false));
    });
  }

  Future<ParcUser?> getUserFromID(String docID) async {
    return await database!
        .getDocument(
            databaseId: databaseId, collectionId: userid, documentId: docID)
        .then((value) {
      return value
          .convertTo((p0) => ParcUser.fromJson(p0 as Map<String, dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(ParcUser(
        id: docID,
        email: '',
      ));
    });
  }

  Future<Prestataire?> getPrestataire(String? docID) async {
    if (docID == null) {
      return Prestataire(id: '', nom: '', adresse: '');
    }
    return await database!
        .getDocument(
            databaseId: databaseId,
            collectionId: prestataireId,
            documentId: docID)
        .then((value) {
      return value
          .convertTo((p0) => Prestataire.fromJson(p0 as Map<String, dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(Prestataire(
        id: docID,
        nom: '',
        adresse: '',
      ));
    });
  }

  Future<void> ajoutActivity(
    int type,
    String docID, {
    String? docName,
  }) async {
    Activity activity = Activity(
      id: DateTime.now().difference(ref).inMilliseconds.toString(),
      type: type,
      docID: docID,
      personName: me.value?.name,
      docName: docName,
      createdBy: me.value?.id,
    );

    await database!.createDocument(
        databaseId: databaseId,
        collectionId: activityId,
        documentId: activity.id,
        data: activity.toJson());
  }

  String getActivityType(int type) {
    switch (type) {
      case 0:
        return "ajoutvehicule";
      case 1:
        return "modifvehicule";
      case 2:
        return "suprvehicule";
      case 3:
        return "ajoutmarque";
      case 4:
        return "ajoutetatvehicule";
      case 5:
        return "modifetatvehicule";
      case 6:
        return "suppretatvehicule";
      case 7:
        return "ajoutdocvehicule";
      case 8:
        return "modifdocvehicule";
      case 9:
        return "suprdocvehicule";
      case 10:
        return "ajoutordre";
      case 11:
        return "modifordre";
      case 12:
        return "suprordre";
      case 13:
        return "nouvprestataire";
      case 14:
        return "modifprestataire";
      case 15:
        return "suprprestataire";
      case 16:
        return "ajoutconducteur";
      case 17:
        return "modifconducteur";
      case 18:
        return "suprconducteur";
      case 19:
        return "archivconducteur";
      case 20:
        return "ajoutetatconducteur";
      case 21:
        return "modifetatconducteur";
      case 22:
        return "suppretatconducteur";
      case 23:
        return "ajoutdocconducteur";
      case 24:
        return "modifdocconducteur";
      case 25:
        return "suprdocconducteur";
      case 26:
        return "ajoutplanning";
      case 27:
        return "modifplanning";
      case 28:
        return "supplanning";
      case 29:
        return "ajoutentreprise";
      case 30:
        return "modifentreprise";
      case 31:
        return "suprentreprise";
      case 32:return "ajoututilisateur";
      case 33:return "modifutilisateur";
      case 35:return "suprutilisateur";
    }
    return '';
  }
}
