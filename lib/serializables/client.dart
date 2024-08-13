import 'package:json_annotation/json_annotation.dart';

import '../utilities/profil_beautifier.dart';
import 'parc_oto_serializable.dart';

part 'client.g.dart';

@JsonSerializable()
class Client extends ParcOtoDefault {
  String nom;
  String adresse;
  String? telephone;
  String? description;
  String? nif;
  String? nis;
  String? rc;
  String? art;
  String? email;
  String? search;

  Client(
      {required super.id,
      super.createdAt,
      super.updatedAt,
      this.description,
      required this.nom,
      required this.adresse,
      this.email,
      this.telephone,
      this.search,
      this.art,
      this.nif,
      this.nis,
      this.rc});

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ClientToJson(this);
}
