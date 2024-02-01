const marqueMax = 70;
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
    switch (m) {
      case 0:
        return 'nonind';
      case 1:
        return "Toyota";
      case 2:
        return "Peugeot";
      case 3:
        return "Renault";
      case 4:
        return "Kia";
      case 5:
        return "Dacia";
      case 6:
        return "Citroën";
      case 7:
        return "Fiat";
      case 8:
        return "Seat";
      case 9:
        return "BMW";
      case 10:
        return "Nissan";
      case 11:
        return "Volkswagen";
      case 12:
        return "Mercedes-Benz";
      case 13:
        return "Ford";
      case 14:
        return "Audi";
      case 15:
        return "Chevrolet";
      case 16:
        return "Daewoo";
      case 17:
        return "Honda";
      case 18:
        return "Hyundai";
      case 19:
        return "Land Rover";
      case 20:
        return "Mahindra";
      case 21:
        return "Mazda";
      case 22:
        return "Porsche";
      case 23:
        return "MINI";
      case 24:
        return "Rolls-Royce";
      case 25:
        return "Skoda";
      case 26:
        return "Ssangyong";
      case 27:
        return "Susuki";
      case 28:
        return "Tesla";
      case 29:
        return "Volvo";
      case 30:
        return "Opel";
      case 31:
        return "Alfa Romeo";
      case 32:
        return "Ferrari";
      case 33:
        return "Iveco";
      case 34:
        return "Lexus";
      case 35:
        return "Jeep";
      case 36:
        return "BAIC";
      case 37:
        return "Chery";
      case 38:
        return "Shacman";
      case 39:
        return "Higer Bus";
      case 40:
        return "Foton";
      case 41:
        return "JAC Motors";
      case 42:
        return "SNVI";
      case 43:
        return "Cadillac";
      case 44:
        return "Etrag";
      case 45:
        return "Sonalika";
      case 46:
        return "Massey Ferguson";
      case 47:
        return "Deutz-Fahr";
      case 48:
        return "Jaguar";
      case 49:
        return "AS-Motors";
      case 50:
        return "SYM";
      case 51:
        return "VMS";
      case 52:
        return "CYCMA";
      case 53:
        return "ORYX";
      case 54:
        return "Aston Martin";
      case 55:
        return "Austin";
      case 56:
        return "Bentley";
      case 57:
        return "Bugatti";
      case 58:
        return "Chrysler";
      case 59:
        return "Corvette";
      case 60:
        return "Lancia";
      case 61:
        return "Mitsubishi";
      case 62:
        return "Saab";
      case 63:
        return "Smart";
      case 64:
        return "Subaru";
      case 65:
        return "Yamaha";
      case 66:
        return "Ducati";
      case 67:
        return "KTM";
      case 68:
        return "Aprilia";
      case 69:
        return "Kawasaki";
      case 70:
        return "MV Agusta";
      default:
        return "N/A";
    }
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

  static String getTypeName(int type) {
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
      default:
        return 'gstate';
    }
  }
}
