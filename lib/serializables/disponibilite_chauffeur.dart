import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import '../utilities/profil_beautifier.dart';

part 'disponibilite_chauffeur.g.dart';

@JsonSerializable()
class DisponibiliteChauffeur extends ParcOtoDefault{

  int type;
  String? chauffeur;
  String? createdBy;
  DisponibiliteChauffeur({required super.id,super.createdAt,super.updatedAt,required this.type,this.createdBy,this.chauffeur});
  factory DisponibiliteChauffeur.fromJson(Map<String, dynamic> json) => _$DisponibiliteChauffeurFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DisponibiliteChauffeurToJson(this);
}