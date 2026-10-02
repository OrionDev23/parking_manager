// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskGroup _$TaskGroupFromJson(Map<String, dynamic> json) => TaskGroup(
      numero: json['numero'] as String,
      tasks:
          (json['tasks'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [''],
      time: (json['time'] as num?)?.toDouble() ?? 0.00,
    );

Map<String, dynamic> _$TaskGroupToJson(TaskGroup instance) => <String, dynamic>{
      'numero': instance.numero,
      'tasks': instance.tasks,
      'time': instance.time,
    };
