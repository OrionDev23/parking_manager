// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentVehicle _$DocumentVehicleFromJson(Map<String, dynamic> json) =>
    DocumentVehicle(
      id: json[r'$id'] as String,
      nom: json['nom'] as String,
      vehicle: json['vehicle'] == null
          ? null
          : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      dateExpiration:DateTime.tryParse(json['dateExpiration'])?.difference(ClientDatabase.ref).inMilliseconds.abs()


    );

Map<String, dynamic> _$DocumentVehicleToJson(DocumentVehicle instance) =>
    <String, dynamic>{
      'dateExpiration': instance.dateExpiration,
      'nom': instance.nom,
      'vehicle': instance.vehicle?.id,
    };
