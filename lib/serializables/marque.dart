
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../utilities/profil_beautifier.dart';


part 'marque.g.dart';

@JsonSerializable()

class Marque extends ParcOtoDefault{
  String? nom;

  Marque({required super.id,this.nom,super.createdAt,super.updatedAt});

  factory Marque.fromJson(Map<String, dynamic> json) => _$MarqueFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  @override
  Map<String, dynamic> toJson() => _$MarqueToJson(this);
}