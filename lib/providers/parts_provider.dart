import 'package:flutter/foundation.dart' hide Category;
import 'package:parc_oto/providers/client_database.dart';
import '../screens/sidemenu/sidemenu.dart';
import '../serializables/pieces/brand.dart';
import '../serializables/pieces/category.dart';
import '../serializables/pieces/option.dart';

class PartsProvider extends ChangeNotifier{

  static Map<String,Category> categories={};
  static Map<String,Brand> brands={};
  static Map<String,Option> options={};

  static bool errorCategories=true;
  static bool errorBrands=true;
  static bool errorOptions=true;
  static bool downloadingCategories=false;
  static bool downloadingBrands=false;
  static bool downloadingOptions=false;
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



  Future<void> downloadAllCategories() async {
    if(!downloadingCategories){
      if (PanesListState.signedIn.value) {

        await DatabaseGetter().listDocuments(categoriesID).then((s){
          for(int i=0;i<s.length;i++){
            categories[s[i].$id]=Category.fromJson(s[i].data);
          }
          errorCategories=false;
        }).catchError(
                (s){
              errorCategories=true;
            });
      } else {
        errorCategories = true;
      }
    }
  }

  Future<void> downloadAllBrands() async {
    if(!downloadingBrands){
      if (PanesListState.signedIn.value) {

        await DatabaseGetter().listDocuments(brandsID).then((s){
          for(int i=0;i<s.length;i++){
            brands[s[i].$id]=Brand.fromJson(s[i].data);
          }
          errorBrands=false;
        }).catchError(
                (s){
              errorBrands=true;
            });
      } else {
        errorBrands = true;
      }
    }
  }

  Future<void> downloadAllOptions() async {
    if(!downloadingOptions){
      if (PanesListState.signedIn.value) {

        await DatabaseGetter().listDocuments(optionsID).then((s){
          for(int i=0;i<s.length;i++){
            options[s[i].$id]=Option.fromJson(s[i].data);
          }
          errorOptions=false;
        }).catchError(
                (s){
              errorOptions=true;
            });
      } else {
        errorOptions = true;
      }
    }
  }
}