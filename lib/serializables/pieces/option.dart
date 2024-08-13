
import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/parc_oto_serializable.dart';
import '../../utilities/profil_beautifier.dart';

part 'option.g.dart';
@JsonSerializable()
class Option extends ParcOtoDefault{
  String code;
  String name;
  List<String>? values;
  String? search;
  Option({required this.code,this.values,required this.name,required
  super.id,super.createdAt,super.updatedAt}){
    search="$code $name ${listToString(values)}";
  }


  Map<String,dynamic> toJsonPDF(){
    return {
      'code':code,
      'v':values,
      'name':name,
      'dateCreat':createdAt?.toIso8601String(),
      'dateModif':updatedAt?.toIso8601String(),
    };
  }
  static List<String> getList(Map<String,dynamic> json){
    List<String> result =List.empty(growable: true);
    json.forEach((key, value) {
      result.add(key);
    });
    return result;
  }

  factory Option.fromJson(Map<String, dynamic> json) =>
      _$OptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$OptionToJson(this);


}