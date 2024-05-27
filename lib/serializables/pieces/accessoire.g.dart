// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accessoire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Accesoire _$AccesoireFromJson(Map<String, dynamic> json) => Accesoire(
      designation: json['designation'] as String,
      prix: (json['prix'] as num).toDouble(),
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$AccesoireToJson(Accesoire instance) => <String, dynamic>{
      'designation': instance.designation,
      'prix': instance.prix,
    };
