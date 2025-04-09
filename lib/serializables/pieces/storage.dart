import 'package:json_annotation/json_annotation.dart';
import '../parc_oto_serializable.dart';
import 'storage_variations.dart';

import '../../utilities/profil_beautifier.dart';


part 'storage.g.dart';
@JsonSerializable()
class Storage extends ParcOtoDefault{

  final double qte;
  final String partID;
  final String pieceName;
  final String? fournisseurID;
  final String? fournisseurName;
  @JsonKey(toJson:timeToJsonN,fromJson: createdAtJson)
  final DateTime? expirationDate;
  @JsonKey(toJson: listToJsonString,)
  final List<StorageVariation>? variations;
  late final String? search;

  Storage({required super.id,super.createdAt,super.updatedAt,this.expirationDate,required this.qte,required this.partID,required this.pieceName,required this.fournisseurID,required this.fournisseurName,required this.variations}){
    search='$partID $pieceName $fournisseurName $fournisseurID  ${expirationDate?.toIso8601String()} ${listToJson(variations)}';
  }


  factory Storage.fromJson(Map<String, dynamic> json) =>
      _$StorageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StorageToJson(this);

}