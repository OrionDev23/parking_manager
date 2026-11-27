import 'dart:collection';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../providers/client_database.dart';

/// Displays saved vehicle images through the authenticated Appwrite SDK.
///
/// Saved images live in the file-secured shared images bucket. A plain
/// Image.network URL cannot reliably read those files because it does not
/// attach the current Appwrite session. External candidate previews can still
/// be rendered directly from their HTTPS URL before the user selects them.
class VehicleImageView extends StatefulWidget {
  final String? fileId;
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const VehicleImageView({
    super.key,
    this.fileId,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  State<VehicleImageView> createState() => _VehicleImageViewState();
}

class _VehicleImageViewState extends State<VehicleImageView> {
  static const String _bucketId = 'images';
  static const int _maximumCachedImages = 8;

  static final LinkedHashMap<String, Uint8List> _imageCache =
      LinkedHashMap<String, Uint8List>();
  static final Map<String, Future<Uint8List?>> _pendingDownloads = {};

  Future<Uint8List?>? _fileBytesFuture;
  String? _effectiveFileId;

  @override
  void initState() {
    super.initState();
    _prepareSource();
  }

  @override
  void didUpdateWidget(covariant VehicleImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId ||
        oldWidget.imageUrl != widget.imageUrl) {
      _prepareSource();
    }
  }

  String? _fileIdFromUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final filesIndex = segments.indexOf('files');
    if (filesIndex < 0 || filesIndex + 1 >= segments.length) return null;
    final fileId = segments[filesIndex + 1].trim();
    return fileId.isEmpty ? null : fileId;
  }

  void _prepareSource() {
    final explicitFileId = widget.fileId?.trim();
    _effectiveFileId = explicitFileId?.isNotEmpty == true
        ? explicitFileId
        : _fileIdFromUrl(widget.imageUrl);
    final fileId = _effectiveFileId;
    _fileBytesFuture = fileId == null ? null : _loadFileBytes(fileId);
  }

  Future<Uint8List?> _loadFileBytes(String fileId) async {
    // Do not reuse in-memory private image bytes across company switches.
    final cacheKey = '${DatabaseGetter.activeCompanyId ?? 'no-company'}:${DatabaseGetter.me.value?.id ?? 'no-user'}:$fileId';
    final cached = _imageCache.remove(cacheKey);
    if (cached != null) {
      _imageCache[cacheKey] = cached;
      return cached;
    }

    final pending = _pendingDownloads[cacheKey];
    if (pending != null) return pending;

    final client = DatabaseGetter.client;
    if (client == null) return null;

    final request = Storage(client)
        .getFileView(bucketId: _bucketId, fileId: fileId);
    _pendingDownloads[cacheKey] = request;

    try {
      final bytes = await request;
      _imageCache[cacheKey] = bytes;
      while (_imageCache.length > _maximumCachedImages) {
        _imageCache.remove(_imageCache.keys.first);
      }
      return bytes;
    } catch (error) {
      debugPrint('[Vehicle image] authenticated Appwrite read failed: $error');
      return null;
    } finally {
      _pendingDownloads.remove(cacheKey);
    }
  }

  Widget _placeholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[30],
          alignment: Alignment.center,
          child: Icon(
            FluentIcons.car,
            size: 34,
            color: Colors.grey[100],
          ),
        );
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileId = _effectiveFileId;
    if (fileId == null) {
      final url = widget.imageUrl?.trim() ?? '';
      return url.isEmpty ? _placeholder() : _networkImage(url);
    }

    final appwriteUrl = _fileIdFromUrl(widget.imageUrl) == fileId;
    return FutureBuilder<Uint8List?>(
      future: _fileBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (_, _, _) => _placeholder(),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _placeholder();
        }

        // Do not retry a file-secured Appwrite URL through unauthenticated
        // Image.network. Keep the fallback only for genuinely external URLs.
        final url = widget.imageUrl?.trim() ?? '';
        if (!appwriteUrl && url.startsWith('https://')) {
          return _networkImage(url);
        }
        return _placeholder();
      },
    );
  }
}
