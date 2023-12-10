
import 'package:json_annotation/json_annotation.dart';


part 'etat_vehicle.g.dart';
@JsonSerializable()
class EtatVehicle{

  bool showOnList=false;
  double avdp = 100;
  double avgp = 100;
  double ardp = 100;
  double argp = 100;

  bool parBriseAvf = false;
  bool parBriseAvc = false;
  bool parBriseAve = false;
  bool parBriseArf = false;
  bool parBriseArc = false;
  bool parBriseAre = false;

  bool phareG = false;
  bool phareD = false;

  bool feuAVD = false;
  bool feuAVG = false;
  bool feuARD = false;
  bool feuARG = false;

  bool aileAVD = false;
  bool aileAVG = false;
  bool aileARD = false;
  bool aileARG = false;

  bool pareChocAV = false;
  bool pareChocAR = false;

  bool porteAVD = false;
  bool porteAVG = false;
  bool porteARD = false;
  bool porteARG = false;

  bool toit = false;

  bool capot = false;

  bool coffre = false;

  bool siegeAVD = false;
  bool siegeAVG = false;
  bool siegeARD = false;
  bool siegeARG = false;
  bool calandre = false;

  EtatVehicle( {
    this.feuARG=false, this.avgp=100, this.avdp=100, this.phareG=false,
    this.feuAVG=false, this.feuAVD=false, this.phareD=false, this.aileARD=false,
    this.aileARG=false, this.aileAVD=false, this.aileAVG=false, this.ardp=100,
    this.argp=100, this.calandre=false, this.capot=false, this.coffre=false,
    this.feuARD=false, this.parBriseArc=false, this.parBriseAre=false,
    this.parBriseArf=false, this.parBriseAvc=false, this.parBriseAve=false,
    this.parBriseAvf=false, this.pareChocAR=false, this.pareChocAV=false,
    this.porteARD=false, this.porteARG=false, this.porteAVD=false,
    this.porteAVG=false, this.siegeARD=false, this.siegeARG=false,
    this.siegeAVD=false, this.siegeAVG=false, this.toit=false,this.showOnList=false
  });



  factory EtatVehicle.fromJson(Map<String, dynamic> json) => _$EtatVehicleFromJson(json);

  Map<String, dynamic> toJson() => _$EtatVehicleToJson(this);




}