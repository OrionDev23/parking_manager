import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Stores Parking plan images locally, isolated by tenant.
class ParkingFileStore {
  final String companyId;

  ParkingFileStore({required this.companyId}) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$').hasMatch(companyId)) {
      throw ArgumentError.value(companyId, 'companyId');
    }
  }

  static const int maxImageBytes = 20 * 1024 * 1024;

  String _safeFileId(String fileId) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$').hasMatch(fileId)) {
      throw ArgumentError.value(fileId, 'fileId');
    }
    return fileId;
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) {
      throw const FormatException('The plan image must have a file extension.');
    }
    final extension = fileName.substring(dot + 1).toLowerCase();
    if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(extension)) {
      throw FormatException('Unsupported plan image format: .$extension');
    }
    return extension;
  }

  Future<Directory> _tenantDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}parcoto'
      '${Platform.pathSeparator}parking'
      '${Platform.pathSeparator}$companyId',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> saveImage({
    required String fileId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final safeId = _safeFileId(fileId);
    final extension = _extension(fileName);
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw ArgumentError('Plan image must contain between 1 byte and 20 MB.');
    }
    final directory = await _tenantDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeId.$extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> pathFor({
    required String fileId,
    required String fileName,
  }) async {
    final safeId = _safeFileId(fileId);
    final extension = _extension(fileName);
    final root = await getApplicationSupportDirectory();
    final file = File(
      '${root.path}${Platform.pathSeparator}parcoto'
      '${Platform.pathSeparator}parking'
      '${Platform.pathSeparator}$companyId'
      '${Platform.pathSeparator}$safeId.$extension',
    );
    return await file.exists() ? file.path : null;
  }

  Future<Uint8List?> readImage({
    required String fileId,
    required String fileName,
  }) async {
    final path = await pathFor(fileId: fileId, fileName: fileName);
    if (path == null) return null;
    return File(path).readAsBytes();
  }

  Future<void> deleteImage({
    required String fileId,
    required String fileName,
  }) async {
    final path = await pathFor(fileId: fileId, fileName: fileName);
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}