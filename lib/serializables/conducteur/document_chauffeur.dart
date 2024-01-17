import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';


part 'document_chauffeur.g.dart';

@JsonSerializable()
class DocumentChauffeur extends ParcOtoDefault{



  @JsonKey(name:"date_expiration",fromJson: dateFromIntJson,toJson: dateToIntJson)
  DateTime? dateExpiration;
  String nom;
  String? chauffeur;

  String? chauffeurNom;
  String? createdBy;

  DocumentChauffeur({required super.id,required this.nom,this.chauffeurNom,this.chauffeur,this.dateExpiration,this.createdBy,super.createdAt,super.updatedAt});

  factory DocumentChauffeur.fromJson(Map<String, dynamic> json) => _$DocumentChauffeurFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$DocumentChauffeurToJson(this);

}