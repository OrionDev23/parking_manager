// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genre_vehicule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenreVehicle _$GenreVehicleFromJson(Map<String, dynamic> json) => GenreVehicle(
      id: json[r'$id'] as String,
      name: json['name'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$GenreVehicleToJson(GenreVehicle instance) =>
    <String, dynamic>{
      'name': instance.name,
      'createdBy': instance.createdBy,
    };
