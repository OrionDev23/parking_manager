

import '../admin_parameters.dart';
import '../screens/entreprise/entreprise.dart';
import 'vehicle_brands.dart';

const marqueMax = 71;
const genreMax = 10;

class VehiclesUtilities {
  static Map<int, String>? marques;
  static Map<int, String>? genres;

  VehiclesUtilities() {
    if (marques == null) {
      marques = {};
      for (int i = 0; i < marqueMax; i++) {
        marques![i + 1] = getMarqueName((i + 1).toString());
      }
    }
    if (genres == null) {
      genres = {};
      for (int j = 0; j < genreMax; j++) {
        genres![j] = getGenreFromNumber(j);
      }
    }
  }

  static Future<List<int>> findMarque(String s) {
    List<int> results = List.empty(growable: true);
    VehiclesUtilities();
    marques!.forEach((key, value) {
      if (key == int.tryParse(s) ||
          value.toUpperCase().contains(s.toUpperCase())) {
        results.add(key);
      }
    });
    return Future.value(results);
  }

  static Future<List<int>> findGenres(String s) {
    List<int> results = List.empty(growable: true);
    VehiclesUtilities();
    genres!.forEach((key, value) {
      if (key == int.tryParse(s) ||
          value.toUpperCase().contains(s.toUpperCase())) {
        results.add(key);
      }
    });
    return Future.value(results);
  }

  static int getAnneeFromMatricule(String matricule) {
    if (matricule.contains('-')) {
      var s = matricule.split('-');
      if (s.length == 3) {
        int annee = int.parse(s[1]);
        annee = annee - (annee ~/ 100) * 100;

        if (annee + 2000 > DateTime.now().year) {
          annee += 1900;
        } else {
          annee += 2000;
        }
        return annee;
      } else {
        return 2023;
      }
    } else {
      return 2023;
    }
  }

  static String getMarqueName(String? marque) {
    int m = marque == null ? 0 : int.tryParse(marque) ?? 0;

    if(vehiculeBrands.length>m){
      return vehiculeBrands[m];
    }
    return "nind";
  }

  static int getGenreNumber(String? matricule){
    if(matricule!=null){
      if (matricule.contains('-')) {
        var s = matricule.split('-');
        if (s.length == 3) {
          int type = int.parse(s[1]);
          type = type ~/ 100;

          return type;
        } else {
          return 1;
        }
      }
    }

    return 99;
  }

  static String getGenre(String matricule) {
    if (matricule.contains('-')) {
      var s = matricule.split('-');
      if (s.length == 3) {
        int type = int.parse(s[1]);
        type = type ~/ 100;

        return getGenreFromNumber(type);
      } else {
        return getGenreFromNumber(1);
      }
    }
    return getGenreFromNumber(99);
  }

  static String getGenreFromNumber(int number) {
    switch (number) {
      case 0:
        return "presid";
      case 1:
        return "vp";
      case 2:
        return "camion";
      case 3:
        return "camionnette";
      case 4:
        return "autobus";
      case 5:
        return "tracteur";
      case 6:
        return "atracteur";
      case 7:
        return "vspe";
      case 8:
        return "remorque";
      case 9:
        return "moto";
      case 99:
        return "nonind";
      default:
        return "nonind";
    }
  }

  static String getEtatName(int type) {
    switch (type) {
      case 0:
        return 'gstate';
      case 1:
        return 'bstate';
      case 2:
        return 'rstate';
      case 3:
        return 'ostate';
      case 4:
        return 'restate';

      case 5:
        return "dispo";
      case 6:
        return "panne";
      case 7:
        return "enreparation";
      case 8:
        return "enmission";


      default:
        return conducteurEmploye?'gstate':'dispo';
    }
  }

  static String getPerimetre (int perimetre){
    switch(perimetre){
      case 0:return 'buisiness';
      case 1:return 'hors perimetre';
      case 2:return 'industrie';
      case 3:return 'auparking';
      case 4: return 'horsparking';
      default:return conducteurEmploye?'buisiness':'auparking';


    }
  }

  static String getAppartenance(String? appartenance){
    if(MyEntrepriseState.p!=null && appartenance!=null){
      for(int i=0;i<MyEntrepriseState.p!.filiales!.length;i++){
        if(MyEntrepriseState.p!.filiales![i].replaceAll(' ', '').toUpperCase
          ().contains(appartenance.replaceAll(' ', '').toUpperCase())){
          return MyEntrepriseState.p!.filiales![i];
        }
      }
    }


    return '';
  }
  static String getDirection(String? direction){
    if(MyEntrepriseState.p!=null && direction!=null){
      for(int i=0;i<MyEntrepriseState.p!.directions!.length;i++){
        if(MyEntrepriseState.p!.directions![i].replaceAll(' ', '').toUpperCase
          ().contains(direction.replaceAll(' ', '').toUpperCase())){
          return MyEntrepriseState.p!.directions![i];
        }
      }
    }


    return '';
  }

  static String getDepartment(String? department){
    if(MyEntrepriseState.p!=null && department!=null){
      for(int i=0;i<MyEntrepriseState.p!.departments!.length;i++){
        if(MyEntrepriseState.p!.departments![i].replaceAll(' ', '').toUpperCase
          ().contains(department.replaceAll(' ', '').toUpperCase())){
          return MyEntrepriseState.p!.departments![i];
        }
      }
    }


    return '';
  }
}
