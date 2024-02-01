import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../../utilities/profil_beautifier.dart';

part 'conducteur.g.dart';

@JsonSerializable()
class Conducteur extends ParcOtoDefault {
  String name;
  String prenom;
  String? search;
  String? email;

  String? telephone;
  String? adresse;

  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJson)
  DateTime? dateNaissance;

  String? createdBy;

  String? etatactuel;
  int? etat;

  String? filliale;
  String? filliateNom;
  String? direction;
  String? directionNom;

  Conducteur(
      {required this.name,
      required this.prenom,
      this.filliateNom,
      this.filliale,
      this.directionNom,
      this.direction,
      this.etat = 0,
      this.etatactuel,
      required super.id,
      this.createdBy,
      super.createdAt,
      super.updatedAt,
      this.search,
      this.adresse,
      this.email,
      this.dateNaissance,
      this.telephone});

  factory Conducteur.fromJson(Map<String, dynamic> json) =>
      _$ConducteurFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ConducteurToJson(this);
}
