import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/serializables/vehicle.dart';

import '../utilities/profil_beautifier.dart';
part 'state.g.dart';

@JsonSerializable()
class Etat extends ParcOtoDefault{


  int type;
  double? valeur;
  String? remarque;
  int? date;
  String? createdBy;
  String? vehicle;

  Etat({required super.id,super.createdAt,super.updatedAt,required this.type,this.valeur,this.remarque,this.date,this.createdBy,this.vehicle});
  factory Etat.fromJson(Map<String, dynamic> json) => _$EtatFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EtatToJson(this);
}