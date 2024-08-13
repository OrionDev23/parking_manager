// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
      id: json['id'] as String,
      createdAt: stringtoTime(json['createdAt'] as String?),
      updatedAt: stringtoTime(json['updatedAt'] as String?),
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

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
      'id': instance.id,
      'updatedAt': timeToJson(instance.updatedAt),
      'createdAt': timeToJson(instance.createdAt),
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
