// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marque.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Marque _$MarqueFromJson(Map<String, dynamic> json) => Marque(
      id: json[r'$id'] as String,
      nom: json['nom'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    )..createdBy = json['createdBy'] as String?;

Map<String, dynamic> _$MarqueToJson(Marque instance) => <String, dynamic>{
      'nom': instance.nom,
      'createdBy': instance.createdBy,
    };
