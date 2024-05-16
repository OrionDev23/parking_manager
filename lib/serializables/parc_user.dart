import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../utilities/profil_beautifier.dart';

part 'parc_user.g.dart';

@JsonSerializable()
class ParcUser extends ParcOtoDefault {
  final String? name;
  final String email;
  final String? tel;

  final String? avatar;

  ParcUser({
    required super.id,
    super.createdAt,
    super.updatedAt,
    this.avatar,
    this.name,
    required this.email,
    this.tel,
  });

  factory ParcUser.fromJson(Map<String, dynamic> json) =>
      _$ParcUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ParcUserToJson(this);


}
