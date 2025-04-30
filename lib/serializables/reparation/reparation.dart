import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';

import 'designation.dart';
import 'entretien_vehicle.dart';
part 'reparation.g.dart';

List<String> listEtats = ['waiting', 'processing', 'complete'];

@JsonSerializable()
class Reparation extends ParcOtoDefault {
  String? vehicule;

  String? vehiculemat;

  String? ficheReception;

  int? ficheReceptionNumber;

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

  String? search;
  bool mobile;

  @JsonKey(toJson: designationsToJson, fromJson: designationsFromJson)
  List<Designation>? designations;

  Reparation({
    required super.id,
    super.createdAt,
    super.updatedAt,
    this.ficheReception,
    this.ficheReceptionNumber,
    required this.numero,
    required this.date,
    this.designations,
    this.mobile = false,
    this.etat,
    this.nchassi,
    this.prestataire,
    this.prestatairenom,
    this.entretien,
    this.remarque,
    this.vehicule,
    this.vehiculemat,
  }) {
    search = "$id "
        "$ficheReceptionNumber "
        "$numero ${date.toIso8601String()}"
        " $prestatairenom $vehiculemat "
        "$remarque $nchassi ${listEtats[etat ?? 0]}";
  }

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
