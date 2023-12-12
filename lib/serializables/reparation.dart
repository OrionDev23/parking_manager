import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';

import 'designation.dart';
import 'entretien_vehicle.dart';
import 'etat_vehicle.dart';

part 'reparation.g.dart';

@JsonSerializable()
class Reparation extends ParcOtoDefault{

  String? vehicule;

  String? vehiculemat;

  String? etat;

  int? type;
  String? prestataire;
  String? prestatairenom;

  @JsonKey(toJson: dateToIntJson,fromJson: dateFromIntJsonNonNull)
  DateTime date;

  int numero;

  int? gaz;

  int? kilometrage;

  String? nmoteur;

  String? nchassi;

  String? couleur;

  String? remarque;

  @JsonKey(toJson: designationsToJson)
  List<Designation>? designations;


  EtatVehicle? etatActuel;

  EntretienVehicle? entretien;

  int? anneeUtil;
  String? modele;



  Reparation({required super.id,super.createdAt,super.updatedAt,
    required this.numero,this.anneeUtil,this.couleur,required this.date,
    this.designations,this.entretien,this.etat,this.etatActuel,this.gaz,
    this.kilometrage,this.modele,this.nchassi,this.nmoteur,this.prestataire,
    this.prestatairenom,this.remarque,this.type,this.vehicule,this.vehiculemat});


  factory Reparation.fromJson(Map<String, dynamic> json) => _$ReparationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ReparationToJson(this);
}