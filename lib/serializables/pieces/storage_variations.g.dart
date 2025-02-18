// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_variations.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageVariation _$StorageVariationFromJson(Map<String, dynamic> json) =>
    StorageVariation(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      optionValues: json['optionValues'] as Map<String, dynamic>?,
      expirationDate: createdAtJson(json['expirationDate'] as String),
      qte: (json['qte'] as num).toDouble(),
    );

Map<String, dynamic> _$StorageVariationToJson(StorageVariation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'optionValues': instance.optionValues,
      'qte': instance.qte,
      'expirationDate': timeToJsonN(instance.expirationDate),
    };
