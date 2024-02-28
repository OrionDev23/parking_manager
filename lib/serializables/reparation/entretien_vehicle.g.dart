// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entretien_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EntretienVehicle _$EntretienVehicleFromJson(Map<String, dynamic> json) =>
    EntretienVehicle(
      bougies: json['bougies'] as bool? ?? false,
      controleNiveaux: json['controleNiveaux'] as bool? ?? false,
      eclairage: json['eclairage'] as bool? ?? false,
      entretienClimatiseur: json['entretienClimatiseur'] as bool? ?? false,
      equilibrageRoues: json['equilibrageRoues'] as bool? ?? false,
      filtreAir: json['filtreAir'] as bool? ?? false,
      filtreCarburant: json['filtreCarburant'] as bool? ?? false,
      filtreHabitacle: json['filtreHabitacle'] as bool? ?? false,
      filtreHuile: json['filtreHuile'] as bool? ?? false,
      liquideFrein: json['liquideFrein'] as bool? ?? false,
      liquideRefroidissement: json['liquideRefroidissement'] as bool? ?? false,
      vidangeBoite: json['vidangeBoite'] as bool? ?? false,
      vidangeMoteur: json['vidangeMoteur'] as bool? ?? false,
      vidangePont: json['vidangePont'] as bool? ?? false,
      cire: json['cire'] as bool? ?? false,
      batterie: json['batterie'] as bool? ?? false,
      changerPneux: json['changerPneux'] as bool? ?? false,
      courroies: json['courroies'] as bool? ?? false,
      differentielAvAr: json['differentielAvAr'] as bool? ?? false,
      inspectionAmortisseurs: json['inspectionAmortisseurs'] as bool? ?? false,
      liquideTransmission: json['liquideTransmission'] as bool? ?? false,
      tuyaux: json['tuyaux'] as bool? ?? false,
      echappement: json['echappement'] as bool? ?? false,
      systemFreinage: json['systemFreinage'] as bool? ?? false,
      systemSuspension: json['systemSuspension'] as bool? ?? false,
      balaisEssuieGlace: json['balaisEssuieGlace'] as bool? ?? false,
      obd: json['obd'] as bool? ?? false,
    );

Map<String, dynamic> _$EntretienVehicleToJson(EntretienVehicle instance) =>
    <String, dynamic>{
      'vidangeMoteur': instance.vidangeMoteur,
      'vidangeBoite': instance.vidangeBoite,
      'vidangePont': instance.vidangePont,
      'filtreAir': instance.filtreAir,
      'filtreHuile': instance.filtreHuile,
      'filtreCarburant': instance.filtreCarburant,
      'filtreHabitacle': instance.filtreHabitacle,
      'liquideFrein': instance.liquideFrein,
      'liquideRefroidissement': instance.liquideRefroidissement,
      'liquideTransmission': instance.liquideTransmission,
      'systemSuspension': instance.systemSuspension,
      'systemFreinage': instance.systemFreinage,
      'inspectionAmortisseurs': instance.inspectionAmortisseurs,
      'bougies': instance.bougies,
      'equilibrageRoues': instance.equilibrageRoues,
      'controleNiveaux': instance.controleNiveaux,
      'changerPneux': instance.changerPneux,
      'differentielAvAr': instance.differentielAvAr,
      'tuyaux': instance.tuyaux,
      'echappement': instance.echappement,
      'batterie': instance.batterie,
      'courroies': instance.courroies,
      'eclairage': instance.eclairage,
      'cire': instance.cire,
      'entretienClimatiseur': instance.entretienClimatiseur,
      'balaisEssuieGlace': instance.balaisEssuieGlace,
      'obd': instance.obd,
    };
