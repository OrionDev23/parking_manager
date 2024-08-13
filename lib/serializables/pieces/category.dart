import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import '../../utilities/profil_beautifier.dart';

part 'category.g.dart';
@JsonSerializable()
class Category extends ParcOtoDefault{
  String code;
  String name;
  String? codeParent;
  Category({required this.code,this.codeParent,required this.name,
    required super.id,super.createdAt,super.updatedAt});


  Map<String,dynamic> toJsonPDF(){
    return {
      'code':code,
      'codeParent':codeParent,
      'dateCreat':createdAt?.toIso8601String(),
      'dateModif':updatedAt?.toIso8601String(),
      'name':name,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}