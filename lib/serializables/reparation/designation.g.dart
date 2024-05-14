// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'designation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Designation _$DesignationFromJson(Map<String, dynamic> json) => Designation(
      designation: json['designation'] as String,
      prix: (json['prix'] as num?)?.toDouble() ?? 0,
      qte: (json['qte'] as num?)?.toInt() ?? 0,
      tva: (json['tva'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$DesignationToJson(Designation instance) =>
    <String, dynamic>{
      'designation': instance.designation,
      'qte': instance.qte,
      'tva': instance.tva,
      'prix': instance.prix,
    };
