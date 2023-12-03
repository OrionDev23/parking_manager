// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entreprise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Entreprise _$EntrepriseFromJson(Map<String, dynamic> json) => Entreprise(
      id: json[r'$id'] as String,
      nom: json['nom'] as String,
      adresse: json['adresse'] as String,
      art: json['art'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      description: json['description'] as String?,
      email: json['email'] as String?,
      nif: json['nif'] as String?,
      nis: json['nis'] as String?,
      rc: json['rc'] as String?,
      search: json['search'] as String?,
      telephone: json['telephone'] as String?,
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      logo: json['logo'] as String?,
    );

Map<String, dynamic> _$EntrepriseToJson(Entreprise instance) =>
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
      'logo': instance.logo,
    };
