import 'package:flutter/foundation.dart' hide Category;
import 'package:get/get.dart';
import 'package:parc_oto/providers/client_database.dart';
import '../screens/sidemenu/sidemenu.dart';
import '../serializables/client.dart';
import '../serializables/pieces/brand.dart';
import '../serializables/pieces/category.dart';
import '../serializables/pieces/option.dart';
import '../serializables/pieces/part.dart';

class PartsProvider extends ChangeNotifier{

  static Map<String,Category> categories={};
  static Map<String,Brand> brands={};
  static Map<String,Option> options={};
  static Map<String,VehiclePart> parts={};
  static Map<String,Client> fournisseurs={};


  static bool errorCategories=true;
  static bool errorBrands=true;
  static bool errorOptions=true;
  static bool errorParts=true;
  static bool errorFournisseurs=true;
  static bool downloadingCategories=false;
  static bool downloadingBrands=false;
  static bool downloadingOptions=false;
  static bool downloadingParts=false;
  static bool downloadingFournisseurs=false;
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
        downloadingCategories=true;

        await DatabaseGetter().listDocuments(categoriesID).then((s){
          for(int i=0;i<s.length;i++){
            categories[s[i].$id]=Category.fromJson(s[i].data);
          }
          errorCategories=false;
          downloadingCategories=false;
        }).catchError(
                (s){
              errorCategories=true;
              downloadingCategories=false;

                });
      } else {
        errorCategories = true;
      }
    }
  }

  Future<void> downloadAllBrands() async {
    if(!downloadingBrands){
      if (PanesListState.signedIn.value) {
        downloadingBrands=true;
        await DatabaseGetter().listDocuments(brandsID).then((s){
          for(int i=0;i<s.length;i++){
            brands[s[i].$id]=Brand.fromJson(s[i].data);
          }
          errorBrands=false;
          downloadingBrands=false;
        }).catchError(
                (s){
              errorBrands=true;
              downloadingBrands=false;

                });
      } else {
        errorBrands = true;
      }
    }
  }

  Future<void> downloadAllOptions() async {
    if(!downloadingOptions){
      if (PanesListState.signedIn.value) {
        downloadingOptions=true;
        await DatabaseGetter().listDocuments(optionsID).then((s){
          for(int i=0;i<s.length;i++){
            options[s[i].$id]=Option.fromJson(s[i].data);
          }
          errorOptions=false;
          downloadingOptions=false;
        }).catchError(
                (s){
              errorOptions=true;
              downloadingOptions=false;

                });
      } else {
        errorOptions = true;
      }
    }
  }
  Future<void> downloadAllParts() async {
    if(!downloadingParts){
      if (PanesListState.signedIn.value) {
        downloadingParts=true;
        await DatabaseGetter().listDocuments(partsID).then((s){
          for(int i=0;i<s.length;i++){
            parts[s[i].$id]=VehiclePart.fromJson(s[i].data);
          }
          errorParts=false;
          downloadingParts=false;
        }).catchError(
                (s){
                  errorParts=true;
                  downloadingParts=false;

                });
      } else {
        errorParts = true;
      }
    }
  }
  Future<void> downloadAllFournisseurs() async {
    if(!downloadingFournisseurs){
      if (PanesListState.signedIn.value) {
        downloadingFournisseurs=true;
        await DatabaseGetter().listDocuments(fournsID).then((s){
          for(int i=0;i<s.length;i++){
            fournisseurs[s[i].$id]=Client.fromJson(s[i].data);
          }
          errorFournisseurs=false;
          downloadingFournisseurs=false;
        }).catchError(
                (s){
                  errorFournisseurs=true;
                  downloadingFournisseurs=false;
                });
      } else {
        errorFournisseurs = true;
      }
    }
  }


  Future<Client?> getFournisseur(String? id) async{
    if(id==null || id.isEmpty){
      return null;
    }
    else{
      if(fournisseurs.containsKey(id)){
        return fournisseurs[id];
      }
      else{
        var doc=await DatabaseGetter().getDocument(fournsID, id);
        if(doc!=null){
          return Client.fromJson(doc.data);
        }
        else{
          return null;
        }
      }
    }
  }
  Future<Brand?> getBrand(String? id) async{
    if(id==null || id.isEmpty){
      return null;
    }
    else{
      if(brands.containsKey(id)){
        return brands[id];
      }
      else{
        var doc=await DatabaseGetter().getDocument(brandsID, id);
        if(doc!=null){
          return Brand.fromJson(doc.data);
        }
        else{
          return null;
        }
      }
    }
  }
  Future<Category?> getCategory(String? id) async{
    if(id==null || id.isEmpty){
      return null;
    }
    else{
      if(categories.containsKey(id)){
        return categories[id];
      }
      else{
        var doc=await DatabaseGetter().getDocument(categoriesID, id);
        if(doc!=null){
          return Category.fromJson(doc.data);
        }
        else{
          return null;
        }
      }
    }
  }
  Future<Option?> getOption(String? id) async{
    if(id==null || id.isEmpty){
      return null;
    }
    else{
      if(options.containsKey(id)){
        return options[id];
      }
      else{
        var doc=await DatabaseGetter().getDocument(optionsID, id);
        if(doc!=null){
          return Option.fromJson(doc.data);
        }
        else{
          return null;
        }
      }
    }
  }
  Future<List<Option>?> getOptionsList(List<String>? ids) async{
    if(ids==null){
      return null;
    }
    else{
      List<Option> result=List.empty(growable: true);
      for(int i=0;i<ids.length;i++){
        var option=await getOption(ids[i]);
        result.addIf(option!=null,option!);
      }
      return result;
    }
  }
}