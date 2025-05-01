// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reparation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reparation _$ReparationFromJson(Map<String, dynamic> json) => Reparation(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      ficheReception: json['ficheReception'] as String?,
      ficheReceptionNumber: (json['ficheReceptionNumber'] as num?)?.toInt(),
      numero: (json['numero'] as num).toInt(),
      date: dateFromIntJsonNonNull((json['date'] as num).toInt()),
      designations: designationsFromJson(json['designations'] as List),
      mobile: json['mobile'] as bool? ?? false,
      showEntretien: json['showEntretien'] as bool? ?? true,
      etat: (json['etat'] as num?)?.toInt(),
      nchassi: json['nchassi'] as String?,
      prestataire: json['prestataire'] as String?,
      prestatairenom: json['prestatairenom'] as String?,
      entretien: entretienFromJson(json['entretien'] as String?),
      remarque: json['remarque'] as String?,
      vehicule: json['vehicule'] as String?,
      vehiculemat: json['vehiculemat'] as String?,
    )..search = json['search'] as String?;

Map<String, dynamic> _$ReparationToJson(Reparation instance) =>
    <String, dynamic>{
      'vehicule': instance.vehicule,
      'vehiculemat': instance.vehiculemat,
      'ficheReception': instance.ficheReception,
      'ficheReceptionNumber': instance.ficheReceptionNumber,
      'etat': instance.etat,
      'prestataire': instance.prestataire,
      'prestatairenom': instance.prestatairenom,
      'entretien': entretienToJson(instance.entretien),
      'date': dateToIntJson(instance.date),
      'numero': instance.numero,
      'nchassi': instance.nchassi,
      'remarque': instance.remarque,
      'search': instance.search,
      'mobile': instance.mobile,
          'showEntretien':instance.showEntretien,
      'designations': designationsToJson(instance.designations),
    };
