
import 'package:fluent_ui/fluent_ui.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/genre_vehicule.dart';
import 'package:parc_oto/serializables/marque.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/serializables/state.dart';

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


  Etat? etat;

  Vehicle({required this.matricule,required this.matriculeEtrang,this.wilaya,
    this.commune,this.date,
    this.adresse,this.quittance,this.numero,
    this.nom,this.prenom,this.profession,
    this.numeroSerie,this.type,this.anneeUtil,
    this.carrosserie,this.charegeUtile,this.daira,
    this.energie,this.genre,this.marque,
    this.matriculePrec, this.pays,this.placesAssises,
    this.poidsTotal, this.puissance, this.createdBy,this.etat
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  int compareTo(Vehicle vehicle) {

    return id!.compareTo(vehicle.id!);
  }
}


/*
*///GENERATED CODE - DO NOT MODIFY BY HAND
/*
part of 'vehicle.dart';
*/
// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************
/*
Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
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
  genre: json['genre'] == null
      ? null
      : GenreVehicle.fromJson(json['genre'] as Map<String, dynamic>),
  marque: json['marque'] == null
      ? null
      : Marque.fromJson(json['marque'] as Map<String, dynamic>),
  matriculePrec: json['matricule_prec'] as String?,
  pays: json['pays'] as String?,
  placesAssises: json['place_assises'] as int?,
  poidsTotal: json['poids_total'] as int?,
  puissance: json['puissance'] as int?,
  createdBy: json['user_creation'] == null
      ? null
      : ParcUser.fromJson(json['user_creation'] as Map<String, dynamic>),
  etat: json['etat'] == null
      ? null
      : Etat.fromJson(json['etat'] as Map<String, dynamic>),
)
  ..id = json[r'$id'] as String?
  ..dateCreation = DateTime.tryParse(json[r'$createdAt'])?.difference(ClientDatabase.ref).inMilliseconds.abs()
  ..dateModification = DateTime.tryParse(json[r'$updatedAt'])?.difference(ClientDatabase.ref).inMilliseconds.abs();


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
  'marque': instance.marque?.id,
  'genre': instance.genre?.id,
  'charge_utile': instance.charegeUtile,
  'poids_total': instance.poidsTotal,
  'place_assises': instance.placesAssises,
  'puissance': instance.puissance,
  'energie': instance.energie,
  'carrosserie': instance.carrosserie,
  'annee_util': instance.anneeUtil,
  'matricule_prec': instance.matriculePrec,
  'user_creation': instance.createdBy?.id,
  'pays': instance.pays,
  'etat': instance.etat?.id,
};

*/