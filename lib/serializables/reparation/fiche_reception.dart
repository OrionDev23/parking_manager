import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';

import 'etat_vehicle.dart';

part 'fiche_reception.g.dart';

@JsonSerializable()
class FicheReception extends ParcOtoDefault {
  String? vehicule;

  String? vehiculemat;

  String? etat;

  int? type;

  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJsonNonNull)
  DateTime dateEntre;
  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJson)
  DateTime? dateSortie;

  int numero;

  int? gaz;

  int? kilometrage;

  String? nmoteur;

  String? nchassi;

  String? couleur;

  String? remarque;

  String? marque;

  String? nomConducteur;
  String? prenomConducteur;
  String? matriculeConducteur;

  List<int?> images;

  @JsonKey(toJson: etatVehiculeToJson, fromJson: etatFromJson)
  EtatVehicle? etatActuel;


  int? anneeUtil;
  String? modele;

  String? reparation;
  double? reparationCost;

  FicheReception(
      {required super.id,
        super.createdAt,
        super.updatedAt,
        required this.numero,
        this.anneeUtil,
        this.couleur,
        required this.dateEntre,
        this.dateSortie,
        this.etat,
        this.etatActuel,
        this.gaz,
        this.images=const [null,null,null,null],
        this.kilometrage,
        this.modele,
        this.nchassi,
        this.nmoteur,
        this.remarque,
        this.type,
        this.vehicule,
        this.vehiculemat,
        this.marque,
        this.matriculeConducteur,
        this.prenomConducteur,
        this.nomConducteur,
        this.reparation,this.reparationCost
      });

  factory FicheReception.fromJson(Map<String, dynamic> json) =>
      _$FicheReceptionJson(json);

  @override
  Map<String, dynamic> toJson() => _$FicheReceptionToJson(this);


}
