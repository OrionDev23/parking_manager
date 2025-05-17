import 'package:json_annotation/json_annotation.dart';
import '../parc_oto_serializable.dart';
import '../../utilities/profil_beautifier.dart';

import 'entretien_vehicle.dart';
import 'etat_vehicle.dart';

part 'fiche_reception.g.dart';

@JsonSerializable()
class FicheReception extends ParcOtoDefault {
  String? vehicule;
  String? vehiculemat;
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
  String? search;
  String? nomConducteur;
  String? prenomConducteur;
  String? matriculeConducteur;
  List<int?> images;
  @JsonKey(toJson: etatVehiculeToJson, fromJson: etatFromJson)
  EtatVehicleInterface? etatActuel;
  @JsonKey(toJson: entretienToJson, fromJson: entretienFromJson)
  EntretienVehicle? entretien;
  int? anneeUtil;
  String? modele;
  String? reparation;
  int? reparationNumero;
  double? reparationCost;
  bool mobile;
  bool showImages;
  bool showEntretien;
  bool showEtat;
  FicheReception(
      {required super.id,
        super.createdAt,
        super.updatedAt,
        this.mobile=false,
        required this.numero,
        this.anneeUtil,
        this.couleur,
        required this.dateEntre,
        this.dateSortie,
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
        this.entretien,
        this.vehiculemat,
        this.marque,
        this.matriculeConducteur,
        this.prenomConducteur,
        this.nomConducteur,
        this.showImages=true,
        this.showEntretien=true,
        this.showEtat=true,
        this.reparation,this.reparationCost
      }){
    search="$id $numero $nomConducteur "
        "$prenomConducteur $reparationNumero $reparationCost"
        "$marque $vehiculemat $nchassi $nmoteur $remarque"
        " $modele $couleur ${dateEntre.toIso8601String() }"
        " ${dateSortie?.toIso8601String()} ";
  }

  factory FicheReception.fromJson(Map<String, dynamic> json) =>
      _$FicheReceptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FicheReceptionToJson(this);


}
