// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentVehicle _$DocumentVehicleFromJson(Map<String, dynamic> json) =>
    DocumentVehicle(
      id: json[r'$id'] as String,
      nom: json['nom'] as String,
      vehiclemat: json['vehiclemat'] as String?,
      vehicle: json['vehicle'] as String?,
      dateExpiration: dateFromIntJson(
        (json['date_expiration'] as num?)?.toInt(),
      ),
      createdBy: json['createdBy'] as String?,
      documentType: json['documentType'] as String?,
      fileId: json['fileId'] as String?,
      fileName: json['fileName'] as String?,
      mimeType: json['mimeType'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      issueDate: dateFromIntJson((json['issueDate'] as num?)?.toInt()),
      notes: json['notes'] as String?,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
    );

Map<String, dynamic> _$DocumentVehicleToJson(DocumentVehicle instance) =>
    <String, dynamic>{
      'date_expiration': dateToIntJson(instance.dateExpiration),
      'nom': instance.nom,
      'vehicle': instance.vehicle,
      'vehiclemat': instance.vehiclemat,
      'createdBy': instance.createdBy,
      'documentType': instance.documentType,
      'fileId': instance.fileId,
      'fileName': instance.fileName,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'issueDate': dateToIntJson(instance.issueDate),
      'notes': instance.notes,
    };
