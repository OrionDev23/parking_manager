
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;

import 'package:parc_oto/serializables/etat_vehicle.dart';
import 'package:parc_oto/serializables/genre_vehicule.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../providers/client_database.dart';
import '../serializables/designation.dart';
import '../serializables/entretien_vehicle.dart';
import '../serializables/marque.dart';
import '../serializables/state.dart';
import '../serializables/vehicle.dart';

class ParcOtoUtilities{
 static  String getFirstLetters(ParcUser? user,) {
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
Appointment appointmentFromJson(String json){

    Map<String,dynamic> map=jsonDecode(json);
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

String appointmentToJson(Appointment? a){
  if(a!=null){
    return jsonEncode({
      'startTime':a.startTime.toIso8601String(),
      'endTime':a.endTime.toIso8601String(),
      'recurrenceRule':a.recurrenceRule,
      'isAllDay':a.isAllDay,
      'id':a.id,
      'subject':a.subject,
      'color':a.color.value,
      'notes':a.notes,
      'location':a.location,
      'resourceIds':jsonEncode(a.resourceIds),
    });
  }
  return '';
}


Color colorFromInt(int? color){
  if(color==null){
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }
  else{
    return Color(color);
  }
}

int colorToInt(Color? color){
  return color?.value??0x00000000;
}


