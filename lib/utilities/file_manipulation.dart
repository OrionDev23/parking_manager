import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';

class FileManipulation {}

Future<void> saveThisFile(
  Uint8List file,
  String title,
  String extension,
  String mime,
) async {
  final normalizedExtension =
      extension.startsWith('.') ? extension.substring(1) : extension;
  await FilePicker.saveFile(
    dialogTitle: "save".tr(),
    fileName: '$title.$normalizedExtension',
    bytes: file,
    mimeType: mime,
  );
}

String jsonify(Map<String, dynamic> map) {
  String result = "";

  result = "{";
  bool first = true;
  map.forEach((key, value) {
    if (!first) {
      result = '$result,';
    }
    if (value == null) {
      result = '$result "$key" : null';
    } else if (value is String) {
      result =
          '$result "$key":${jsonEncode(value.trim().replaceAll('\n', '\\n').replaceAll('\t', '\\t'))}';
    } else if (value is List<String>) {
      String temp = "[";
      bool f = true;
      for (int i = 0; i < value.length; i++) {
        if (!f) {
          temp = '$temp,';
        }
        temp = '$temp ${jsonEncode(value[i].trim())}';
        if (f) {
          f = false;
        }
      }

      temp = "$temp ]";

      result = '$result "$key":$temp';
    } else {
      result = '$result "$key":$value';
    }

    if (first) {
      first = false;
    }
  });
  result = "$result }";
  return result;
}
