
import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';
@JsonSerializable()
class Vehicle{

  bool selected=false;
  String? id;
  String matricule;
  bool martriculeEtrang;
  int? wilaya;
  String? commune;
  String? daira;
  String? adresse;
  int? dateCreation;
  int? dateModification;
  int? date;
  double? quittance;
  String? numero;
  String? nom;
  String? prenom;
  String? profession;

  String? numeroSerie;
  String? type;
  String? marque;
  String? genre;
  int? chargeUtile;
  int? poidsTotal;
  int? placeAssises;
  int? puissance;
  String? energie;
  String? carosserie;
  int? anneeUtil;
  String? matriculePrec;
  String? userCreation;
  String? pays;

  Vehicle({required this.matricule,required this.martriculeEtrang,this.wilaya,
    this.commune,this.date,
    this.adresse,this.quittance,this.numero,
    this.nom,this.prenom,this.profession,
    this.numeroSerie,this.type,this.anneeUtil,
    this.carosserie,this.chargeUtile,this.daira,
    this.energie,this.genre,this.marque,
    this.matriculePrec, this.pays,this.placeAssises,
    this.poidsTotal, this.puissance, this.userCreation,
  });


  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$VehicleToJson(this);
}


/*
* // GENERATED CODE - DO NOT MODIFY BY HAND

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
      genre: json['genre']["\$id"] as String?,
      marque: json['marque']["\$id"] as String?,
      matriculePrec: json['matricule_prec'] as String?,
      pays: json['pays'] as String?,
      placeAssises: json['place_assises'] as int?,
      poidsTotal: json['poids_total'] as int?,
      puissance: json['puissance'] as int?,
      userCreation: json['user_creation']["\$id"] as String?,
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

    };*/