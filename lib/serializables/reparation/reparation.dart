import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';

import 'designation.dart';
import 'entretien_vehicle.dart';
part 'reparation.g.dart';

@JsonSerializable()
class Reparation extends ParcOtoDefault {
  String? vehicule;

  String? vehiculemat;

  String ficheReception;

  int ficheReceptionNumber;

  int? etat;

  String? prestataire;
  String? prestatairenom;

  @JsonKey(toJson: entretienToJson, fromJson: entretienFromJson)
  EntretienVehicle? entretien;

  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJsonNonNull)
  DateTime date;

  int numero;

  String? nchassi;


  String? remarque;

  @JsonKey(toJson: designationsToJson, fromJson: designationsFromJson)
  List<Designation>? designations;

  Reparation(
      {required super.id,
      super.createdAt,
      super.updatedAt,
        required this.ficheReception,
        required this.ficheReceptionNumber,
      required this.numero,
      required this.date,
      this.designations,
      this.etat,
      this.nchassi,
      this.prestataire,
      this.prestatairenom,
        this.entretien,
      this.remarque,
      this.vehicule,
      this.vehiculemat,
      });

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
