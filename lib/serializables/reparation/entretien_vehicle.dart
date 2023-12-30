
import 'package:json_annotation/json_annotation.dart';


part 'entretien_vehicle.g.dart';
@JsonSerializable()
class EntretienVehicle{
  bool vidangeMoteur = false;
  bool vidangeBoite = false;
  bool vidangePont = false;
  bool filtreAir = false;
  bool filtreHuile = false;
  bool filtreCarburant = false;
  bool filtreHabitacle = false;
  bool liquideFrein = false;
  bool liquideRefroidissement = false;
  bool equilibrageRoues = false;
  bool controleNiveaux = false;
  bool entretienClimatiseur = false;
  bool balaisEssuieGlace = false;
  bool eclairage = false;
  bool obd = false;
  bool bougies = false;

  EntretienVehicle({
    this.balaisEssuieGlace=false, this.bougies=false, this.controleNiveaux=false,
    this.eclairage=false,this.entretienClimatiseur=false,this.equilibrageRoues=false,
    this.filtreAir=false,this.filtreCarburant=false,this.filtreHabitacle=false,
    this.filtreHuile=false,this.liquideFrein=false,this.liquideRefroidissement=false,
    this.obd=false,this.vidangeBoite=false,this.vidangeMoteur=false,this.vidangePont=false
});

  factory EntretienVehicle.fromJson(Map<String, dynamic> json) => _$EntretienVehicleFromJson(json);

  Map<String, dynamic> toJson() => _$EntretienVehicleToJson(this);
}