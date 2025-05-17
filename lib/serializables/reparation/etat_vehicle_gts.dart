import 'package:json_annotation/json_annotation.dart';

import 'etat_vehicle.dart';

part "etat_vehicle_gts.g.dart";
@JsonSerializable()

class EtatVehicleGTS extends EtatVehicleInterface{
  //Cabine
  bool intCab;
  bool balEss;
  bool parBrise;
  bool retroVis;
  String cabineCom;

  //Exterieur avant
  bool pareChoAv;
  bool optiqueSign;
  bool plaqueAvant;
  bool marchePieds;
  bool rouePnAvant;
  bool reservoir;
  String exterieurAvCom;

  //Exterieur arriere
  bool calottes=false;
  bool pareChoAr=false;
  bool plaqueArriere=false;
  bool feuxSign;
  bool rouePnArriere;
  bool rouesecours;
  String exterieurArCom;

  bool showOnList;

  EtatVehicleGTS({this.intCab=false,this.balEss=false,this.parBrise=false,this.retroVis=false,this.marchePieds=false,
  this.pareChoAv=false,this.optiqueSign=false,this.plaqueAvant=false,this.rouePnAvant=false,this.reservoir=false,
    this.calottes=false,this.pareChoAr=false,this.plaqueArriere=false,
  this.feuxSign=false,this.rouePnArriere=false,this.rouesecours=false,this.exterieurArCom="",this.exterieurAvCom="",this.cabineCom="",this.showOnList=true});

  factory EtatVehicleGTS.fromJson(Map<String, dynamic> json) =>
      _$EtatVehicleGTSFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EtatVehicleGTSToJson(this);

}