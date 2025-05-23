import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/serializables/pieces/variation.dart';
import 'package:parc_oto/serializables/reparation/etat_vehicle.dart';
import 'package:parc_oto/serializables/reparation/etat_vehicle_gts.dart';
import 'package:parc_oto/serializables/vehicle/genre_vehicule.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../providers/client_database.dart';
import '../serializables/reparation/designation.dart';
import '../serializables/reparation/entretien_vehicle.dart';
import '../serializables/vehicle/marque.dart';
import '../serializables/vehicle/state.dart';
import '../serializables/vehicle/vehicle.dart';

class ParcOtoUtilities {
  static String getFirstLetters(
    ParcUser? user,
  ) {
    String result = "";
    if (user != null) {
      if (user.name != null && user.name!.isNotEmpty) {
        var s = user.name!.split(' ');
        if (s.length > 1) {
          result = s[0][0] + s[1][0];
        } else {
          result = user.name![0] + user.name![1];
        }
      } else {
        result = user.email[0] + user.email[1];
      }
    }
    return result;
  }
}

int? dateToIntJson(DateTime? date) {
  return date?.difference(DatabaseGetter.ref).inMilliseconds;
}

DateTime? dateFromIntJson(int? json) {
  if (json != null) {
    return DatabaseGetter.ref.add(Duration(milliseconds: json));
  } else {
    return null;
  }
}

DateTime dateFromIntJsonNonNull(int json) {
  return DatabaseGetter.ref.add(Duration(milliseconds: json));
}

String? userToJson(ParcUser? value) {
  return value?.id;
}

String? vehiculeToJson(Vehicle? value) {
  return value?.id;
}

String? stateToJson(Etat? etat) {
  return etat?.id;
}

String? marqueToJson(Marque? marque) {
  return marque?.id;
}

String? genreToJson(GenreVehicle? genre) {
  return genre?.id;
}

DateTime? createdAtJson(String json) {
  return DateTime.tryParse(json);
}

DateTime? updatedAtJson(String json) {
  return DateTime.tryParse(json);
}

List<String>? designationsToJson(List<Designation>? list) {
  return list?.map((e) => jsonEncode(e.toJson())).toList();
}

String? etatVehiculeToJson(EtatVehicleInterface? etat) {
  return jsonEncode(etat?.toJson());
}

String? entretienToJson(EntretienVehicle? entretienVehicle) {
  return jsonEncode(entretienVehicle?.toJson());
}

EtatVehicleInterface? etatFromJson(String? json) {
  if(json==null || json=='null'){
    return null;
  }
  else{
    Map<String,dynamic> data=jsonDecode(json);
    if(data.containsKey('intCab')){
      return EtatVehicleGTS.fromJson(data);
    }
    else{
      return EtatVehicle.fromJson(data);
    }
  }
}

EntretienVehicle? entretienFromJson(String? json) {
  return json == null || json=='null'? null : EntretienVehicle.fromJson(jsonDecode(json));
}

List<Designation>? designationsFromJson(List<dynamic> json) {
  return json
      .map((e) => Designation.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .toList();
}

Appointment appointmentFromJson(String json) {
  Map<String, dynamic> map = jsonDecode(json);
  return Appointment(
    startTime: createdAtJson(map['startTime'])!,
    endTime: createdAtJson(map['endTime'])!,
    recurrenceRule: map['recurrenceRule'],
    isAllDay: map['isAllDay'],
    resourceIds: jsonDecode(map['resourceIds']),
    id: map['id'],
    subject: map['subject'],
    color: Color(map['color']),
    notes: map['notes'],
    location: map['location'],
  );
}

String appointmentToJson(Appointment? a) {
  if (a != null) {
    return jsonEncode({
      'startTime': a.startTime.toIso8601String(),
      'endTime': a.endTime.toIso8601String(),
      'recurrenceRule': a.recurrenceRule,
      'isAllDay': a.isAllDay,
      'id': a.id,
      'subject': a.subject,
      'color': a.color.value,
      'notes': a.notes,
      'location': a.location,
      'resourceIds': jsonEncode(a.resourceIds),
    });
  }
  return '';
}

Color colorFromInt(int? color) {
  if (color == null) {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  } else {
    return Color(color);
  }
}
String listToString(List<String>? words){
  String result="";
  if(words!=null){
    for(int i=0;i<words.length;i++){
      result+=words[i];
      result+=" ";
    }
  }

  result.trim();
  return result;
}


int colorToInt(Color? color) {
  return color?.value ?? 0x00000000;
}

DateTime? stringtoTime(String? json) {
  return DateTime.tryParse(json ?? '');
}

DateTime stringToTimeNN(String? json) {
  return DateTime.tryParse(json ?? '') ?? DateTime.now();
}
String timeToJson(DateTime? date) {
  return date?.toIso8601String() ?? DateTime.now().toIso8601String();
}
String? timeToJsonN(DateTime? date) {
  return date?.toIso8601String();
}


List<dynamic>? listToJson(List<dynamic>? objects) {
  return objects?.map((s) => s.toJson()).toList();
}
List<String>? listToJsonString(List<dynamic>?objects){
  return objects?.map((s)=>jsonEncode(s.toJson())).toList();
}

String dlistToString(List<dynamic>?objects){
  List<String>? temp=listToJsonString(objects);
  String result="";
  if(temp!=null){
    for(int i=0;i<temp!.length;i++){
      result+=temp[i]??'';
      result+=" ";
    }
  }

  return result;
}

List<Variation>? variationsFromList(List<dynamic>? json){
  return json
      ?.map((e) => Variation.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .toList();
}