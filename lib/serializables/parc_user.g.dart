// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parc_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParcUser _$ParcUserFromJson(Map<String, dynamic> json) => ParcUser(
      avatar: json['avatar'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String,
      datec: json['datec'] as int?,
      datea: json['datea'] as int?,
      datel: json['datel'] as int?,
      tel: json['tel'] as String?,
      id: json[r'$id'] as String,
    );

Map<String, dynamic> _$ParcUserToJson(ParcUser instance) => <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'datec': instance.datec,
      'datea': instance.datea,
      'datel': instance.datel,
      'tel': instance.tel,
      'avatar': instance.avatar,
    };
