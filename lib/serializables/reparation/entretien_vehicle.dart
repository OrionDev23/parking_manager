import 'package:json_annotation/json_annotation.dart';
part 'entretien_vehicle.g.dart';

@JsonSerializable()
class EntretienVehicle {
  bool vidangeMoteur = false;
  bool vidangeBoite = false;
  bool vidangePont = false;
  bool filtreAir = false;
  bool filtreHuile = false;
  bool filtreCarburant = false;
  bool filtreHabitacle = false;
  bool liquideFrein = false;
  bool liquideRefroidissement = false;
  bool liquideTransmission = false;
  bool systemSuspension=false;
  bool systemFreinage=false;
  bool inspectionAmortisseurs = false;
  bool bougies = false;
  bool equilibrageRoues = false;
  bool controleNiveaux = false;
  bool changerPneux = false;
  bool differentielAvAr = false;
  bool tuyaux=false;
  bool echappement=false;
  bool batterie = false;
  bool courroies = false;
  bool eclairage = false;
  bool cire = false;
  bool entretienClimatiseur = false;
  bool balaisEssuieGlace = false;
  bool obd = false;

  EntretienVehicle({
    this.bougies = false,
    this.controleNiveaux = false,
    this.eclairage = false,
    this.entretienClimatiseur = false,
    this.equilibrageRoues = false,
    this.filtreAir = false,
    this.filtreCarburant = false,
    this.filtreHabitacle = false,
    this.filtreHuile = false,
    this.liquideFrein = false,
    this.liquideRefroidissement = false,
    this.vidangeBoite = false,
    this.vidangeMoteur = false,
    this.vidangePont = false,
    this.cire = false,
    this.batterie = false,
    this.changerPneux = false,
    this.courroies = false,
    this.differentielAvAr = false,
    this.inspectionAmortisseurs = false,
    this.liquideTransmission = false,
    this.tuyaux=false,
    this.echappement=false,
    this.systemFreinage=false,
    this.systemSuspension=false,
    this.balaisEssuieGlace = false,
    this.obd = false,

  });

  factory EntretienVehicle.fromJson(Map<String, dynamic> json) =>
      _$EntretienVehicleFromJson(json);

  Map<String, dynamic> toJson() => _$EntretienVehicleToJson(this);
}
