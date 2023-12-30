// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conducteur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conducteur _$ConducteurFromJson(Map<String, dynamic> json) => Conducteur(
      name: json['name'] as String,
      prenom: json['prenom'] as String,
      etat: json['etat'] as int? ?? 0,
      etatactuel: json['etatactuel'] as String?,
      id: json[r'$id'] as String,
      createdBy: json['createdBy'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      search: json['search'] as String?,
      adresse: json['adresse'] as String?,
      email: json['email'] as String?,
      dateNaissance: dateFromIntJson(json['dateNaissance'] as int?),
      telephone: json['telephone'] as String?,
    );

Map<String, dynamic> _$ConducteurToJson(Conducteur instance) =>
    <String, dynamic>{
      'name': instance.name,
      'prenom': instance.prenom,
      'search': instance.search,
      'email': instance.email,
      'telephone': instance.telephone,
      'adresse': instance.adresse,
      'dateNaissance': dateToIntJson(instance.dateNaissance),
      'createdBy': instance.createdBy,
      'etatactuel': instance.etatactuel,
      'etat': instance.etat,
    };
