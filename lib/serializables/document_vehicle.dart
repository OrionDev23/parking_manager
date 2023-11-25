import 'package:fluent_ui/fluent_ui.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/serializables/vehicle.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';


part 'document_vehicle.g.dart';

@JsonSerializable()
class DocumentVehicle{

  @JsonKey(includeToJson: false,name: '\$id')

  String id;

  @JsonKey(name:"date_expiration")
  int? dateExpiration;
  String nom;
  @JsonKey(toJson: vehiculeToJson)

  Vehicle? vehicle;
  @JsonKey(toJson: userToJson)
  ParcUser? createdBy;
  @JsonKey(includeToJson: false,name: '\$createdAt',fromJson: createdAtJson)
  DateTime? dateAjout;
  @JsonKey(includeToJson: false,name: '\$updatedAt',fromJson: updatedAtJson)
  DateTime? dateModif;
  @JsonKey(includeFromJson: false,includeToJson: false)
  FlyoutController controller=FlyoutController();
  DocumentVehicle({required this.id,required this.nom,this.vehicle,this.dateExpiration,this.createdBy,this.dateAjout,this.dateModif});

  factory DocumentVehicle.fromJson(Map<String, dynamic> json) => _$DocumentVehicleFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentVehicleToJson(this);

}