import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Reparation search status', () {
    test('keeps a missing status aligned with the waiting default', () {
      final repair = Reparation(
        id: 'repair-1',
        numero: 1,
        date: DateTime.utc(2026, 1, 1),
      );

      expect(repair.search, contains('waiting'));
    });

    test('does not throw for unsupported persisted status codes', () {
      for (final status in [-1, 3, 99]) {
        final repair = Reparation(
          id: 'repair-$status',
          numero: 1,
          date: DateTime.utc(2026, 1, 1),
          etat: status,
        );

        expect(repair.etat, status);
        expect(repair.search, contains('unknown'));
      }
    });
  });
}
