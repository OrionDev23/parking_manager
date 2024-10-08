
import 'package:json_annotation/json_annotation.dart';
part 'variation.g.dart';

@JsonSerializable()
class Variation {
  String id;
  String name;
  String sku;
  @JsonKey(includeToJson: false,includeFromJson: false)
  bool selected=false;
  Map<String,dynamic>? optionValues;

  Variation({required this.id,required this.name,required this.sku,this
      .optionValues,});

  factory Variation.fromJson(Map<String, dynamic> json) =>
      _$VariationFromJson(json);

  Map<String, dynamic> toJson() => _$VariationToJson(this);
}