// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentVehicle _$DocumentVehicleFromJson(Map<String, dynamic> json) =>
    DocumentVehicle(
      id: json[r'$id'] as String,
      nom: json['nom'] as String,
      vehiclemat: json['vehiclemat'] as String?,
      vehicle: json['vehicle'] as String?,
      dateExpiration: dateFromIntJson(json['date_expiration'] as int?),
      createdBy: json['createdBy'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$DocumentVehicleToJson(DocumentVehicle instance) =>
    <String, dynamic>{
      'date_expiration': dateToIntJson(instance.dateExpiration),
      'nom': instance.nom,
      'vehicle': instance.vehicle,
      'vehiclemat': instance.vehiclemat,
      'createdBy': instance.createdBy,
    };
