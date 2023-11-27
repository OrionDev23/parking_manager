import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/serializables/parc_user.dart';

import '../utilities/profil_beautifier.dart';

part 'conducteur.g.dart';

@JsonSerializable()
class Conducteur extends ParcOtoDefault{


  String name;
  String prenom;
  String? search;
  String? email;

  String? telephone;
  String? adresse;

  @JsonKey(toJson: dateToIntJson,)
  DateTime? dateNaissance;

  String? createdBy;


  Conducteur({required this.name,required this.prenom,required super.id,this.createdBy,super.createdAt,super.updatedAt,this.search,this.adresse,this.email,this.dateNaissance,this.telephone});

  factory Conducteur.fromJson(Map<String, dynamic> json) => _$ConducteurFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ConducteurToJson(this);


}
