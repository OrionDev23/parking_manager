
import 'dart:io';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:universal_html/html.dart' as html;
import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../pdf_generation/pdf_theming.dart';
class List2Excel{
  List<Map<String, dynamic>> list;
  final List<String> keysToInclude;
  String title;

  List2Excel({required this.list,required this.keysToInclude,required this.title});

  void getExcel() async{
    await PDFTheming().initLogosOnly();

    final Workbook workbook = Workbook();

    final Worksheet sheet = workbook.worksheets[0];
    var r=prepareList();


    sheet.pictures.addStream(1, 1, entrepriseLogo!.bytes)
      ..width=entrepriseLogo!.width!*100~/entrepriseLogo!.width!
      ..height=entrepriseLogo!.height!*100~/entrepriseLogo!.width!;
    sheet.getRangeByIndex(1, 4)
    ..setText(title)
    ..cellStyle.bold=true
    ..cellStyle.underline;
    r.forEach((key, value) {
      sheet.importList(value, key+2, 2, false);
    });
    for(int i=0;i<keysToInclude.length+1;i++){
      sheet.getRangeByIndex(3, i+2).cellStyle.backColor='#FFA500';
      sheet.getRangeByIndex(3, i+2).cellStyle.bold=true;
      sheet.getRangeByIndex(3, i+2).cellStyle.wrapText=true;
      sheet.autoFitColumn(i+2);
    }


    final List<int> bytes = workbook.saveAsStream();
    saveThisFile(Uint8List.fromList(bytes));
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
        if(keysToInclude[k]=='perimetre'){
          result[i+2]!.add(VehiclesUtilities.getPerimetre
            (list[i][keysToInclude[k]]).tr());
        }
        else if(keysToInclude[k]=='etatactuel'){
          result[i+2]!.add(VehiclesUtilities.getEtatName
            (list[i][keysToInclude[k]]).tr());
        }
        else if(keysToInclude[k]=='direction'){
          result[i+2]!.add(VehiclesUtilities.getDirection
            (list[i][keysToInclude[k]]));
        }
        else if(keysToInclude[k]=='appartenance'){
          result[i+2]!.add(VehiclesUtilities.getAppartenance
            (list[i][keysToInclude[k]]));
        }
        else{
          if(list[i][keysToInclude[k]]==null || list[i][keysToInclude[k]]
              .toString()=='null'){
            result[i+2]!.add('');
          }
          else{
            result[i+2]!.add(list[i][keysToInclude[k]]);

          }
        }

      }
    }
    return result;
  }



  void saveThisFile(Uint8List file,) async {
    if (DeviceType.android == Device.deviceType ||
        Device.deviceType == DeviceType.ios) {
      DocumentFileSavePlus().saveFile(file,
          '$title.xlsx',
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    } else if (kIsWeb) {
      saveFileWeb(
          file,
          '$title.xlsx');
    } else {
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: "save".tr(),
        fileName: '$title.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (path != null) {
        File f = File(path);
        f.writeAsBytes(file, mode: FileMode.write);
      }
    }
  }

  void saveFileWeb(Uint8List bytes, String name) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = name;
    html.document.body?.children.add(anchor);

// download
    anchor.click();

// cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }




}