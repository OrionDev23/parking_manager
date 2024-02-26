import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/prestataire.dart';

import '../utilities/profil_beautifier.dart';

part 'entreprise.g.dart';

@JsonSerializable()
class Entreprise extends Prestataire {
  String? logo;
  List<String>? filiales=[];
  List<String>? directions=[];

  List<String>? departments=[];

  Entreprise(
      {required super.id,
      required super.nom,
      required super.adresse,
      super.art,
      super.createdAt,
      super.description,
      super.email,
      super.nif,
      super.nis,
      super.rc,
      super.search,
      super.telephone,
      super.updatedAt,
      this.directions,
      this.filiales,
        this.departments,
      this.logo});

  factory Entreprise.fromJson(Map<String, dynamic> json) =>
      _$EntrepriseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EntrepriseToJson(this);
}
