import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';

import '../serializables/vehicle.dart';

class VehiculesDataSource extends AsyncDataTableSource {
  VehiculesDataSource() {
    print('DessertDataSourceAsync created');
  }

  VehiculesDataSource.empty() {
    _empty = true;
    print('DessertDataSourceAsync.empty created');
  }

  VehiculesDataSource.error() {
    _errorCounter = 0;
    print('DessertDataSourceAsync.error created');
  }

  bool _empty = false;
  int? _errorCounter;


  final VehiculesWebService _repo = VehiculesWebService();

  int _sortColumn = 0;
  bool _sortAscending = true;

  void sort(int column, bool ascending) {
    _sortColumn = column;
    _sortAscending = ascending;
    refreshDatasource();
  }

  Future<int> getTotalRecords() {
    return Future<int>.delayed(
        const Duration(milliseconds: 0), () => _empty ? 0 : _vehicles.length);
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    print('getRows($startIndex, $count)');
    if (_errorCounter != null) {
      _errorCounter = _errorCounter! + 1;

      if (_errorCounter! % 2 == 1) {
        await Future.delayed(const Duration(milliseconds: 1000));
        throw 'Error #${((_errorCounter! - 1) / 2).round() + 1} has occured';
      }
    }

    final format = NumberFormat.decimalPercentPattern(
      locale: 'fr',
      decimalDigits: 0,
    );
    assert(startIndex >= 0);

    // List returned will be empty is there're fewer items than startingAt
    var x = _empty
        ? await Future.delayed(const Duration(milliseconds: 2000),
            () => VehiculesWebServiceResponse(0, []))
        : await _repo.getData(
        startIndex, count,  _sortColumn, _sortAscending);

    var r = AsyncRowsResponse(
        x.totalRecords,
        x.data.map((vehicle) {
          return DataRow(
            key: ValueKey<String>(vehicle.id!),
            selected: vehicle.selected,
            onSelectChanged: (value) {
              if (value != null) {
                setRowSelection(ValueKey<String>(vehicle.id!), value);
              }
            },
            cells: [
              DataCell(Text(vehicle.id!)),
              DataCell(Text(vehicle.matricule)),
              DataCell(Text(vehicle.marque??'')),
              DataCell(Text(vehicle.type??'')),
              DataCell(Text(vehicle.anneeUtil??(VehiclesUtilities.getAnneeFromMatricule(vehicle.matricule) == 0?'NA':VehiclesUtilities.getAnneeFromMatricule(vehicle.matricule)))),
              DataCell(Text('${vehicle.dateCreation}')),
              DataCell(Text('${vehicle.dateModification}')),
              const DataCell(Icon(Icons.more_vert_sharp)),
            ],
          );
        }).toList());

    return r;
  }
}

class VehiculesWebServiceResponse {
  VehiculesWebServiceResponse(this.totalRecords, this.data);

  /// THe total ammount of records on the server, e.g. 100
  final int totalRecords;

  /// One page, e.g. 10 reocrds
  final List<Vehicle> data;
}

class VehiculesWebService {
  int Function(Vehicle, Vehicle)? _getComparisonFunction(
      int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      //id
      case 0:
        return (Vehicle d1, Vehicle d2) => coef * d1.id!.compareTo(d2.id!);
        //matricule
        case 1:
        return (Vehicle d1, Vehicle d2) => coef * d1.matricule.compareTo(d2.matricule);
        //marque
        case 2:
          return (Vehicle d1, Vehicle d2) {
            if(d1.marque==null){
              return -1;
            }
            else if(d2.marque==null){
              return 1;
            }
            else{
              return coef * d1.marque!.compareTo(d2.marque!);
            }
          };
        //type
      case 3:
        return (Vehicle d1, Vehicle d2) {
          if(d1.type==null){
            return -1;
          }
          else if(d2.type==null){
            return 1;
          }
          else{
            return coef * d1.type!.compareTo(d2.type!);
          }
        };
        //annee
      case 4:
        return (Vehicle d1, Vehicle d2) {
          int annee1=d1.anneeUtil??VehiclesUtilities.getAnneeFromMatricule(d1.matricule);
          int annee2=d2.anneeUtil??VehiclesUtilities.getAnneeFromMatricule(d2.matricule);

            return coef * annee1.compareTo(annee2);
        };
        //dateAjout
      case 5:
        return (Vehicle d1, Vehicle d2) => coef * d1.dateCreation!.compareTo(d2.dateCreation!);
      //date modif
        case 6:
        return (Vehicle d1, Vehicle d2) => coef * d1.dateModification!.compareTo(d2.dateModification!);
    }

    return null;
  }

  Future<VehiculesWebServiceResponse> getData(int startingAt, int count,int sortedBy, bool sortedAsc) async {
    return Future.delayed(
        Duration(
            milliseconds: startingAt == 0
                ? 2650
                : startingAt < 20
                ? 2000
                : 400), () {
      var result = _vehicles;

      result.sort(_getComparisonFunction(sortedBy, sortedAsc));
      return VehiculesWebServiceResponse(
          result.length, result.skip(startingAt).take(count).toList());
    });
  }
}

int _selectedCount = 0;

List<Vehicle> _vehicles = List.empty();

_showSnackbar(BuildContext context, String text, [Color? color]) {
  snackBar(context,content: Text(text),duration: const Duration(seconds: 1),backgroundColor: color);

}