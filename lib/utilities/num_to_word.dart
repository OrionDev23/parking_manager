class NumToWord {}

String letter(int num, {bool zero = false}) {
  switch (num) {
    case 1:
      return 'un';
    case 2:
      return 'deux';
    case 3:
      return 'trois';
    case 4:
      return 'quatre';
    case 5:
      return 'cinq';
    case 6:
      return 'six';
    case 7:
      return 'sept';
    case 8:
      return 'huit';
    case 9:
      return 'neuf';
    case 10:
      return 'dix';
    case 11:
      return 'onze';
    case 12:
      return 'douze';
    case 13:
      return 'treize';
    case 14:
      return 'quatorze';
    case 15:
      return 'quinze';
    case 16:
      return 'seize';
    case 17:
      return 'dix sept';
    case 18:
      return 'dix huit';
    case 19:
      return 'dix neuf';
    case 20:
      return "vingt";
    case 30:
      return "trente";
    case 40:
      return "quarante";
    case 50:
      return "cinquante";
    case 60:
      return "soixante";
    case 70:
      return "soixante dix";
    case 80:
      return "quatre vingt";
    case 90:
      return "quatre vingt dix";
    case 0:
      if (zero) {
        return 'zéro';
      } else {
        return '';
      }
    default:
      return 'un';
  }
}

String numToLettersWithoutZero(int nb) {
  return numToLetters(nb, showZero: nb.toString().length == 1);
}

String numToLetters(int nb, {bool showZero = true}) {
  String numberToLetter = '';
  int quotient = 0;
  int reste = 0;

  var n = nb.toString().length;
  switch (n) {
    case 1:
      numberToLetter = letter(nb, zero: showZero);
      break;
    case 2:
      if (nb > 19) {
        quotient = (nb / 10).floor();
        reste = nb % 10;
        if (nb < 71 || (nb > 79 && nb < 91)) {
          if (reste == 0) {
            numberToLetter = letter(quotient * 10, zero: showZero);
          }
          if (reste == 1) {
            numberToLetter =
                "${letter(quotient * 10, zero: showZero)} et ${letter(reste, zero: showZero)}";
          }
          if (reste > 1) {
            numberToLetter =
                "${letter(quotient * 10, zero: showZero)} ${letter(reste, zero: showZero)}";
          }
        } else {
          numberToLetter =
              "${letter((quotient - 1) * 10, zero: showZero)} ${letter(10 + reste, zero: showZero)}";
        }
      } else {
        numberToLetter = letter(nb, zero: showZero);
      }
      break;
    case 3:
      quotient = (nb / 100).floor();
      reste = nb % 100;
      if (quotient == 1 && reste == 0) numberToLetter = "cent";
      if (quotient == 1 && reste != 0) {
        numberToLetter = "cent ${numToLetters(reste, showZero: showZero)}";
      }
      if (quotient > 1 && reste == 0) {
        numberToLetter = "${letter(quotient, zero: showZero)} cent";
      }
      if (quotient > 1 && reste != 0) {
        numberToLetter =
            "${letter(quotient, zero: showZero)} cent ${numToLetters(reste, showZero: showZero)}";
      }
      break;
    case 4:
    case 5:
    case 6:
      quotient = (nb / 1000).floor();
      reste = nb - quotient * 1000;
      if (quotient == 1 && reste == 0) numberToLetter = "mille";
      if (quotient == 1 && reste != 0) {
        numberToLetter = "mille ${numToLetters(reste, showZero: showZero)}";
      }
      if (quotient > 1 && reste == 0) {
        numberToLetter = "${numToLetters(quotient, showZero: showZero)} mille";
      }
      if (quotient > 1 && reste != 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} mille ${numToLetters(reste, showZero: showZero)}";
      }
      break;
    case 7:
    case 8:
    case 9:
      quotient = (nb / 1000000).floor();
      reste = nb % 1000000;
      if (quotient == 1 && reste == 0) numberToLetter = "un million";
      if (quotient == 1 && reste != 0) {
        numberToLetter =
            "un million ${numToLetters(reste, showZero: showZero)}";
      }
      if (quotient > 1 && reste == 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} million";
      }
      if (quotient > 1 && reste != 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} million ${numToLetters(reste, showZero: showZero)}";
      }
      break;
    case 10:
    case 11:
    case 12:
      quotient = (nb / 1000000000).floor();
      reste = nb - quotient * 1000000000;
      if (quotient == 1 && reste == 0) numberToLetter = "un milliard";
      if (quotient == 1 && reste != 0) {
        numberToLetter =
            "un milliard ${numToLetters(reste, showZero: showZero)}";
      }
      if (quotient > 1 && reste == 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} milliard";
      }
      if (quotient > 1 && reste != 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} milliard ${numToLetters(reste, showZero: showZero)}";
      }
      break;
    case 13:
    case 14:
    case 15:
      quotient = (nb / 1000000000000).floor();
      reste = nb - quotient * 1000000000000;
      if (quotient == 1 && reste == 0) numberToLetter = "un billion";
      if (quotient == 1 && reste != 0) {
        numberToLetter =
            "un billion ${numToLetters(reste, showZero: showZero)}";
      }
      if (quotient > 1 && reste == 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} billion";
      }
      if (quotient > 1 && reste != 0) {
        numberToLetter =
            "${numToLetters(quotient, showZero: showZero)} billion ${numToLetters(reste, showZero: showZero)}";
      }
      break;
  }

  return numberToLetter;
}
