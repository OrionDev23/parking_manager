
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import '../../utilities/profil_beautifier.dart';

part 'brand.g.dart';

@JsonSerializable()
class Brand extends ParcOtoDefault{
  String code;
  String name;
  String? search;
  Brand({required this.code,required this.name,super.createdAt,super
      .updatedAt,
    required super
      .id}){
    search="$code $name";
  }


  Map<String,dynamic> toJsonPDF(){
    return {
      'code':code,
      'dateCreat':createdAt?.toIso8601String(),
      'dateModif':updatedAt?.toIso8601String(),
      'name':name,
    };
  }
  factory Brand.fromJson(Map<String, dynamic> json) =>
      _$BrandFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BrandToJson(this);
}