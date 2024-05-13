import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';

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

  String? profession;

  bool service;
  @JsonKey(toJson: dateToIntJson, fromJson: dateFromIntJson)
  DateTime? dateNaissance;

  String? createdBy;
  String? etatactuel;
  int? etat;
  String? filliale;
  String? direction;

  String? departement;
  List<String>? vehicules=[];

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
        this.departement,
        this.profession,
        this.service=false,
      this.telephone}){
      search='$name $prenom ${VehiclesUtilities.getDepartment(departement)} '
          '${VehiclesUtilities.getDirection(direction)} ${VehiclesUtilities
          .getAppartenance(filliale)} ${DriverProvider
          .getEtat(etat).tr()} $matricule $adresse $email '
          '${dateNaissance?.toIso8601String()??''} $telephone $profession ${service?'service':'fonction'}';
  }

  factory Conducteur.fromJson(Map<String, dynamic> json) =>
      _$ConducteurFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ConducteurToJson(this);
}
