
import 'package:json_annotation/json_annotation.dart';

part 'parc_user.g.dart';

@JsonSerializable()
class ParcUser {
  final String? name;
  final String email;
  final int? datec;
  final int? datea;
  final int? datel;
  final String? tel;
  @JsonKey(includeToJson: false,name: '\$id')

  final String id;

  final String? avatar;

  ParcUser({this.avatar, this.name, required this.email, this.datec, this.datea, this.datel, this.tel, required this.id});


  factory ParcUser.fromJson(Map<String, dynamic> json) => _$ParcUserFromJson(json);
  Map<String, dynamic> toJson() => _$ParcUserToJson(this);

}