// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      matricule: json['matricule'] as String,
      wilaya: json['wilaya'] as int?,
      commune: json['commune'] as String?,
      date: json['date'] as int?,
      adresse: json['adresse'] as String?,
      quittance: (json['quittance'] as num?)?.toDouble(),
      numero: json['numero'] as String?,
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      profession: json['profession'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      type: json['type'] as String?,
      anneeUtil: json['anneeUtil'] as int?,
      carosserie: json['carosserie'] as String?,
      chargeUtile: json['chargeUtile'] as int?,
      daira: json['daira'] as String?,
      energie: json['energie'] as String?,
      genre: json['genre'] as String?,
      marque: json['marque'] as String?,
      matriculePrec: json['matriculePrec'] as String?,
      pays: json['pays'] as String?,
      placeAssises: json['placeAssises'] as int?,
      poidsTotal: json['poidsTotal'] as int?,
      puissance: json['puissance'] as int?,
      userCreation: json['userCreation'] as String?,
    )
      ..id = json['id'] as String?
      ..dateCreation = json['dateCreation'] as int?
      ..dateModification = json['dateModification'] as int?;

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'id': instance.id,
      'matricule': instance.matricule,
      'wilaya': instance.wilaya,
      'commune': instance.commune,
      'daira': instance.daira,
      'adresse': instance.adresse,
      'dateCreation': instance.dateCreation,
      'dateModification': instance.dateModification,
      'date': instance.date,
      'quittance': instance.quittance,
      'numero': instance.numero,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'profession': instance.profession,
      'numeroSerie': instance.numeroSerie,
      'type': instance.type,
      'marque': instance.marque,
      'genre': instance.genre,
      'chargeUtile': instance.chargeUtile,
      'poidsTotal': instance.poidsTotal,
      'placeAssises': instance.placeAssises,
      'puissance': instance.puissance,
      'energie': instance.energie,
      'carosserie': instance.carosserie,
      'anneeUtil': instance.anneeUtil,
      'matriculePrec': instance.matriculePrec,
      'userCreation': instance.userCreation,
      'pays': instance.pays,
    };
