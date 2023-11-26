import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
int _idPieceCounter=0;



class PieceJointe  {
  TextEditingController controller=TextEditingController();
  DateTime? expiration;
  String? nom;
  String? lien;
  File? fileSelected;
  bool selected;
  final int id = _idPieceCounter++;

  PieceJointe({this.nom, this.lien,this.fileSelected,this.selected=false,this.expiration,});

}

