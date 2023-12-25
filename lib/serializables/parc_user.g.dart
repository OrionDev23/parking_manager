// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parc_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParcUser _$ParcUserFromJson(Map<String, dynamic> json) => ParcUser(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      avatar: json['avatar'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String,
      tel: json['tel'] as String?,
    );

Map<String, dynamic> _$ParcUserToJson(ParcUser instance) => <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'tel': instance.tel,
      'avatar': instance.avatar,
    };
