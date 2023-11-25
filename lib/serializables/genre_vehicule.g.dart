// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genre_vehicule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenreVehicle _$GenreVehicleFromJson(Map<String, dynamic> json) => GenreVehicle(
      id: json[r'$id'] as String,
      name: json['name'] as String?,
      user: json['user'] == null
          ? null
          : ParcUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GenreVehicleToJson(GenreVehicle instance) =>
    <String, dynamic>{
      'name': instance.name,
      'user': userToJson(instance.user),
    };
