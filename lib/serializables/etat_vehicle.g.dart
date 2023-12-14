// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EtatVehicle _$EtatVehicleFromJson(Map<String, dynamic> json) => EtatVehicle(
      feuARG: json['feuARG'] as bool? ?? false,
      avgp: (json['avgp'] as num?)?.toDouble() ?? 100,
      avdp: (json['avdp'] as num?)?.toDouble() ?? 100,
      phareG: json['phareG'] as bool? ?? false,
      feuAVG: json['feuAVG'] as bool? ?? false,
      feuAVD: json['feuAVD'] as bool? ?? false,
      phareD: json['phareD'] as bool? ?? false,
      aileARD: json['aileARD'] as bool? ?? false,
      aileARG: json['aileARG'] as bool? ?? false,
      aileAVD: json['aileAVD'] as bool? ?? false,
      aileAVG: json['aileAVG'] as bool? ?? false,
      ardp: (json['ardp'] as num?)?.toDouble() ?? 100,
      argp: (json['argp'] as num?)?.toDouble() ?? 100,
      calandre: json['calandre'] as bool? ?? false,
      capot: json['capot'] as bool? ?? false,
      coffre: json['coffre'] as bool? ?? false,
      feuARD: json['feuARD'] as bool? ?? false,
      parBriseArc: json['parBriseArc'] as bool? ?? false,
      parBriseAre: json['parBriseAre'] as bool? ?? false,
      parBriseArf: json['parBriseArf'] as bool? ?? false,
      parBriseAvc: json['parBriseAvc'] as bool? ?? false,
      parBriseAve: json['parBriseAve'] as bool? ?? false,
      parBriseAvf: json['parBriseAvf'] as bool? ?? false,
      pareChocAR: json['pareChocAR'] as bool? ?? false,
      pareChocAV: json['pareChocAV'] as bool? ?? false,
      porteARD: json['porteARD'] as bool? ?? false,
      porteARG: json['porteARG'] as bool? ?? false,
      porteAVD: json['porteAVD'] as bool? ?? false,
      porteAVG: json['porteAVG'] as bool? ?? false,
      siegeARD: json['siegeARD'] as bool? ?? false,
      siegeARG: json['siegeARG'] as bool? ?? false,
      siegeAVD: json['siegeAVD'] as bool? ?? false,
      siegeAVG: json['siegeAVG'] as bool? ?? false,
      toit: json['toit'] as bool? ?? false,
      showOnList: json['showOnList'] as bool? ?? false,
    );

Map<String, dynamic> _$EtatVehicleToJson(EtatVehicle instance) =>
    <String, dynamic>{
      'avdp': instance.avdp,
      'avgp': instance.avgp,
      'ardp': instance.ardp,
      'argp': instance.argp,
      'parBriseAvf': instance.parBriseAvf,
      'parBriseAvc': instance.parBriseAvc,
      'parBriseAve': instance.parBriseAve,
      'parBriseArf': instance.parBriseArf,
      'parBriseArc': instance.parBriseArc,
      'parBriseAre': instance.parBriseAre,
      'phareG': instance.phareG,
      'phareD': instance.phareD,
      'feuAVD': instance.feuAVD,
      'feuAVG': instance.feuAVG,
      'feuARD': instance.feuARD,
      'feuARG': instance.feuARG,
      'aileAVD': instance.aileAVD,
      'aileAVG': instance.aileAVG,
      'aileARD': instance.aileARD,
      'aileARG': instance.aileARG,
      'pareChocAV': instance.pareChocAV,
      'pareChocAR': instance.pareChocAR,
      'porteAVD': instance.porteAVD,
      'porteAVG': instance.porteAVG,
      'porteARD': instance.porteARD,
      'porteARG': instance.porteARG,
      'toit': instance.toit,
      'capot': instance.capot,
      'coffre': instance.coffre,
      'calandre': instance.calandre,
      'siegeAVD': instance.siegeAVD,
      'siegeAVG': instance.siegeAVG,
      'siegeARD': instance.siegeARD,
      'siegeARG': instance.siegeARG,
      'showOnList': instance.showOnList,

    };
