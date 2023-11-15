// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Etat _$EtatFromJson(Map<String, dynamic> json) => Etat(
      id: json[r'$id'] as String,
      type: json['type'] as int,
      valeur: (json['valeur'] as num?)?.toDouble(),
      remarque: json['remarque'] as String?,
      date: json['date'] as int?,
      createdBy: json['createdBy'] == null
          ? null
          : ParcUser.fromJson(json['createdBy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EtatToJson(Etat instance) => <String, dynamic>{
      'type': instance.type,
      'valeur': instance.valeur,
      'remarque': instance.remarque,
      'date': instance.date,
      'createdBy': instance.createdBy?.id,
    };
