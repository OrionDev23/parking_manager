// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prestataire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prestataire _$PrestataireFromJson(Map<String, dynamic> json) => Prestataire(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      description: json['description'] as String?,
      nom: json['nom'] as String,
      adresse: json['adresse'] as String,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      search: json['search'] as String?,
      art: json['art'] as String?,
      nif: json['nif'] as String?,
      nis: json['nis'] as String?,
      rc: json['rc'] as String?,
    );

Map<String, dynamic> _$PrestataireToJson(Prestataire instance) =>
    <String, dynamic>{
      'nom': instance.nom,
      'adresse': instance.adresse,
      'telephone': instance.telephone,
      'description': instance.description,
      'nif': instance.nif,
      'nis': instance.nis,
      'rc': instance.rc,
      'art': instance.art,
      'email': instance.email,
      'search': instance.search,
    };
