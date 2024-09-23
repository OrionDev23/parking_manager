// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehiclePart _$VehiclePartFromJson(Map<String, dynamic> json) => VehiclePart(
      id: json[r'$id'] as String,
      createdAt: createdAtJson(json[r'$createdAt'] as String),
      updatedAt: updatedAtJson(json[r'$updatedAt'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      variations: variationsFromList(json['variations'] as List),
      barcode: json['barcode'] as String?,
      selectedOptions: (json['selectedOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      price: (json['price'] as num?)?.toDouble(),
      brandName: json['brandName'] as String?,
      fournisseurID: json['fournisseurID'] as String?,
      brandID: json['brandID'] as String?,
      categoryID: json['categoryID'] as String?,
      categoryName: json['categoryName'] as String?,
      fournisseurName: json['fournisseurName'] as String?,
      selectedOptionsNames: (json['selectedOptionsNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      unitType: (json['unitType'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VehiclePartToJson(VehiclePart instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'unitType': instance.unitType,
      'price': instance.price,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'fournisseurID': instance.fournisseurID,
      'fournisseurName': instance.fournisseurName,
      'brandID': instance.brandID,
      'brandName': instance.brandName,
      'categoryID': instance.categoryID,
      'categoryName': instance.categoryName,
      'selectedOptions': instance.selectedOptions,
      'selectedOptionsNames': instance.selectedOptionsNames,
      'variations': listToJson(instance.variations),
    };
