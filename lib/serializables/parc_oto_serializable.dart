import 'package:fluent_ui/fluent_ui.dart';
import 'package:json_annotation/json_annotation.dart';

import '../utilities/profil_beautifier.dart';
part 'parc_oto_serializable.g.dart';

@JsonSerializable()
class ParcOtoDefault {
  ParcOtoDefault({required this.id, this.updatedAt, this.createdAt});

  ParcOtoDefault.empty({this.id = '', this.updatedAt, this.createdAt});

  @JsonKey(includeToJson: false, includeFromJson: false)
  bool selected = false;

  @JsonKey(includeFromJson: false, includeToJson: false)
  FlyoutController controller = FlyoutController();

  @JsonKey(includeToJson: false, name: '\$id')
  String id;

  @JsonKey(includeToJson: false, name: '\$updatedAt', fromJson: updatedAtJson)
  DateTime? updatedAt;

  @JsonKey(includeToJson: false, name: '\$createdAt', fromJson: createdAtJson)
  DateTime? createdAt;

  factory ParcOtoDefault.fromJson(Map<String, dynamic> json) =>
      _$ParcOtoDefaultFromJson(json);

  Map<String, dynamic> toJson() => _$ParcOtoDefaultToJson(this);
}
