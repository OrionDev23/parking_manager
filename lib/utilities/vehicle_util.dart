import 'package:easy_localization/easy_localization.dart';

class VehiclesUtilities{


  static getAnneeFromMatricule(String matricule){
    if(matricule.contains('-')){
      var s=matricule.split('-');
      if(s.length==3){
        int annee=int.parse(s[1]);
        annee=annee-(annee~/100)*100;

        if(annee+2000>DateTime.now().year){
          annee+=1900;
        }
        else{
          annee+=2000;
        }
        return annee;
      }
      else{
        return 0;
      }
    }
    else{
      return 0;
    }
  }


  static String getMarqueName(String marque){
    int m=int.tryParse(marque)??0;
    switch(m){
      case 1: return "Toyota";
      case 2: return "Peugeot";
      case 3: return "Renault";
      case 4: return "Kia";
      case 5: return "Dacia";
      case 6: return "Citroën";
      case 7: return "Fiat";
      case 8: return "Seat";
      case 9: return "BMW";
      case 10: return "Nissan";
      case 11: return "Volkswagen";
      case 12: return "Mercedes-Benz";
      case 13: return "Ford";
      case 14: return "Audi";
      case 15: return "Chevrolet";
      case 16: return "Daewoo";
      case 17: return "Honda";
      case 18: return "Hyundai";
      case 19: return "Land Rover";
      case 20: return "Mahindra";
      case 21: return "Mazda";
      case 22: return "Porsche";
      case 23: return "MINI";
      case 24: return "Rolls-Royce";
      case 25: return "Skoda";
      case 26: return "Ssangyong";
      case 27: return "Susuki";
      case 28: return "Tesla";
      case 29: return "Volvo";
      case 30: return "Opel";
      case 31: return "Alfa Romeo";
      case 32: return "Ferrari";
      case 33: return "Iveco";
      case 34: return "Lexus";
      case 35: return "Jeep";
      case 36: return "BAIC";
      case 37: return "Chery";
      case 38: return "Shacman";
      case 39: return "Higer Bus";
      case 40: return "Foton";
      case 41: return "JAC Motors";
      case 42: return "SNVI";
      case 43: return "Cadillac";
      case 44: return "Etrag";
      case 45: return "Sonalika";
      case 46: return "Massey Ferguson";
      case 47: return "Deutz-Fahr";
      case 48: return "Jaguar";
      case 49: return "AS-Motors";
      case 50: return "SYM";
      case 51: return "VMS";
      case 52: return "CYCMA";
      case 53: return "ORYX";
      case 54: return "Aston Martin";
      case 55: return "Austin";
      case 56: return "Bentley";
      case 57: return "Bugatti";
      case 58: return "Chrysler";
      case 59: return "Corvette";
      case 60: return "Lancia";
      case 61: return "Mitsubishi";
      case 62: return "Saab";
      case 63: return "Smart";
      case 64: return "Subaru";
      case 65: return "Yamaha";
      case 66: return "Ducati";
      case 67: return "KTM";
      case 68: return "Aprilia";
      case 69: return "Kawasaki";
      case 70: return "MV Agusta";
      default: return "N/A";
    }
  }

  static String getGenre(String matricule){
    if(matricule.contains('-')){
      var s=matricule.split('-');
      if(s.length==3){
        int type=int.parse(s[1]);
        type=type~/100;

        return getGenreFromNumber(type);
      }
      else{
        return getGenreFromNumber(1);
      }
    }
    return getGenreFromNumber(99);
  }
  static String getGenreFromNumber(int number){
    switch(number){
      case 0: return "presid".tr();
      case 1: return "vp".tr();
      case 2: return "camion".tr();
      case 3: return "camionnette".tr();
      case 4: return "autobus".tr();
      case 5: return "tracteur".tr();
      case 6: return "atracteur".tr();
      case 7: return "vspe".tr();
      case 8: return "remorque".tr();
      case 9: return "moto".tr();
      case 99: return "nonind".tr();
      default:return "vp".tr();
    }
  }
}
