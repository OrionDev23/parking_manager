import 'dart:io' as f;

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ImportAppartenance {
  final FilePickerResult file;
  final int type;
  ImportAppartenance({required this.file,required this.type});
  double progressLoadingFile = 0;

  List<String> result = [];
  Map<String, int> columnToRead = {};

  bool invalidFile = false;

  int invalidTables=0;

  Future<List<String>> loadFile() async {

    Uint8List? bytes = file.files.first.bytes;
    if (kIsWeb) {
      bytes = file.files.first.bytes;
    } else {
      bytes = await f.File(file.files.single.path!).readAsBytes();
    }
    if (bytes != null) {
      var excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        if (kDebugMode) {
          print('trying table $table');
        }
        if (isFileValid(excel, table)) {
          if (kDebugMode) {
            print('table $table is valid');
          }
          for (var row in excel.tables[table]!.rows) {
            switch(type){
              case 0:addFiliale(row);
              break;
              case 1:addDirection(row);
              break;
              case 2:addDepartment(row);
            }
          }
        } else {
          invalidTables ++;
          break;
        }
      }
      if(invalidTables==excel.tables.length){
        invalidFile=true;
      }
    }

    return result;
  }
  void addDepartment(List<Data?> data) {
    String? department =
    data[columnToRead['departement']!]?.value.toString()
        .trim();
    if(department!=null && department.isNotEmpty && !result.contains(department)){
      result.add(department);
    }
  }
  void addDirection(List<Data?> data) {
    String? direction =
    data[columnToRead['direction']!]?.value.toString()
        .trim();
    if(direction!=null && direction.isNotEmpty && !result.contains(direction)){
      result.add(direction);
    }
  }

  void addFiliale(List<Data?> data) {
    String? filiale =
    data[columnToRead['filiale']!]?.value.toString()
        .trim();
    if(filiale!=null && filiale.isNotEmpty&& !result.contains(filiale)){
      result.add(filiale);
    }
  }

  bool isFileValid(Excel excel, String table) {
    for (var row in excel.tables[table]!.rows) {
      for (var cell in row) {
        if (cell?.value != null) {
          switch (cell?.value) {
            case null:
              break;
            case FormulaCellValue():
              break;
            case IntCellValue():
              break;

            case DoubleCellValue():
              break;

            case DateCellValue():
              break;

            case TextCellValue():
              final value = cell!.value as TextCellValue;
              if (value.value.text?.toLowerCase().trim()=='departement' &&
          type==2) {
                columnToRead['departement'] = cell.columnIndex;
                return true;
              }
              if (value.value.text?.toLowerCase().trim()=='direction' &&type==1) {
                columnToRead['direction'] = cell.columnIndex;
                return true;
              }
              if (value.value.text!=null && value.value.text!.toLowerCase()
              .contains('appartenance') &&
                  type==0) {
                columnToRead['filiale'] = cell.columnIndex;
                return true;
              }

              break;
            case BoolCellValue():
              break;

            case TimeCellValue():
              break;

            case DateTimeCellValue():
              break;
          }
        }
      }
    }

    return false;
  }

}
