// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_vehicle_gts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EtatVehicleGTS _$EtatVehicleGTSFromJson(Map<String, dynamic> json) =>
    EtatVehicleGTS(
      intCab: json['intCab'] as bool? ?? false,
      balEss: json['balEss'] as bool? ?? false,
      parBrise: json['parBrise'] as bool? ?? false,
      retroVis: json['retroVis'] as bool? ?? false,
      cabineCom: json['cabineCom'] as String? ?? "",
      pareChoAv: json['pareChoAv'] as bool? ?? false,
      optiqueSign: json['optiqueSign'] as bool? ?? false,
      plaqueAvant: json['plaqueAvant'] as bool? ?? false,
      marchePieds: json['marchePieds'] as bool? ?? false,
      rouePnAvant: json['rouePnAvant'] as bool? ?? false,
      reser: json['reser'] as bool? ?? false,
      exterieurAvCom: json['exterieurAvCom'] as String? ?? "",
      calottes: json['calottes'] as bool? ?? false,
      pareChoAr: json['pareChoAr'] as bool? ?? false,
      plaqueArriere: json['plaqueArriere'] as bool? ?? false,
      feuxSign: json['feuxSign'] as bool? ?? false,
      rouePnArriere: json['rouePnArriere'] as bool? ?? false,
      roueSecours: json['roueSecours'] as bool? ?? false,
      exterieurArCom: json['exterieurArCom'] as String? ?? "",
      showOnList: json['showOnList'] as bool? ?? true,
    );

Map<String, dynamic> _$EtatVehicleGTSToJson(EtatVehicleGTS instance) =>
    <String, dynamic>{
      'intCab': instance.intCab,
      'balEss': instance.balEss,
      'parBrise': instance.parBrise,
      'retroVis': instance.retroVis,
      'cabineCom': instance.cabineCom,
      'pareChoAv': instance.pareChoAv,
      'optiqueSign': instance.optiqueSign,
      'plaqueAvant': instance.plaqueAvant,
      'marchePieds': instance.marchePieds,
      'rouePnAvant': instance.rouePnAvant,
      'reser': instance.reser,
      'exterieurAvCom': instance.exterieurAvCom,
      'calottes': instance.calottes,
      'pareChoAr': instance.pareChoAr,
      'plaqueArriere': instance.plaqueArriere,
      'feuxSign': instance.feuxSign,
      'rouePnArriere': instance.rouePnArriere,
      'roueSecours': instance.roueSecours,
      'exterieurArCom': instance.exterieurArCom,
      'showOnList': instance.showOnList,
    };
