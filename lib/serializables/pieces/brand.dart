
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import '../../utilities/profil_beautifier.dart';

part 'brand.g.dart';

@JsonSerializable()
class Brand extends ParcOtoDefault{
  String code;
  String? pic;
  String name;
  Brand({required this.code,this.pic,required this.name,super.createdAt,super
      .updatedAt,
    required super
      .id});


  Map<String,dynamic> toJsonPDF(){
    return {
      'code':code,
      'dateCreat':createdAt?.toIso8601String(),
      'dateModif':updatedAt?.toIso8601String(),
      'name':name,
    };
  }

}