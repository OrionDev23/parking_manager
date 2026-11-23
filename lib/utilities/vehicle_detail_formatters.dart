import 'vehicle_util.dart';

/// Converts persisted vehicle codes into values that are suitable for display.
/// The original stored values remain untouched.
abstract final class VehicleDetailFormatters {
  static String? genreLabel(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return null;

    final code = int.tryParse(value);
    if (code == null) return value;
    if (code == 99) return null;
    if (code < 0 || code > 9) return 'Genre inconnu ($code)';

    return VehiclesUtilities.getGenreFromNumber(code);
  }

  static String? paintLabel(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return null;

    final normalized = value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\\s+'), ' ');

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

  static String formatNumber(num value) {
    if (value.isFinite && value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
