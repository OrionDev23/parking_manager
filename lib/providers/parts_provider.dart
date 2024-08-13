import 'package:flutter/foundation.dart' hide Category;
import '../serializables/pieces/brand.dart';
import '../serializables/pieces/category.dart';
import '../serializables/pieces/option.dart';

class PartsProvider extends ChangeNotifier{

  static Map<String,Category> categories={};
  static Map<String,Brand> brands={};
  static Map<String,Option> options={};
  static String getUniqueCodeCategory() {
    int i = 0;
    while (true) {
      if (categories.containsKey("cat$i")) {
        i++;
      } else {
        break;
      }
    }
    return "cat$i";
  }

  static String getUniqueCodeBrand() {
    int i = 0;
    while (true) {
      if (brands.containsKey("bran$i")) {
        i++;
      } else {
        break;
      }
    }
    return "bran$i";
  }

  static String getUniqueCodeOption() {
    int i = 0;
    while (true) {
      if (options.containsKey("opt$i")) {
        i++;
      } else {
        break;
      }
    }
    return "opt$i";
  }
}