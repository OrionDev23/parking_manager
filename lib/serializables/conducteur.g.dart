// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conducteur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conducteur _$ConducteurFromJson(Map<String, dynamic> json) => Conducteur(
      name: json['name'] as String,
      prenom: json['prenom'] as String,
      id: json[r'$id'] as String,
      search: json['search'] as String?,
      adresse: json['adresse'] as String?,
      createdBy: json['createdBy'] == null
          ? null
          : ParcUser.fromJson(json['createdBy'] as Map<String, dynamic>),
      email: json['email'] as String?,
      dateNaissance: json['dateNaissance'] == null
          ? null
          : DateTime.parse(json['dateNaissance'] as String),
      telephone: json['telephone'] as String?,
    )
      ..dateAjout = json[r'$createdAt'] == null
          ? null
          : DateTime.parse(json[r'$createdAt'] as String)
      ..dateModif = json[r'$updatedAt'] == null
          ? null
          : DateTime.parse(json[r'$updatedAt'] as String);

Map<String, dynamic> _$ConducteurToJson(Conducteur instance) =>
    <String, dynamic>{
      'name': instance.name,
      'prenom': instance.prenom,
      'search': instance.search,
      'email': instance.email,
      'telephone': instance.telephone,
      'adresse': instance.adresse,
      'dateNaissance': dateToIntJson(instance.dateNaissance),
      'createdBy': userToJson(instance.createdBy),
    };
