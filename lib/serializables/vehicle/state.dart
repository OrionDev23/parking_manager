import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../../utilities/profil_beautifier.dart';
part 'state.g.dart';

@JsonSerializable()
class Etat extends ParcOtoDefault{
  int type;
  double? valeur;
  String? remarque;
  int? ordreNum;
  String? ordreID;
  String? createdBy;
  String vehicle;
  String vehicleMat;

  @JsonKey(toJson:dateToIntJson,fromJson: dateFromIntJson)
  DateTime? date;

  Etat({required super.id,super.createdAt,super.updatedAt,required this.type,this.valeur,this.remarque,this.createdBy,required this.vehicle,this.date,this.ordreID,this.ordreNum,required this.vehicleMat});
  factory Etat.fromJson(Map<String, dynamic> json) => _$EtatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EtatToJson(this);
}