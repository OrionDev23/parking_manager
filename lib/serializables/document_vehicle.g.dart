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
      dateExpiration: json['date_expiration'] as int?,
      createdBy: json['createdBy'] == null
          ? null
          : ParcUser.fromJson(json['createdBy'] as Map<String, dynamic>),
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$DocumentVehicleToJson(DocumentVehicle instance) =>
    <String, dynamic>{
      'date_expiration': instance.dateExpiration,
      'nom': instance.nom,
      'vehicle': vehiculeToJson(instance.vehicle),
      'createdBy': userToJson(instance.createdBy),
    };
