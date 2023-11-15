
import 'package:json_annotation/json_annotation.dart';


part 'marque.g.dart';

@JsonSerializable()

class Marque{
  @JsonKey(includeToJson: false,name: '\$id')

  String id;
  String? nom;

  Marque({required this.id,this.nom});

  factory Marque.fromJson(Map<String, dynamic> json) => _$MarqueFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$MarqueToJson(this);
}