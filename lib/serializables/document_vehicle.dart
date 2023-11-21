import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/vehicle.dart';

import '../providers/client_database.dart';

part 'document_vehicle.g.dart';

@JsonSerializable()
class DocumentVehicle{

  @JsonKey(includeToJson: false,name: '\$id')

  String id;
  int? dateExpiration;
  String nom;

  Vehicle? vehicle;

  DocumentVehicle({required this.id,required this.nom,this.vehicle,this.dateExpiration});

  factory DocumentVehicle.fromJson(Map<String, dynamic> json) => _$DocumentVehicleFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentVehicleToJson(this);

}