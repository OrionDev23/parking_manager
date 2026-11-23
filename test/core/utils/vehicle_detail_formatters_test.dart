import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/utilities/vehicle_detail_formatters.dart';

void main() {
  group('VehicleDetailFormatters.genreLabel', () {
    test('resolves the stored genre code to its translation key', () {
      expect(VehicleDetailFormatters.genreLabel('2'), 'camion');
    });

    test('treats legacy not-indicated codes as missing', () {
      expect(VehicleDetailFormatters.genreLabel('99'), isNull);
      expect(VehicleDetailFormatters.genreLabel('-1'), isNull);
    });

    test('keeps descriptive values and marks unknown numeric codes', () {
      expect(VehicleDetailFormatters.genreLabel('Autocar'), 'Autocar');
      expect(
        VehicleDetailFormatters.genreLabel('12'),
        'Genre inconnu (12)',
      );
    });
  });

  group('VehicleDetailFormatters.paintLabel', () {
    test('resolves persisted paint keys to French labels', () {
      expect(VehicleDetailFormatters.paintLabel('white'), 'Blanc');
      expect(VehicleDetailFormatters.paintLabel('silver'), 'Argent');
      expect(
        VehicleDetailFormatters.paintLabel('original'),
        'Peinture d’origine',
      );
    });

    test('preserves custom historical colour labels', () {
      expect(
        VehicleDetailFormatters.paintLabel('Bleu nuit'),
        'Bleu nuit',
      );
    });
  });

  group('VehicleDetailFormatters.formatNumber', () {
    test('removes unnecessary decimal zeros', () {
      expect(VehicleDetailFormatters.formatNumber(110.0), '110');
      expect(VehicleDetailFormatters.formatNumber(7.5), '7.5');
      expect(VehicleDetailFormatters.formatNumber(0), '0');
    });
  });

  group('VehicleDetailFormatters.wilayaName', () {
    test('resolves wilayas from the 69-wilaya administrative map', () {
      expect(
        VehicleDetailFormatters.wilayaName(23, languageCode: 'fr'),
        'Annaba',
      );
      expect(
        VehicleDetailFormatters.wilayaName(23, languageCode: 'ar'),
        'عنابة',
      );
      expect(
        VehicleDetailFormatters.wilayaName(59, languageCode: 'fr'),
        'Aflou',
      );
      expect(
        VehicleDetailFormatters.wilayaName(69, languageCode: 'fr'),
        'El Abiodh Sidi Cheikh',
      );
    });

    test('keeps null and unknown codes explicit', () {
      expect(VehicleDetailFormatters.wilayaName(null), isNull);
      expect(
        VehicleDetailFormatters.wilayaName(70),
        'Code wilaya inconnu (70)',
      );
    });
  });
}
