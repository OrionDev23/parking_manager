// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Variation _$VariationFromJson(Map<String, dynamic> json) => Variation(
      name: json['name'] as String,
      sku: json['sku'] as String,
      optionValues: json['optionValues'] as Map<String, dynamic>?, id:
json['id'] as String,
    );

Map<String, dynamic> _$VariationToJson(Variation instance) => <String, dynamic>{
      'name': instance.name,
      'sku': instance.sku,
      'optionValues': instance.optionValues,
      'id':instance.id,
    };