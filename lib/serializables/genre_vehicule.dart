import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_user.dart';


part 'genre_vehicule.g.dart';

@JsonSerializable()
class GenreVehicle{
  @JsonKey(includeToJson: false,name: '\$id')

  String id;
  String? name;
  ParcUser? user;

  GenreVehicle({required this.id,this.name,this.user});

  factory GenreVehicle.fromJson(Map<String, dynamic> json) => _$GenreVehicleFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$GenreVehicleToJson(this);

}