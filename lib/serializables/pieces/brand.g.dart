// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Brand _$BrandFromJson(Map<String, dynamic> json) => Brand(
      code: json['code'] as String,
      name: json['name'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      id: json[r'$id'] as String,
    )..search = json['search'] as String?;

Map<String, dynamic> _$BrandToJson(Brand instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'search': instance.search,
    };
