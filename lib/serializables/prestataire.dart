import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import '../utilities/profil_beautifier.dart';


part 'prestataire.g.dart';
@JsonSerializable()
class Prestataire extends ParcOtoDefault{

  String nom;
  String adresse;
  String? telephone;
  String? nif;
  String? nis;
  String? rc;
  String? art;
  String? email;
  String? search;
  Prestataire({required super.id,super.createdAt,super.updatedAt,
    required this.nom,required this.adresse,this.email,
    this.telephone,this.search,this.art,this.nif,
    this.nis,this.rc});


  factory Prestataire.fromJson(Map<String, dynamic> json) => _$PrestataireFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PrestataireToJson(this);

}