
import 'dart:convert';

import 'package:parc_oto/serializables/etat_vehicle.dart';
import 'package:parc_oto/serializables/genre_vehicule.dart';
import 'package:parc_oto/serializables/parc_user.dart';

import '../providers/client_database.dart';
import '../serializables/designation.dart';
import '../serializables/entretien_vehicle.dart';
import '../serializables/marque.dart';
import '../serializables/state.dart';
import '../serializables/vehicle.dart';

class ProfilUtilitis{
 static  String getFirstLetters(ParcUser? user) {
    String result = "";
    if (user != null) {
      if (user.name!=null && user.name!.isNotEmpty) {
        var s = user.name!.split(' ');
        if (s.length > 1) {
          result = s[0][0] + s[1][0];
        } else {
          result = user.name![0] + user.name![1];
        }
      }
      else {
        result = user.email[0] + user.email[1];
      }
    }
    return result;
  }
}

int? dateToIntJson(DateTime? date){
  return date?.difference(ClientDatabase.ref).inMilliseconds;
}

DateTime? dateFromIntJson(int? json){
  if(json!=null){
    return ClientDatabase.ref.add(Duration(milliseconds:json));
  }
  else{
    return null;
  }
}
DateTime dateFromIntJsonNonNull(int json){
  return ClientDatabase.ref.add(Duration(milliseconds:json));
}

String? userToJson(ParcUser? value){
  return value?.id;
}

String? vehiculeToJson(Vehicle? value){
  return value?.id;
}

String? stateToJson(Etat? etat){
  return etat?.id;
}

String? marqueToJson(Marque? marque){
  return marque?.id;
}

String? genreToJson(GenreVehicle? genre){
  return genre?.id;
}


DateTime? createdAtJson(String json){
  return DateTime.tryParse(json);
}

DateTime? updatedAtJson(String json){
  return DateTime.tryParse(json);
}



List<String>? designationsToJson(List<Designation>? list){

  return list?.map((e) => jsonEncode(e.toJson())).toList();
}


String? etatVehiculeToJson(EtatVehicle? etat){
  return jsonEncode(etat?.toJson());
}

String? entretienToJson(EntretienVehicle? entretienVehicle){
  return jsonEncode(entretienVehicle?.toJson());
}

EtatVehicle? etatFromJson(String? json){
  return json==null?null:EtatVehicle.fromJson(jsonDecode(json));
}
EntretienVehicle? entretienFromJson(String? json){
  return json==null?null:EntretienVehicle.fromJson(jsonDecode(json));
}

List<Designation>? designationsFromJson(List<dynamic> json){
  return json.map((e) => Designation.fromJson(jsonDecode(e) as Map<String,dynamic>)).toList();
}