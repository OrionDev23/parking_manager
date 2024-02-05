import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/providers/client_database.dart';
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
  String? direction;
  List<String>? vehicules;

  String matricule;

  Conducteur(
      {required this.name,
        required this.matricule,
      required this.prenom,
        this.vehicules,
      this.filliale,
      this.direction,
      this.etat = 0,
      this.etatactuel,
      required super.id,
      this.createdBy,
      super.createdAt,
      super.updatedAt,
      this.adresse,
      this.email,
        this.search,
      this.dateNaissance,
      this.telephone}){
      search='$name $prenom $direction $filliale ${ClientDatabase
          .getEtat(etat).tr()} $matricule $adresse $email ${dateNaissance?.toIso8601String()??''} $telephone';
  }

  factory Conducteur.fromJson(Map<String, dynamic> json) =>
      _$ConducteurFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ConducteurToJson(this);
}
