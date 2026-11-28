import 'dart:typed_data';

/// Browser Parking media is unavailable until a remote bucket and API exist.
class ParkingFileStore {
  final String companyId;
  ParkingFileStore({required this.companyId});

  UnsupportedError _unsupported() => UnsupportedError(
        'Local Parking image storage is not available on Web. '
        'A remote Parking media service has not been deployed.',
      );

  Future<String> saveImage({
    required String fileId,
    required String fileName,
    required Uint8List bytes,
  }) async => throw _unsupported();

  Future<String?> pathFor({
    required String fileId,
    required String fileName,
  }) async => throw _unsupported();

  Future<Uint8List?> readImage({
    required String fileId,
    required String fileName,
  }) async => throw _unsupported();

  Future<void> deleteImage({
    required String fileId,
    required String fileName,
  }) async => throw _unsupported();
}
