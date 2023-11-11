// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      matricule: json['matricule'] as String,
      martriculeEtrang: json['martricule_etrang'] as bool,
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
      carosserie: json['carrosserie'] as String?,
      chargeUtile: json['charge_utile'] as int?,
      daira: json['daira'] as String?,
      energie: json['energie'] as String?,
      genre: json['genre'] as String?,
      marque: json['marque'] as String?,
      matriculePrec: json['matricule_prec'] as String?,
      pays: json['pays'] as String?,
      placeAssises: json['place_assises'] as int?,
      poidsTotal: json['poids_total'] as int?,
      puissance: json['puissance'] as int?,
      userCreation: json['user_creation'] as String?,
    );

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'matricule': instance.matricule,
      'martricule_etrang': instance.martriculeEtrang,
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
      'charge_utile': instance.chargeUtile,
      'poids_total': instance.poidsTotal,
      'place_assises': instance.placeAssises,
      'puissance': instance.puissance,
      'energie': instance.energie,
      'carrosserie': instance.carosserie,
      'annee_util': instance.anneeUtil,
      'matricule_prec': instance.matriculePrec,
      'user_creation': instance.userCreation,
      'pays': instance.pays,
    };
