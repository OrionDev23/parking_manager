import 'package:json_annotation/json_annotation.dart';
import '../parc_oto_serializable.dart';

part 'part.g.dart';

List<String>units=[
  'unit',
  'gram',
  'kgram',
  'litre',
  'metre',
  'smetre',
  'volume',
  'heure',
  'jour',
];
@JsonSerializable()
class VehiclePart extends ParcOtoDefault{



  VehiclePart({required super.id,super.createdAt,super.updatedAt});

  factory VehiclePart.fromJson(Map<String, dynamic> json) =>
      _$VehiclePartFromJson(json);

  Map<String, dynamic> toJson() => _$VehiclePartToJson(this);

}