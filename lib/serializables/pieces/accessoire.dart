import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';

import '../../utilities/profil_beautifier.dart';

part 'accessoire.g.dart';

@JsonSerializable()
class Accesoire extends ParcOtoDefault{
  String designation;
  double prix;
  Accesoire({required this.designation,required this.prix,required super.id,
    super.createdAt,super.updatedAt});


}