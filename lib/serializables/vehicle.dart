
import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';
@JsonSerializable()
class Vehicle{

  bool selected=false;
  String? id;
  String matricule;
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

  Vehicle({required this.matricule,this.wilaya,
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