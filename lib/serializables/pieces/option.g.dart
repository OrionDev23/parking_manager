// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Option _$OptionFromJson(Map<String, dynamic> json) => Option(
      code: json['code'] as String,
      values:
          (json['values'] as List<dynamic>?)?.map((e) => e as String).toList(),
      name: json['name'] as String,
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$OptionToJson(Option instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'values': instance.values,
    };
