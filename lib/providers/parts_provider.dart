import '../core/sync/sync_operation.dart';

import 'package:flutter/foundation.dart' hide Category;

import '../main.dart';
import 'client_database.dart';
import '../screens/sidemenu/sidemenu.dart';
import '../serializables/client.dart';
import '../serializables/pieces/brand.dart';
import '../serializables/pieces/category.dart';
import '../serializables/pieces/option.dart';
import '../serializables/pieces/part.dart';

class PartsProvider extends ChangeNotifier {
  static Map<String, Category> categories = {};
  static Map<String, Brand> brands = {};
  static Map<String, Option> options = {};
  static Map<String, VehiclePart> parts = {};
  static Map<String, Client> fournisseurs = {};

  static bool errorCategories = true;
  static bool errorBrands = true;
  static bool errorOptions = true;
  static bool errorParts = true;
  static bool errorFournisseurs = true;

  /// Last remote refresh failures, keyed by the legacy collection/entity.
  /// Cached rows remain usable; a failed remote refresh is still reported.
  static final Map<String, String> refreshErrors = {};
  static bool downloadingCategories = false;
  static bool downloadingBrands = false;
  static bool downloadingOptions = false;
  static bool downloadingParts = false;
  static bool downloadingFournisseurs = false;
  static int _cacheGeneration = 0;

  static bool _isCurrentCompany(String companyId, int generation) =>
      vehicleServices.companyId == companyId && _cacheGeneration == generation;

  static String? _cacheCompanyId;

  PartsProvider() {
    _ensureCompanyCache();
  }

  static void _ensureCompanyCache() {
    final companyId = vehicleServices.companyId;
    if (_cacheCompanyId == companyId) return;
    _cacheGeneration++;
    categories.clear();
    brands.clear();
    options.clear();
    parts.clear();
    fournisseurs.clear();
    refreshErrors.clear();
    errorCategories = true;
    errorBrands = true;
    errorOptions = true;
    errorParts = true;
    errorFournisseurs = true;
    downloadingCategories = false;
    downloadingBrands = false;
    downloadingOptions = false;
    downloadingParts = false;
    downloadingFournisseurs = false;
    _cacheCompanyId = companyId;
  }

  static String getUniqueCodeCategory() {
    var i = 0;
    while (categories.containsKey('cat$i')) {
      i++;
    }
    return 'cat$i';
  }

  static String getUniqueCodeBrand() {
    var i = 0;
    while (brands.containsKey('bran$i')) {
      i++;
    }
    return 'bran$i';
  }

  static String getUniqueCodeOption() {
    var i = 0;
    while (options.containsKey('opt$i')) {
      i++;
    }
    return 'opt$i';
  }

  List<Map<String, dynamic>> _readCache(String entity) => vehicleServices
      .localDatabase
      .readLegacyCache(companyId: vehicleServices.companyId, entity: entity);

  Map<String, dynamic> _payload(dynamic row) => <String, dynamic>{
    ...Map<String, dynamic>.from(row.data),
    r'$id': row.$id,
    r'$createdAt': row.$createdAt,
    r'$updatedAt': row.$updatedAt,
  };

  Future<void> _loadCollection<T>({
    required String entity,
    required String tableId,
    required Map<String, T> target,
    required T Function(Map<String, dynamic>) decode,
    required void Function(bool) setError,
    required void Function(bool) setDownloading,
  }) async {
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    bool isCurrent() => _isCurrentCompany(companyId, generation);
    try {
      final cachedRows = _readCache(entity);
      if (!isCurrent()) return;
      for (final payload in cachedRows) {
        try {
          final item = decode(payload);
          final id = payload[r'$id']?.toString();
          if (id != null && id.isNotEmpty) target[id] = item;
        } catch (error) {
          debugPrint('[ParcOto Stock] invalid $entity cache row ignored: $error');
        }
      }
      final cachedPendingOperations = await vehicleServices.syncQueue.pending(
        limit: 5000, companyId: companyId,
      );
      if (!isCurrent()) return;
      for (final operation in cachedPendingOperations) {
        if (operation.entity != entity) continue;
        switch (operation.type) {
          case SyncOperationType.create:
          case SyncOperationType.update:
            try {
              target[operation.entityId] = decode(<String, dynamic>{
                ...operation.payload, r'$id': operation.entityId,
              });
            } catch (error) {
              debugPrint('[ParcOto Stock] cached pending $entity row ignored: $error');
            }
            break;
          case SyncOperationType.delete:
            target.remove(operation.entityId);
            break;
        }
      }
      if (!isCurrent()) return;
      if (target.isNotEmpty) { setError(false); notifyListeners(); }
      if (!PanesListState.signedIn.value) {
        setError(target.isEmpty);
        return;
      }
      final database = DatabaseGetter.database;
      if (database == null) throw StateError('Appwrite database unavailable');
      final rows = await DatabaseGetter().listDocuments(tableId);
      if (!isCurrent()) return;
      final refreshed = <String, T>{};
      for (final row in rows) {
        final payload = _payload(row);
        try {
          refreshed[row.$id] = decode(payload);
          vehicleServices.localDatabase.cacheLegacyRow(
            companyId: companyId, entity: entity, entityId: row.$id, payload: payload,
          );
        } catch (error) {
          debugPrint('[ParcOto Stock] remote $entity row ignored: $error');
        }
      }
      final pendingOperations = await vehicleServices.syncQueue.pending(
        limit: 5000, companyId: companyId,
      );
      if (!isCurrent()) return;
      for (final operation in pendingOperations) {
        if (operation.entity != entity) continue;
        switch (operation.type) {
          case SyncOperationType.create:
          case SyncOperationType.update:
            try {
              refreshed[operation.entityId] = decode(<String, dynamic>{
                ...operation.payload, r'$id': operation.entityId,
              });
            } catch (error) {
              debugPrint('[ParcOto Stock] pending $entity operation ignored: $error');
            }
            break;
          case SyncOperationType.delete:
            refreshed.remove(operation.entityId);
            break;
        }
      }
      if (!isCurrent()) return;
      target..clear()..addAll(refreshed);
      setError(false);
      refreshErrors.remove(entity);
    } catch (error, stackTrace) {
      if (isCurrent()) {
        setError(true);
        refreshErrors[entity] = error.toString();
        debugPrint('[ParcOto Stock] $entity refresh failed: $error');
        if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      if (isCurrent()) {
        setDownloading(false);
        notifyListeners();
      }
    }
  }

  Future<void> downloadAllCategories() async {
    if (downloadingCategories) return;
    downloadingCategories = true;
    await _loadCollection<Category>(
      entity: 'part_category',
      tableId: categoriesID,
      target: categories,
      decode: Category.fromJson,
      setError: (value) => errorCategories = value,
      setDownloading: (value) => downloadingCategories = value,
    );
  }

  Future<void> downloadAllBrands() async {
    if (downloadingBrands) return;
    downloadingBrands = true;
    await _loadCollection<Brand>(
      entity: 'part_brand',
      tableId: brandsID,
      target: brands,
      decode: Brand.fromJson,
      setError: (value) => errorBrands = value,
      setDownloading: (value) => downloadingBrands = value,
    );
  }

  Future<void> downloadAllOptions() async {
    if (downloadingOptions) return;
    downloadingOptions = true;
    await _loadCollection<Option>(
      entity: 'part_option',
      tableId: optionsID,
      target: options,
      decode: Option.fromJson,
      setError: (value) => errorOptions = value,
      setDownloading: (value) => downloadingOptions = value,
    );
  }

  Future<void> downloadAllParts() async {
    if (downloadingParts) return;
    downloadingParts = true;
    await _loadCollection<VehiclePart>(
      entity: 'part',
      tableId: partsID,
      target: parts,
      decode: VehiclePart.fromJson,
      setError: (value) => errorParts = value,
      setDownloading: (value) => downloadingParts = value,
    );
  }

  Future<void> downloadAllFournisseurs() async {
    if (downloadingFournisseurs) return;
    downloadingFournisseurs = true;
    await _loadCollection<Client>(
      entity: 'supplier',
      tableId: fournsID,
      target: fournisseurs,
      decode: Client.fromJson,
      setError: (value) => errorFournisseurs = value,
      setDownloading: (value) => downloadingFournisseurs = value,
    );
  }

  T? _cachedById<T>({
    required String entity,
    required String id,
    required T Function(Map<String, dynamic>) decode,
  }) {
    for (final payload in _readCache(entity)) {
      if (payload[r'$id']?.toString() == id) {
        try {
          return decode(payload);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  Future<T?> _getById<T>({
    required String entity,
    required String tableId,
    required String id,
    required T Function(Map<String, dynamic>) decode,
  }) async {
    final companyId = vehicleServices.companyId;
    final generation = _cacheGeneration;
    // A queued deletion is a local tombstone: do not resurrect the remote
    // record through a detail lookup before the delete reaches Appwrite.
    final pendingOperations = await vehicleServices.syncQueue.pending(
      limit: 5000,
      companyId: companyId,
    );
    if (!_isCurrentCompany(companyId, generation)) return null;
    SyncOperation? latestPending;
    for (final operation in pendingOperations) {
      if (operation.entity == entity && operation.entityId == id) {
        if (latestPending == null ||
            operation.createdAt.isAfter(latestPending.createdAt)) {
          latestPending = operation;
        }
      }
    }
    if (latestPending?.type == SyncOperationType.delete) return null;
    if (latestPending != null) {
      try {
        return decode(<String, dynamic>{...latestPending.payload, r'$id': id});
      } catch (error) {
        debugPrint(
          '[ParcOto Stock] pending $entity detail decode failed: $error',
        );
      }
    }

    final cached = _cachedById(entity: entity, id: id, decode: decode);
    if (cached != null) return cached;

    try {
      final row = await DatabaseGetter().getDocument(tableId, id);
      if (!_isCurrentCompany(companyId, generation) || row == null) return null;
      final payload = _payload(row);
      final item = decode(payload);
      vehicleServices.localDatabase.cacheLegacyRow(
        companyId: companyId,
        entity: entity,
        entityId: id,
        payload: payload,
      );
      return item;
    } catch (error) {
      debugPrint('[ParcOto Stock] $entity lookup failed: $error');
      return null;
    }
  }

  Future<Client?> getFournisseur(String? id) async {
    if (id == null || id.isEmpty) return null;
    return _getById<Client>(
      entity: 'supplier',
      tableId: fournsID,
      id: id,
      decode: Client.fromJson,
    );
  }

  Future<Brand?> getBrand(String? id) async {
    if (id == null || id.isEmpty) return null;
    return _getById<Brand>(
      entity: 'part_brand',
      tableId: brandsID,
      id: id,
      decode: Brand.fromJson,
    );
  }

  Future<Category?> getCategory(String? id) async {
    if (id == null || id.isEmpty) return null;
    return _getById<Category>(
      entity: 'part_category',
      tableId: categoriesID,
      id: id,
      decode: Category.fromJson,
    );
  }

  Future<Option?> getOption(String? id) async {
    if (id == null || id.isEmpty) return null;
    return _getById<Option>(
      entity: 'part_option',
      tableId: optionsID,
      id: id,
      decode: Option.fromJson,
    );
  }

  Future<List<Option>?> getOptionsList(List<String>? ids) async {
    if (ids == null) return null;
    final result = <Option>[];
    for (final id in ids) {
      final option = await getOption(id);
      if (option != null) result.add(option);
    }
    return result;
  }

  Future<VehiclePart?> getPart(String? id) async {
    if (id == null || id.isEmpty) return null;
    return _getById<VehiclePart>(
      entity: 'part',
      tableId: partsID,
      id: id,
      decode: VehiclePart.fromJson,
    );
  }
}
