// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Backup _$BackupFromJson(Map<String, dynamic> json) => Backup(
      vehicles: (json['vehicles'] as num?)?.toInt() ?? 0,
      vehicledocs: (json['vehicledocs'] as num?)?.toInt() ?? 0,
      vehiclesstates: (json['vehiclesstates'] as num?)?.toInt() ?? 0,
      drivers: (json['drivers'] as num?)?.toInt() ?? 0,
      driversdocs: (json['driversdocs'] as num?)?.toInt() ?? 0,
      driversstates: (json['driversstates'] as num?)?.toInt() ?? 0,
      repairs: (json['repairs'] as num?)?.toInt() ?? 0,
      providers: (json['providers'] as num?)?.toInt() ?? 0,
      plannings: (json['plannings'] as num?)?.toInt() ?? 0,
      logs: (json['logs'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String?,
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$BackupToJson(Backup instance) => <String, dynamic>{
      'vehicles': instance.vehicles,
      'vehicledocs': instance.vehicledocs,
      'vehiclesstates': instance.vehiclesstates,
      'drivers': instance.drivers,
      'driversdocs': instance.driversdocs,
      'driversstates': instance.driversstates,
      'repairs': instance.repairs,
      'providers': instance.providers,
      'plannings': instance.plannings,
      'logs': instance.logs,
      'createdBy': instance.createdBy,
    };
