import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_user.dart';

import '../utilities/profil_beautifier.dart';

part 'conducteur.g.dart';

@JsonSerializable()
class Conducteur{

  @JsonKey(includeToJson: false,name: '\$id')
  String id;
  String name;
  String prenom;
  String? search;
  String? email;

  String? telephone;
  String? adresse;

  @JsonKey(toJson: dateToIntJson,)
  DateTime? dateNaissance;
  @JsonKey(toJson: userToJson,)

  ParcUser? createdBy;

  @JsonKey(includeToJson: false,name: '\$createdAt')
  DateTime? dateAjout;
  @JsonKey(includeToJson: false,name: '\$updatedAt')

  DateTime? dateModif;

  Conducteur({required this.name,required this.prenom,required this.id,this.search,this.adresse,this.createdBy,this.email,this.dateNaissance,this.telephone});

  factory Conducteur.fromJson(Map<String, dynamic> json) => _$ConducteurFromJson(json);
  Map<String, dynamic> toJson() => _$ConducteurToJson(this);


}
