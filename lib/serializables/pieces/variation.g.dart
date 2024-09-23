// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Variation _$VariationFromJson(Map<String, dynamic> json) => Variation(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      optionValues: json['optionValues'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$VariationToJson(Variation instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sku': instance.sku,
      'optionValues': instance.optionValues,
    };
