import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_user.dart';
part 'state.g.dart';

@JsonSerializable()
class Etat {

  @JsonKey(includeToJson: false,name: '\$id')

  String id;
  int type;
  double? valeur;
  String? remarque;
  int? date;
  ParcUser? createdBy;

  Etat({required this.id,required this.type,this.valeur,this.remarque,this.date,this.createdBy});
  factory Etat.fromJson(Map<String, dynamic> json) => _$EtatFromJson(json);

  Map<String, dynamic> toJson() => _$EtatToJson(this);
}