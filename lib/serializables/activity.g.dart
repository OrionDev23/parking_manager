// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      type: json['type'] as int,
      docID: json['docID'] as String,
      personName: json['personName'] as String?,
      createdBy: json['createdBy'] as String?,
      docName: json['docName'] as String?,
    );

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
      'type': instance.type,
      'docID': instance.docID,
      'personName': instance.personName,
      'createdBy': instance.createdBy,
      'docName': instance.docName,
    };
