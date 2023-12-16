import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/vehicle.dart';

import '../screens/entreprise.dart';
import '../serializables/entreprise.dart';
import '../serializables/parc_user.dart';
import '../serializables/prestataire.dart';

const databaseId = "6531ad112080ae3b14a7";
const userid = "users";
const chauffeurid = "6537d87b492c80f255e8";
const genreid = "6537960246d5b0e1ab77";
const vehiculeid = "6531ad22153b2a49ca2c";
const chaufDispID="chauf_disponibilite";
const chaufDoc="doc_chauffeur";
const vehicDoc="doc_vehic";
const entrepriseid="entreprise";
const buckedId="images";
const reparationId="reparation";
const prestataireId="prestataire";
const endpoint ="https://cloud.appwrite.io/v1";
const project="6531ace99382e496a904";
class ClientDatabase {
  static Client? client;
  static Account? account;
  static User? user;
  static Storage? storage;
  static final DateTime ref=DateTime(2023,11,01,12,13,15);

  static Databases? database;

  static ValueNotifier<ParcUser?> me=ValueNotifier(null);

  ClientDatabase() {
    client ??= Client()
      ..setEndpoint(endpoint)
      ..setProject(project);
    account ??= Account(client!);
    database ??= Databases(client!);
    storage ??=Storage(client!);
    getEntreprise();
  }

  Future<void> getUser() async {
    if (user == null) {
      await account?.get().then((value) async {
        user = value;
        database!
            .getDocument(
                databaseId: databaseId,
                collectionId: userid,
                documentId: user!.$id)
            .then((result) {
          me.value = ParcUser.fromJson(result.data);
        }).catchError((error){

          me.value = ParcUser(
            email: user!.email,
            id: user!.$id,
            name: user!.name,
            tel: user!.phone,
            datea: DateTime.parse(user!.accessedAt.isEmpty?DateTime.now().toIso8601String():user!.accessedAt).difference(ref).inMilliseconds.abs(),
            datec: DateTime.parse(user!.$createdAt).difference(ref).inMilliseconds.abs(),
            datel: DateTime.parse(user!.$updatedAt.isEmpty?DateTime.now().toIso8601String():user!.$updatedAt).difference(ref).inMilliseconds.abs(),
          );
          uploadUser(me.value!);
        });
      }).catchError((error) {
        user = null;
      });
    }
  }


  Future<void> getEntreprise() async{
    if(MyEntrepriseState.p==null){
      MyEntrepriseState.downloading=true;
      try{
        await database!.getDocument(
            databaseId: databaseId, collectionId: entrepriseid,
            documentId: "1").then((value) {
          MyEntrepriseState.p=value.convertTo((p0) => Entreprise.fromJson(p0 as Map<String,dynamic>));
        });
      }
      catch(e){
        //
      }
      MyEntrepriseState.downloading=false;
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




  Future<int> countVehicles() async{
    int result=0;


      await database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehiculeid,
        queries: [
          Query.limit(1),
        ]
      ).then((value) {
        result=value.total;
      }).onError((AppwriteException error, stackTrace) {
      });



    return result;
  }

  Future<int> countChauffeur() async{
    int result=0;


    await database!.listDocuments(
        databaseId: databaseId,
        collectionId: chauffeurid,
        queries: [
          Query.limit(1),
        ]
    ).then((value) {
      result=value.total;
    }).onError((AppwriteException error, stackTrace) {
    });



    return result;
  }


  static String getEtat(int? etat){
    switch(etat){
      case 0:return 'disponible';
      case 1:return 'mission';
      case 2:return 'absent';
      case 3:return 'quitteentre';
      default:return 'disponible';
    }
  }
  
  Future<Vehicle?> getVehicle(String docID) async{
    return await database!.getDocument(
        databaseId: databaseId,
        collectionId: vehiculeid, documentId: docID).then((value) {
          return value.convertTo((p0) => Vehicle.fromJson(p0 as Map<String,dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(Vehicle(id: docID, matricule: '', matriculeEtrang: false));
    });
  }


  Future<ParcUser?> getUserFromID(String docID) async{
    return await database!.getDocument(
        databaseId: databaseId,
        collectionId: userid, documentId: docID).then((value) {
      return value.convertTo((p0) => ParcUser.fromJson(p0 as Map<String,dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(ParcUser(id: docID, email: '',));
    });
  }


  Future<Prestataire?> getPrestataire(String? docID) async{
    if(docID==null){
      return Prestataire(id: '', nom: '', adresse: '');
    }
    return await database!.getDocument(
        databaseId: databaseId,
        collectionId: prestataireId, documentId: docID).then((value) {
      return value.convertTo((p0) => Prestataire.fromJson(p0 as Map<String,dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(Prestataire(id: docID, nom: '', adresse: '',));
    });
  }
}
