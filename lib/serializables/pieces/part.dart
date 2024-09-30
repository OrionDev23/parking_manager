import 'package:json_annotation/json_annotation.dart';
import 'package:parc_oto/serializables/pieces/variation.dart';
import '../../utilities/profil_beautifier.dart';
import '../parc_oto_serializable.dart';

part 'part.g.dart';

List<String>units=[
  'unit',
  'gram',
  'kgram',
  'litre',
  'metre',
  'smetre',
  'volume',
  'heure',
  'jour',
];
@JsonSerializable()
class VehiclePart extends ParcOtoDefault{

  String name;
  String? description;
  int unitType;
  double? price;
  String? sku;
  String? barcode;
  String? fournisseurID;
  String? fournisseurName;
  String? brandID;
  String? brandName;
  String? categoryID;
  String? categoryName;
  List<String>?selectedOptions;
  List<String>?selectedOptionsNames;
  
  String? search;

  @JsonKey(toJson: listToJsonString,fromJson: variationsFromList)
  List<Variation>? variations;

  VehiclePart({required super.id,super.createdAt,super.updatedAt,required
  this.name,this.description,this.sku,this.variations,this.barcode,this
      .selectedOptions,this.price,this.brandName,this.fournisseurID,this
      .brandID,this.categoryID,this.categoryName,this.fournisseurName,this
      .selectedOptionsNames,this.unitType=0}){
    search="$name $description ${units[unitType]} $sku $barcode "
        "$fournisseurName $categoryName $brandName ${listToString
      (selectedOptionsNames)} ${listToString(variations?.map((e)=>e.name)
            .toList())}";
  }

  factory VehiclePart.fromJson(Map<String, dynamic> json) =>
      _$VehiclePartFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$VehiclePartToJson(this);

}