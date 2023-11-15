
import 'package:fluent_ui/fluent_ui.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/genre_vehicule.dart';
import 'package:parc_oto/serializables/marque.dart';
import 'package:parc_oto/serializables/parc_user.dart';

part 'vehicle.g.dart';
@JsonSerializable()
class Vehicle{
  @JsonKey(includeToJson: false,includeFromJson: false)
  bool selected=false;

  @JsonKey(includeFromJson: false,includeToJson: false)
  FlyoutController controller=FlyoutController();
  @JsonKey(includeToJson: false,name: '\$id')

  String? id;
  String matricule;
  @JsonKey(name: 'martricule_etrang')

  bool matriculeEtrang;
  int? wilaya;
  String? commune;
  String? daira;
  String? adresse;
  @JsonKey(includeToJson: false,name: '\$createdAt')

  int? dateCreation;
  @JsonKey(includeToJson: false,name: '\$updatedAt')

  int? dateModification;
  int? date;
  double? quittance;
  String? numero;
  String? nom;
  String? prenom;
  String? profession;

  @JsonKey(name: 'numero_serie')

  String? numeroSerie;
  String? type;
  Marque? marque;
  GenreVehicle? genre;
  @JsonKey(name: 'charge_utile')

  int? charegeUtile;
  @JsonKey(name: 'poids_total')

  int? poidsTotal;
  @JsonKey(name: 'place_assises')

  int? placesAssises;
  int? puissance;
  String? energie;
  String? carrosserie;
  @JsonKey(name: 'annee_util')

  int? anneeUtil;
  @JsonKey(name: 'matricule_prec')

  String? matriculePrec;
  @JsonKey(name: 'user_creation')

  ParcUser? createdBy;
  String? pays;

  Vehicle({required this.matricule,required this.matriculeEtrang,this.wilaya,
    this.commune,this.date,
    this.adresse,this.quittance,this.numero,
    this.nom,this.prenom,this.profession,
    this.numeroSerie,this.type,this.anneeUtil,
    this.carrosserie,this.charegeUtile,this.daira,
    this.energie,this.genre,this.marque,
    this.matriculePrec, this.pays,this.placesAssises,
    this.poidsTotal, this.puissance, this.createdBy,
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