import 'dart:convert';
import 'dart:io';

import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:universal_html/html.dart' as html;

class FileManipulation{

}

void saveThisFile(Uint8List file,String title,String extension,String mime)
async {
  if (DeviceType.android == Device.deviceType ||
      Device.deviceType == DeviceType.ios) {
    DocumentFileSavePlus().saveFile(file,
        '$title.$extension',
        mime);
  } else if (kIsWeb) {
    saveFileWeb(
        file,
        '$title.$extension');
  } else {
    String? path = await FilePicker.platform.saveFile(
      dialogTitle: "save".tr(),
      fileName: '$title.$extension',
      type: FileType.custom,
      allowedExtensions: [extension],
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

String jsonify(Map<String,dynamic> map){

  String result="";

  result="{";
  bool first=true;
  map.forEach((key, value) {
    if(!first){
      result='$result,';
    }
    if(value==null){
      result='$result "$key" : null';

    }

    else if(value is String){
        result='$result "$key":${jsonEncode(value.trim().replaceAll('\n', '\\n')
            .replaceAll('\t', '\\t'))}';
    }
    else if(value is List<String> ){
      String temp="[";
      bool f=true;
      for(int i=0;i<value.length;i++){
        if(!f){
          temp='$temp,';
        }
        temp='$temp ${jsonEncode(value[i].trim())}';
        if(f){
          f=false;
        }
      }

      temp="$temp ]";

      result='$result "$key":$temp';
    }
    else{
        result='$result "$key":$value';
    }

    if(first){
      first=false;
    }


  });
  result="$result }";
  return result;
}
