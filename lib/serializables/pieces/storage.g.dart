// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Storage _$StorageFromJson(Map<String, dynamic> json) => Storage(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      expirationDate: createdAtJson(json['expirationDate'] as String),
      qte: (json['qte'] as num).toDouble(),
      partID: json['partID'] as String,
      pieceName: json['pieceName'] as String,
      fournisseurID: json['fournisseurID'] as String?,
      fournisseurName: json['fournisseurName'] as String?,
      variations: (json['variations'] as List<dynamic>?)
          ?.map((e) => StorageVariation.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..search = json['search'] as String?;

Map<String, dynamic> _$StorageToJson(Storage instance) => <String, dynamic>{
      'qte': instance.qte,
      'partID': instance.partID,
      'pieceName': instance.pieceName,
      'fournisseurID': instance.fournisseurID,
      'fournisseurName': instance.fournisseurName,
      'expirationDate': timeToJsonN(instance.expirationDate),
      'variations': listToJsonString(instance.variations),
      'search': instance.search,
    };
