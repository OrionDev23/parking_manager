import 'vehicle_util.dart';

/// Converts persisted vehicle codes into values that are suitable for display.
/// The original stored values remain untouched.
abstract final class VehicleDetailFormatters {
  // Wilaya names and codes are taken from syscli/algeria's data/wilayas.csv.
  // The upstream dataset is MIT-licensed and cites Journal officiel laws
  // 84-09, 19-12, 26-06 and decrees 84-79, 21-117 and 26-206.
  static const Map<int, ({String fr, String ar})> _wilayas = {
    1: (fr: 'Adrar', ar: 'أدرار'),
    2: (fr: 'Chlef', ar: 'الشلف'),
    3: (fr: 'Laghouat', ar: 'الاغواط'),
    4: (fr: 'Oum El Bouaghi', ar: 'أم البواقى'),
    5: (fr: 'Batna', ar: 'باتنة'),
    6: (fr: 'Bejaïa', ar: 'بجاية'),
    7: (fr: 'Biskra', ar: 'بسكرة'),
    8: (fr: 'Béchar', ar: 'بشار'),
    9: (fr: 'Blida', ar: 'البليدة'),
    10: (fr: 'Bouira', ar: 'البويرة'),
    11: (fr: 'Tamanghasset', ar: 'تامنغست'),
    12: (fr: 'Tebessa', ar: 'تبسة'),
    13: (fr: 'Tlemcen', ar: 'تلمسان'),
    14: (fr: 'Tiaret', ar: 'تيارت'),
    15: (fr: 'Tizi Ouzou', ar: 'تيزى وزو'),
    16: (fr: 'Alger', ar: 'الجزائر'),
    17: (fr: 'Djelfa', ar: 'الجلفة'),
    18: (fr: 'Jijel', ar: 'جيجل'),
    19: (fr: 'Sétif', ar: 'سطيف'),
    20: (fr: 'Saïda', ar: 'سعيدة'),
    21: (fr: 'Skikda', ar: 'سكيكدة'),
    22: (fr: 'Sidi Bel Abbès', ar: 'سيدى بلعباس'),
    23: (fr: 'Annaba', ar: 'عنابة'),
    24: (fr: 'Guelma', ar: 'قالمة'),
    25: (fr: 'Constantine', ar: 'قسنطينة'),
    26: (fr: 'Médéa', ar: 'المدية'),
    27: (fr: 'Mostaganem', ar: 'مستغانم'),
    28: (fr: "M'Sila", ar: 'المسيلة'),
    29: (fr: 'Mascara', ar: 'معسكر'),
    30: (fr: 'Ouargla', ar: 'ورقلة'),
    31: (fr: 'Oran', ar: 'وهران'),
    32: (fr: 'El Bayadh', ar: 'البيض'),
    33: (fr: 'Illizi', ar: 'ايليزي'),
    34: (fr: 'Bordj Bou Arréridj', ar: 'برج بوعريريج'),
    35: (fr: 'Boumerdes', ar: 'بومرداس'),
    36: (fr: 'El Tarf', ar: 'الطارف'),
    37: (fr: 'Tindouf', ar: 'تندوف'),
    38: (fr: 'Tissemsilt', ar: 'تيسمسيلت'),
    39: (fr: 'El Oued', ar: 'الوادى'),
    40: (fr: 'Khenchela', ar: 'خنشلة'),
    41: (fr: 'Souk Ahras', ar: 'سوق أهراس'),
    42: (fr: 'Tipaza', ar: 'تيبازة'),
    43: (fr: 'Mila', ar: 'ميلة'),
    44: (fr: 'Aïn Defla', ar: 'عين الدفلى'),
    45: (fr: 'Naama', ar: 'النعامة'),
    46: (fr: 'Aïn Temouchent', ar: 'عين تيموشنت'),
    47: (fr: 'Ghardaïa', ar: 'غرداية'),
    48: (fr: 'Relizane', ar: 'غليزان'),
    49: (fr: 'Timimoun', ar: 'تيميمون'),
    50: (fr: 'Bordj Badji Mokhtar', ar: 'برج باجي مختار'),
    51: (fr: 'Ouled Djellal', ar: 'أولاد جلال'),
    52: (fr: 'Béni Abbès', ar: 'بني عباس'),
    53: (fr: 'In Salah', ar: 'إن صالح'),
    54: (fr: 'In Guezzam', ar: 'إن قزام'),
    55: (fr: 'Touggourt', ar: 'توقرت'),
    56: (fr: 'Djanet', ar: 'جانت'),
    57: (fr: "El M'Ghaier", ar: 'المغير'),
    58: (fr: 'El Meniaa', ar: 'المنيعة'),
    59: (fr: 'Aflou', ar: 'أفلو'),
    60: (fr: 'Barika', ar: 'بريكة'),
    61: (fr: 'El Kantara', ar: 'القنطرة'),
    62: (fr: 'Bir El Ater', ar: 'بئر العاتر'),
    63: (fr: 'El Aricha', ar: 'العريشة'),
    64: (fr: 'Ksar Chellala', ar: 'قصر الشلالة'),
    65: (fr: 'Aïn Ouessara', ar: 'عين وسارة'),
    66: (fr: 'Messaad', ar: 'مسعد'),
    67: (fr: 'Ksar El Boukhari', ar: 'قصر البخاري'),
    68: (fr: 'Bou Saâda', ar: 'بوسعادة'),
    69: (fr: 'El Abiodh Sidi Cheikh', ar: 'الأبيض سيدي الشيخ'),
  };

  static String? wilayaName(int? code, {String? languageCode}) {
    if (code == null) return null;
    final wilaya = _wilayas[code];
    if (wilaya == null) return 'Code wilaya inconnu ($code)';
    return languageCode?.toLowerCase() == 'ar' ? wilaya.ar : wilaya.fr;
  }

  static String? genreLabel(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return null;

    final code = int.tryParse(value);
    if (code == null) return value;
    if (code == 99 || code < 0) return null;
    if (code > 9) return 'Genre inconnu ($code)';

    return VehiclesUtilities.getGenreFromNumber(code);
  }

  static String? paintLabel(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return null;

    final normalized = value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (normalized) {
      case 'original':
      case 'origine':
      case 'peinture d origine':
      case 'couleur d origine':
      case 'default':
        return 'Peinture d’origine';
      case 'white':
      case 'blanc':
      case 'blanche':
        return 'Blanc';
      case 'black':
      case 'noir':
      case 'noire':
        return 'Noir';
      case 'silver':
      case 'argent':
      case 'argenté':
      case 'argente':
      case 'gris clair':
      case 'gris métallisé':
      case 'gris metallise':
        return 'Argent';
      case 'grey':
      case 'gray':
      case 'gris':
      case 'gris foncé':
      case 'gris fonce':
      case 'anthracite':
        return 'Gris foncé';
      case 'blue':
      case 'bleu':
      case 'bleue':
        return 'Bleu';
      case 'red':
      case 'rouge':
        return 'Rouge';
      default:
        return value;
    }
  }

  static String normalizeRegistration(String? value) {
    return (value ?? '')
        .trim()
        .replaceAll(RegExp(r'\\s+'), '')
        .toUpperCase();
  }

  static bool sameRegistration(String? left, String? right) {
    final normalizedLeft = normalizeRegistration(left);
    return normalizedLeft.isNotEmpty &&
        normalizedLeft == normalizeRegistration(right);
  }

  static String formatNumber(num value) {
    if (value.isFinite && value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
