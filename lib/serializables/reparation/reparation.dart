import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';

import 'designation.dart';
import 'entretien_vehicle.dart';
import 'etat_vehicle.dart';

part 'reparation.g.dart';

@JsonSerializable()
class Reparation extends ParcOtoDefault {
  String? vehicule;

  String? vehiculemat;

  String? etat;

  int? type;
  String? prestataire;
  String? prestatairenom;

  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJsonNonNull)
  DateTime date;

  int numero;

  int? gaz;

  int? kilometrage;

  String? nmoteur;

  String? nchassi;

  String? couleur;

  String? remarque;

  String? marque;

  @JsonKey(toJson: designationsToJson, fromJson: designationsFromJson)
  List<Designation>? designations;

  @JsonKey(toJson: etatVehiculeToJson, fromJson: etatFromJson)
  EtatVehicle? etatActuel;

  @JsonKey(toJson: entretienToJson, fromJson: entretienFromJson)
  EntretienVehicle? entretien;

  int? anneeUtil;
  String? modele;

  Reparation(
      {required super.id,
      super.createdAt,
      super.updatedAt,
      required this.numero,
      this.anneeUtil,
      this.couleur,
      required this.date,
      this.designations,
      this.entretien,
      this.etat,
      this.etatActuel,
      this.gaz,
      this.kilometrage,
      this.modele,
      this.nchassi,
      this.nmoteur,
      this.prestataire,
      this.prestatairenom,
      this.remarque,
      this.type,
      this.vehicule,
      this.vehiculemat,
      this.marque});

  factory Reparation.fromJson(Map<String, dynamic> json) =>
      _$ReparationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ReparationToJson(this);

  double getPrixTTC() {
    if (designations == null) {
      return 0;
    }
    double result = 0;

    for (int i = 0; i < designations!.length; i++) {
      result += (designations![i].prix +
              (designations![i].prix * designations![i].tva) / 100) *
          designations![i].qte;
    }
    return result;
  }

  double getPrixTotal() {
    if (designations == null) {
      return 0;
    }
    double result = 0;

    for (int i = 0; i < designations!.length; i++) {
      result += designations![i].prix * designations![i].qte;
    }
    return result;
  }

  double getPrixTva() {
    if (designations == null) {
      return 0;
    }
    double result = 0;

    for (int i = 0; i < designations!.length; i++) {
      result += ((designations![i].prix * designations![i].tva) / 100) *
          designations![i].qte;
    }
    return result;
  }
}
