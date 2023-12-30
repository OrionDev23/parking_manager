// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entretien_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EntretienVehicle _$EntretienVehicleFromJson(Map<String, dynamic> json) =>
    EntretienVehicle(
      balaisEssuieGlace: json['balaisEssuieGlace'] as bool? ?? false,
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
      obd: json['obd'] as bool? ?? false,
      vidangeBoite: json['vidangeBoite'] as bool? ?? false,
      vidangeMoteur: json['vidangeMoteur'] as bool? ?? false,
      vidangePont: json['vidangePont'] as bool? ?? false,
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
      'equilibrageRoues': instance.equilibrageRoues,
      'controleNiveaux': instance.controleNiveaux,
      'entretienClimatiseur': instance.entretienClimatiseur,
      'balaisEssuieGlace': instance.balaisEssuieGlace,
      'eclairage': instance.eclairage,
      'obd': instance.obd,
      'bougies': instance.bougies,
    };
