import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/activity.dart';
import 'package:encrypt/encrypt.dart' as en;

import '../main.dart';
import '../screens/entreprise/entreprise.dart';
import '../screens/sidemenu/sidemenu.dart';
import '../serializables/entreprise.dart';
import '../serializables/parc_user.dart';

const databaseId = "6531ad112080ae3b14a7";
const userid = "users";
const trialID = "trialdate";
const limitsID = "limits";
const chauffeurid = "6537d87b492c80f255e8";
const genreid = "6537960246d5b0e1ab77";
const vehiculeid = "6531ad22153b2a49ca2c";
const etatId = "etat";
const chaufDispID = "chauf_disponibilite";
const chaufDoc = "doc_chauffeur";
const vehicDoc = "doc_vehic";
const entrepriseid = "entreprise";
const planningID = "planning";
const buckedId = "images";
const adminID = "admin_keys";
const reparationId = "reparation";
const activityId = "activity";
const prestataireId = "prestataire";
const backupId="backup";
const endpoint = "https://cloud.appwrite.io/v1";
String? project;

String? secretKey;

class ClientDatabase {
  static bool secretKeySet = false;
  static Client? client;
  static Account? account;
  static User? user;

  static List<Team> myTeams = List.empty(growable: true);
  static Storage? storage;
  static final DateTime ref = DateTime(2023, 11, 01, 12, 13, 15);

  static Databases? database;

  static ValueNotifier<ParcUser?> me = ValueNotifier(null);

  ClientDatabase() {
    project ??= prefs.getString('project');
    if(project!=null){
      client ??= Client()
        ..setEndpoint(endpoint)
        ..setProject(project);
      account ??= Account(client!);
      database ??= Databases(client!);
      storage ??= Storage(client!);
      getLimits();

      getEntreprise();
    }

  }

  bool isManager({List<Team>? teams}) {
    for (var element in teams ?? myTeams) {
      if (element.name.toLowerCase() == 'managers') {
        return true;
      }
    }
    return false;
  }

  bool isAdmin({List<Team>? teams}) {
    for (var element in teams ?? myTeams) {
      if (element.name.toLowerCase() == 'admins') {
        if (teams == null && !secretKeySet) {
          setSecretKey();
        }
        return true;
      }
    }
    return false;
  }

  static bool settingSecretKey = false;


  static en.Encrypter? encrypter;
  static en.IV? iv;
  void setSecretKey() async {
    if (!settingSecretKey && !secretKeySet) {
      settingSecretKey = true;
      await database!
          .getDocument(
              databaseId: databaseId,
              collectionId: adminID,
              documentId: 'admin')
          .then((value) {
        secretKey = value.data['key'];
        secretKeySet = true;
        String s;
        if(secretKey!=null){
          if (secretKey!.length < 32) {
            s = secretKey!;
            for (int i = 0; i < (32 - secretKey!.length); i++) {
              s = '${s}p';
            }
          } else {
            s = secretKey!.substring(0, 32);
          }
          final key = en.Key.fromUtf8(s);
          iv = en.IV.fromUtf8(s.substring(0,16));
          encrypter = en.Encrypter(en.AES(key));
        }


      }).onError((error, stackTrace) {
      });
    }
  }

  static bool gettingUser = false;

  Future<void> getUser() async {
    if (user == null && !gettingUser) {
      gettingUser = true;
      await account?.get().then((value) async {
        user = value;
          await getTrialDate();
          if (trialDate == null ||
              trialDate!.difference(DateTime.now()).inMilliseconds <= 0) {
            await account!.deleteSession(sessionId: 'current');
            user = null;
            PanesListState.signedIn.value = false;
            PanesListState.index.value = 0;
            return;
          }
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
      }).
      onError((AppwriteException error,stacktrace) {
        if (kDebugMode) {
          print(error.message);
          print(error.response);

        }
        user = null;
      });
      gettingUser = false;
    }
    if (user != null) {
      await Teams(client!).list().then((t) {
        myTeams = t.teams;
      });

    }
  }

  static DateTime? trialDate;


  static Map<String,int> limits={};

  static bool gotLimit=false;

  Future<void> getLimits() async{
    if(!gotLimit){
      await database!
          .getDocument(
          databaseId: databaseId,
          collectionId: limitsID,
          documentId: '1')
          .then((value) {

        if(value.data.containsKey('vehicles')){
          limits['vehicles']=value.data['vehicles'];
        }
        if(value.data.containsKey('users')){
          limits['users']=value.data['users'];
        }
        gotLimit=true;

      }).onError((AppwriteException error, stackTrace) {
        gotLimit=false;
      });
    }

  }

  Future<void> getTrialDate() async {
    if(user!.$id=='999'){
      trialDate = DateTime(2100);

    }
    else{
      await database!
          .getDocument(
          databaseId: databaseId,
          collectionId: trialID,
          documentId: '1')
          .then((value) {
        trialDate = DateTime.tryParse(value.data['date']);
      }).onError((AppwriteException error, stackTrace) {
      });
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
    if (kIsWeb) {
      downloadLogo();
    }
  }

  static Future<void> downloadLogo() async {
    await ClientDatabase.storage!
        .getFileDownload(bucketId: buckedId, fileId: 'mylogo.png')
        .then((value) async {
      MyEntrepriseState.logo = value;
    }).onError((error, stackTrace) {});
  }

  void uploadUser(ParcUser u) {
    database!.createDocument(
        databaseId: databaseId,
        collectionId: userid,
        documentId: u.id,
        data: me.value!.toJson(),
        permissions: [
          Permission.read(Role.users()),
          Permission.write(Role.user(me.value!.id)),
          Permission.update(Role.user(me.value!.id)),
          Permission.delete(Role.user(me.value!.id)),
        ]);
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
      case 32:
        return "ajoututilisateur";
      case 33:
        return "modifutilisateur";
      case 34:
        return "suprutilisateur";
      case 35:
        return "changePermi";
    }
    return '';
  }








}
