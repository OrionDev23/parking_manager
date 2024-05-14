// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reparation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reparation _$ReparationFromJson(Map<String, dynamic> json) => Reparation(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      numero: (json['numero'] as num).toInt(),
      anneeUtil: (json['anneeUtil'] as num?)?.toInt(),
      couleur: json['couleur'] as String?,
      date: dateFromIntJsonNonNull((json['date'] as num).toInt()),
      designations: designationsFromJson(json['designations'] as List),
      entretien: entretienFromJson(json['entretien'] as String?),
      etat: json['etat'] as String?,
      etatActuel: etatFromJson(json['etatActuel'] as String?),
      gaz: (json['gaz'] as num?)?.toInt(),
      kilometrage: (json['kilometrage'] as num?)?.toInt(),
      modele: json['modele'] as String?,
      nchassi: json['nchassi'] as String?,
      nmoteur: json['nmoteur'] as String?,
      prestataire: json['prestataire'] as String?,
      prestatairenom: json['prestatairenom'] as String?,
      remarque: json['remarque'] as String?,
      type: (json['type'] as num?)?.toInt(),
      vehicule: json['vehicule'] as String?,
      vehiculemat: json['vehiculemat'] as String?,
      marque: json['marque'] as String?,
      matriculeConducteur: json['matriculeConducteur'] as String?,
      prenomConducteur: json['prenomConducteur'] as String?,
      nomConducteur: json['nomConducteur'] as String?,
    );

Map<String, dynamic> _$ReparationToJson(Reparation instance) =>
    <String, dynamic>{
      'vehicule': instance.vehicule,
      'vehiculemat': instance.vehiculemat,
      'etat': instance.etat,
      'type': instance.type,
      'prestataire': instance.prestataire,
      'prestatairenom': instance.prestatairenom,
      'date': dateToIntJson(instance.date),
      'numero': instance.numero,
      'gaz': instance.gaz,
      'kilometrage': instance.kilometrage,
      'nmoteur': instance.nmoteur,
      'nchassi': instance.nchassi,
      'couleur': instance.couleur,
      'remarque': instance.remarque,
      'marque': instance.marque,
      'nomConducteur': instance.nomConducteur,
      'prenomConducteur': instance.prenomConducteur,
      'matriculeConducteur': instance.matriculeConducteur,
      'designations': designationsToJson(instance.designations),
      'etatActuel': etatVehiculeToJson(instance.etatActuel),
      'entretien': entretienToJson(instance.entretien),
      'anneeUtil': instance.anneeUtil,
      'modele': instance.modele,
    };
