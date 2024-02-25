
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class List2Excel{
  List<Map<String, dynamic>> list;
  final List<String> keysToInclude;
  String title;

  List2Excel({required this.list,required this.keysToInclude,required this.title});

  void getExcel() async{
    final Workbook workbook = Workbook();

    final Worksheet sheet = workbook.worksheets[0];
    var r=prepareList();

    r.forEach((key, value) {
      sheet.importList(value, key, 1, false);
    });

    final Range range1 = sheet.getRangeByName('A1:A${keysToInclude.length+1}');

    range1.autoFitColumns();


// Save and dispose workbook.
    final List<int> bytes = workbook.saveAsStream();

    var folder=await FilePicker.platform.saveFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      fileName: '$title.xlsx'
    );
    if(folder!=null){
      File(folder).writeAsBytes(bytes);
    }
    workbook.dispose();
  }


  Map<int,List<dynamic>> prepareList(){
    Map<int,List<dynamic>> result={};
    result[1]=['N°'];

    for(int j=0;j<keysToInclude.length;j++){
      result[1]!.add(keysToInclude[j].tr());
    }
    for(int i=0;i<list.length;i++){
      result[i+2]=[i+1,];
      for(int k=0;k<keysToInclude.length;k++){
        result[i+2]!.add(list[i][keysToInclude[k]]);
      }
    }
    return result;
  }




}