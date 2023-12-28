// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Planning _$PlanningFromJson(Map<String, dynamic> json) => Planning(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      subject: json['subject'] as String,
      startTime: dateFromIntJsonNonNull(json['startTime'] as int),
      endTime: dateFromIntJsonNonNull(json['endTime'] as int),
      resourceIds: (json['resourceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      type: json['type'] as int? ?? 0,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      color: colorFromInt(json['color'] as int?),
      createdBy: json['createdBy'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      recurrenceRule: json['recurrenceRule'] as String?,
    );

Map<String, dynamic> _$PlanningToJson(Planning instance) => <String, dynamic>{
      'startTime': dateToIntJson(instance.startTime),
      'endTime': dateToIntJson(instance.endTime),
      'recurrenceRule': instance.recurrenceRule,
      'isAllDay': instance.isAllDay,
      'subject': instance.subject,
      'type': instance.type,
      'createdBy': instance.createdBy,
      'color': colorToInt(instance.color),
      'notes': instance.notes,
      'location': instance.location,
      'resourceIds': instance.resourceIds,
    };
