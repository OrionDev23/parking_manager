import 'package:json_annotation/json_annotation.dart';

part 'designation.g.dart';

@JsonSerializable()
class Designation {
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool selected = false;
  String designation;
  int qte = 1;

  double tva = 0;

  double prix = 0;

  Designation(
      {required this.designation, this.prix = 0, this.qte = 0, this.tva = 0});

  factory Designation.fromJson(Map<String, dynamic> json) =>
      _$DesignationFromJson(json);

  Map<String, dynamic> toJson() => _$DesignationToJson(this);

  double getTTC() {
    return (prix + (prix * tva / 100)) * qte;
  }
}
