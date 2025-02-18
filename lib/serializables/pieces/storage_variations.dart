import 'package:json_annotation/json_annotation.dart';
import 'variation.dart';

import '../../utilities/profil_beautifier.dart';

part 'storage_variations.g.dart';
@JsonSerializable()
class StorageVariation extends Variation{
  double qte;
  @JsonKey(toJson:timeToJsonN,fromJson: createdAtJson)
  DateTime? expirationDate;
  StorageVariation(  {
    required super.id,
    required super.name,
    required super.sku,
    super.optionValues,
    this.expirationDate,
    required this.qte,
  });


  factory StorageVariation.fromJson(Map<String, dynamic> json) =>
      _$StorageVariationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StorageVariationToJson(this);
}