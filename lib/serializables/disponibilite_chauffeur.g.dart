// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disponibilite_chauffeur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisponibiliteChauffeur _$DisponibiliteChauffeurFromJson(
        Map<String, dynamic> json) =>
    DisponibiliteChauffeur(
      id: json[r'$id'] as String,
      chauffeurNom: json['chauffeurNom'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      type: json['type'] as int,
      createdBy: json['createdBy'] as String?,
      chauffeur: json['chauffeur'] as String,
    );

Map<String, dynamic> _$DisponibiliteChauffeurToJson(
        DisponibiliteChauffeur instance) =>
    <String, dynamic>{
      'type': instance.type,
      'chauffeur': instance.chauffeur,
      'chauffeurNom': instance.chauffeurNom,
      'createdBy': instance.createdBy,
    };
