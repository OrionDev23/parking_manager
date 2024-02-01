import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../../utilities/profil_beautifier.dart';
part 'genre_vehicule.g.dart';

@JsonSerializable()
class GenreVehicle extends ParcOtoDefault {
  String? name;

  String? createdBy;

  GenreVehicle(
      {required super.id,
      this.name,
      this.createdBy,
      super.createdAt,
      super.updatedAt});

  factory GenreVehicle.fromJson(Map<String, dynamic> json) =>
      _$GenreVehicleFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$GenreVehicleToJson(this);
}
