// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      id: json[r'$id'] as String,
      matricule: json['matricule'] as String,
      matriculeEtrang: json['martricule_etrang'] as bool,
      wilaya: json['wilaya'] as int?,
      commune: json['commune'] as String?,
      date: json['date'] as int?,
      adresse: json['adresse'] as String?,
      quittance: (json['quittance'] as num?)?.toDouble(),
      numero: json['numero'] as String?,
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      profession: json['profession'] as String?,
      numeroSerie: json['numero_serie'] as String?,
      type: json['type'] as String?,
      anneeUtil: json['annee_util'] as int?,
      carrosserie: json['carrosserie'] as String?,
      charegeUtile: json['charge_utile'] as int?,
      daira: json['daira'] as String?,
      energie: json['energie'] as String?,
      genre: json['genre'] as String?,
      marque: json['marque'] as String?,
      matriculePrec: json['matricule_prec'] as String?,
      pays: json['pays'] as String?,
      placesAssises: json['place_assises'] as int?,
      poidsTotal: json['poids_total'] as int?,
      puissance: json['puissance'] as int?,
      createdBy: json['user_creation'] as String?,
      etat: json['etat'] as String?,
      etatactuel: json['etatactuel'] as int?,
    )
      ..dateCreation = updatedAtJson(json[r'$createdAt'] as String)
      ..dateModification = updatedAtJson(json[r'$updatedAt'] as String);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'matricule': instance.matricule,
      'martricule_etrang': instance.matriculeEtrang,
      'wilaya': instance.wilaya,
      'commune': instance.commune,
      'daira': instance.daira,
      'adresse': instance.adresse,
      'date': instance.date,
      'quittance': instance.quittance,
      'numero': instance.numero,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'profession': instance.profession,
      'numero_serie': instance.numeroSerie,
      'type': instance.type,
      'marque': instance.marque,
      'genre': instance.genre,
      'charge_utile': instance.charegeUtile,
      'poids_total': instance.poidsTotal,
      'place_assises': instance.placesAssises,
      'puissance': instance.puissance,
      'energie': instance.energie,
      'carrosserie': instance.carrosserie,
      'annee_util': instance.anneeUtil,
      'matricule_prec': instance.matriculePrec,
      'user_creation': instance.createdBy,
      'pays': instance.pays,
      'etat': instance.etat,
      'etatactuel': instance.etatactuel,
    };
