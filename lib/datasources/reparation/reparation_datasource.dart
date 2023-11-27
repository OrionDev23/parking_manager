import 'package:flutter/src/material/data_table.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';

class ReparationDataSource extends ParcOtoDatasource{
  ReparationDataSource({required super.collectionID, required super.current});

  @override
  String deleteConfirmationMessage(c) {
    // TODO: implement deleteConfirmationMessage
    throw UnimplementedError();
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, dynamic> element) {
    // TODO: implement getCellsToShow
    throw UnimplementedError();
  }
  

}