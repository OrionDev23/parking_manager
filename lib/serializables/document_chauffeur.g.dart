// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_chauffeur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentChauffeur _$DocumentChauffeurFromJson(Map<String, dynamic> json) =>
    DocumentChauffeur(
      id: json[r'$id'] as String,
      nom: json['nom'] as String,
      chauffeurNom: json['chauffeurNom'] as String?,
      chauffeur: json['chauffeur'] as String?,
      dateExpiration: json['date_expiration'] as int?,
      createdBy: json['createdBy'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$DocumentChauffeurToJson(DocumentChauffeur instance) =>
    <String, dynamic>{
      'date_expiration': instance.dateExpiration,
      'nom': instance.nom,
      'chauffeur': instance.chauffeur,
      'chauffeurNom': instance.chauffeurNom,
      'createdBy': instance.createdBy,
    };
