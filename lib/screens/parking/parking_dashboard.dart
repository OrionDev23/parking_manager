import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../../core/services/parking_services.dart';
import '../../data/local/vehicles/sqlite_vehicle_source.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/parking/parking_canvas_document.dart';
import '../../domain/parking/parking_geometry.dart';
import '../../domain/parking/parking_models.dart';
import 'parking_access_dialog.dart';
import 'parking_canvas_editor_dialog.dart';
import '../../theme.dart';

class ParkingDashboard extends StatefulWidget {
  const ParkingDashboard({super.key});

  @override
  State<ParkingDashboard> createState() => _ParkingDashboardState();
}

class _ParkingSnapshot {
  final List<ParkingSite> sites;
  final List<ParkingLot> lots;
  final ParkingLot? selectedLot;
  final List<ParkingLayout> layouts;
  final List<ParkingZone> zones;
  final List<ParkingSpace> spaces;
  final List<VehicleParkingAssignment> assignments;
  final Uint8List? backgroundBytes;
  final int? backgroundPixelWidth;
  final int? backgroundPixelHeight;

  const _ParkingSnapshot({
    required this.sites,
    required this.lots,
    required this.selectedLot,
    required this.layouts,
    required this.zones,
    required this.spaces,
    required this.assignments,
    this.backgroundBytes,
    this.backgroundPixelWidth,
    this.backgroundPixelHeight,
  });
}

enum _SpaceDisplayState { free, occupied, reserved, blocked, maintenance }

class _ParkingDashboardState extends State<ParkingDashboard> {
  ParkingServices? _services;
  Future<_ParkingSnapshot>? _snapshotFuture;
  String? _selectedLotId;
  String? _selectedSpaceId;

  @override
  void initState() {
    super.initState();
    ParkingServices.active.addListener(_onServicesChanged);
    _setServices(ParkingServices.active.value);
  }

  @override
  void dispose() {
    ParkingServices.active.removeListener(_onServicesChanged);
    super.dispose();
  }

  void _onServicesChanged() {
    _setServices(ParkingServices.active.value);
  }

  void _setServices(ParkingServices? services) {
    if (!mounted) {
      _services = services;
      _snapshotFuture = services == null ? null : _loadSnapshot(services);
      return;
    }
    setState(() {
      _services = services;
      _selectedLotId = null;
      _selectedSpaceId = null;
      _snapshotFuture = services == null ? null : _loadSnapshot(services);
    });
  }

  Future<_ParkingSnapshot> _loadSnapshot(
    ParkingServices services, {
    String? parkingLotId,
  }) async {
    final sites = await services.local.getSites();
    final lots = await services.local.getParkingLots();
    if (lots.isEmpty) {
      return _ParkingSnapshot(
        sites: sites,
        lots: lots,
        selectedLot: null,
        layouts: const [],
        zones: const [],
        spaces: const [],
        assignments: const [],
      );
    }

    ParkingLot selected = lots.first;
    final requestedId = parkingLotId ?? _selectedLotId;
    if (requestedId != null) {
      for (final lot in lots) {
        if (lot.id == requestedId) {
          selected = lot;
          break;
        }
      }
    }

    final layouts = await services.local.getLayouts(selected.id);
    final zones = await services.local.getZones(selected.id);
    final spaces = <ParkingSpace>[];
    for (final zone in zones) {
      spaces.addAll(await services.local.getSpaces(zone.id));
    }
    final assignments = await services.local.getAssignments(
      parkingLotId: selected.id,
    );
    final mediaItems = await services.local.getMedia(selected.id);
    ParkingMedia? backgroundMedia;
    Uint8List? backgroundBytes;
    if (layouts.isNotEmpty && layouts.first.backgroundFileId != null) {
      for (final media in mediaItems) {
        if (media.fileId == layouts.first.backgroundFileId) {
          backgroundMedia = media;
          break;
        }
      }
      if (backgroundMedia != null) {
        backgroundBytes = await services.files.readImage(
          fileId: backgroundMedia.fileId,
          fileName: backgroundMedia.fileName,
        );
      }
    }

    return _ParkingSnapshot(
      sites: sites,
      lots: lots,
      selectedLot: selected,
      layouts: layouts,
      zones: zones,
      spaces: spaces,
      assignments: assignments,
      backgroundBytes: backgroundBytes,
      backgroundPixelWidth: backgroundMedia?.pixelWidth,
      backgroundPixelHeight: backgroundMedia?.pixelHeight,
    );
  }

  void _refresh({String? parkingLotId}) {
    final services = _services;
    if (services == null) return;
    setState(() {
      if (parkingLotId != null) _selectedLotId = parkingLotId;
      _snapshotFuture = _loadSnapshot(
        services,
        parkingLotId: parkingLotId ?? _selectedLotId,
      );
    });
  }

  String _nextUniqueSiteCode(
    String requested,
    Set<String> existingCodes,
  ) {
    final normalized = existingCodes.map((code) => code.toLowerCase()).toSet();
    if (!normalized.contains(requested.toLowerCase())) return requested;

    for (var suffixNumber = 2; suffixNumber < 10000; suffixNumber++) {
      final suffix = '-${suffixNumber.toString().padLeft(2, '0')}';
      final prefixLength = requested.length <= 40 - suffix.length
          ? requested.length
          : 40 - suffix.length;
      final candidate = requested.substring(0, prefixLength) + suffix;
      if (!normalized.contains(candidate.toLowerCase())) return candidate;
    }
    throw StateError('No unique site code could be generated.');
  }

  Future<void> _createParking() async {
    final services = _services;
    if (services == null) return;

    final input = await showDialog<_ParkingSetupInput>(
      context: context,
      builder: (context) => const _CreateParkingDialog(),
    );
    if (input == null || !mounted) return;

    try {
      final existingSites = await services.local.getSites();
      final uniqueSiteCode = _nextUniqueSiteCode(
        input.siteCode,
        existingSites.map((site) => site.code).toSet(),
      );
      final now = DateTime.now().toUtc();
      final stamp = now.microsecondsSinceEpoch.toString();
      final siteId = 'site_$stamp';
      final parkingLotId = 'lot_$stamp';
      final layoutId = 'layout_$stamp';
      final zoneId = 'zone_$stamp';

      final margin = 2.0;
      final horizontal =
          input.orientation == ParkingRowOrientation.horizontal;
      final widthM = margin * 2 +
          (horizontal
              ? input.spacesPerRow * input.spaceWidthM +
                  (input.spacesPerRow - 1) * input.spaceGapM
              : input.rowCount * input.spaceLengthM +
                  (input.rowCount - 1) * input.rowGapM);
      final heightM = margin * 2 +
          (horizontal
              ? input.rowCount * input.spaceLengthM +
                  (input.rowCount - 1) * input.rowGapM
              : input.spacesPerRow * input.spaceWidthM +
                  (input.spacesPerRow - 1) * input.spaceGapM);

      final site = ParkingSite(
        id: siteId,
        companyId: services.companyId,
        code: uniqueSiteCode,
        name: input.siteName,
        createdAt: now,
        updatedAt: now,
      );
      final parkingLot = ParkingLot(
        id: parkingLotId,
        companyId: services.companyId,
        siteId: siteId,
        code: input.parkingCode,
        name: input.parkingName,
        status: ParkingLotStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final layout = ParkingLayout(
        id: layoutId,
        companyId: services.companyId,
        parkingLotId: parkingLotId,
        name: 'Plan principal',
        version: 1,
        status: ParkingLayoutStatus.draft,
        widthM: widthM,
        heightM: heightM,
        gridStepM: 0.25,
        createdAt: now,
        updatedAt: now,
      );
      final zone = ParkingZone(
        id: zoneId,
        companyId: services.companyId,
        parkingLotId: parkingLotId,
        code: input.zoneCode,
        name: 'Zone ${input.zoneCode}',
        type: ParkingZoneType.standard,
        boundary: ParkingPolygon(
          points: [
            const ParkingPoint(x: 0, y: 0),
            ParkingPoint(x: widthM, y: 0),
            ParkingPoint(x: widthM, y: heightM),
            ParkingPoint(x: 0, y: heightM),
          ],
        ),
        createdAt: now,
        updatedAt: now,
      );

      const rowGenerator = ParkingRowGenerator();
      final spaces = <ParkingSpace>[];
      for (var rowIndex = 0; rowIndex < input.rowCount; rowIndex++) {
        final rowCode = input.rowPrefix + (rowIndex + 1).toString();
        final generated = rowGenerator.generate(
          ParkingRowSpec(
            zoneCode: input.zoneCode,
            rowCode: rowCode,
            spacePrefix: '$rowCode-',
            count: input.spacesPerRow,
            numberPadding: 3,
            anchorX: horizontal
                ? margin + input.spaceWidthM / 2
                : margin + input.spaceLengthM / 2 +
                    rowIndex * (input.spaceLengthM + input.rowGapM),
            anchorY: horizontal
                ? margin + input.spaceLengthM / 2 +
                    rowIndex * (input.spaceLengthM + input.rowGapM)
                : margin + input.spaceWidthM / 2,
            spaceWidth: input.spaceWidthM,
            spaceLength: input.spaceLengthM,
            gap: input.spaceGapM,
            orientation: input.orientation,
          ),
        );
        for (final generatedSpace in generated) {
          final ordinal = spaces.length + 1;
          spaces.add(
            ParkingSpace(
              id: 'space_${stamp}_$ordinal',
              companyId: services.companyId,
              parkingZoneId: zoneId,
              code: generatedSpace.code,
              type: ParkingSpaceType.standard,
              status: ParkingSpaceStatus.active,
              shape: ParkingSpaceShape.rectangle,
              rectangle: generatedSpace.geometry,
              rowCode: generatedSpace.rowCode,
              sortOrder: ordinal - 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }

      await services.local.createParkingSetup(
        site: site,
        parkingLot: parkingLot,
        layout: layout,
        zones: [zone],
        spaces: spaces,
      );
      if (!mounted) return;
      _selectedLotId = parkingLotId;
      _selectedSpaceId = null;
      _refresh(parkingLotId: parkingLotId);
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Parking créé'),
          content: Text(
            'Code du site : ${site.code}. Le plan et ses places sont '
            'enregistrés sur cet appareil. La synchronisation Appwrite sera '
            'activée après le déploiement des services distants Parking.',
          ),
          severity: InfoBarSeverity.success,
        ),
        duration: const Duration(seconds: 6),
      );
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Création impossible'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: const Duration(seconds: 6),
      );
    }
  }


  Future<void> _editVectorPlan(
    _ParkingSnapshot data,
    AppTheme theme,
  ) async {
    final services = _services;
    if (services == null || kIsWeb || data.layouts.isEmpty) return;

    final layout = data.layouts.first;
    ParkingCanvasDocument document;
    try {
      document = ParkingCanvasDocument.fromJsonString(layout.layersJson);
      final defaultLayers =
          ParkingCanvasDocument.withDefaultLayers().layers;
      final layers = [...document.layers];
      for (final defaultLayer in defaultLayers) {
        if (layers.any((layer) => layer.type == defaultLayer.type)) continue;
        var layerId = defaultLayer.id;
        var suffix = 1;
        while (layers.any((layer) => layer.id == layerId)) {
          layerId = '${defaultLayer.id}_$suffix';
          suffix++;
        }
        layers.add(
          defaultLayer.copyWith(
            id: layerId,
            sortOrder: layers.length,
          ),
        );
      }
      document = document.copyWith(
        layers: [
          for (var index = 0; index < layers.length; index++)
            layers[index].copyWith(sortOrder: index),
        ],
      );
    } catch (error) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Plan illisible'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
      );
      return;
    }

    final editedDocument = await showDialog<ParkingCanvasDocument>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ParkingCanvasEditorDialog(
        layout: layout,
        document: document,
        zones: data.zones,
        spaces: data.spaces,
        backgroundBytes: data.backgroundBytes,
        backgroundPixelWidth: data.backgroundPixelWidth,
        backgroundPixelHeight: data.backgroundPixelHeight,
        primaryColor: theme.color,
        backgroundColor: theme.surfaceColor,
        borderColor: theme.borderColor,
        textColor: theme.textColor,
        mutedColor: theme.mutedTextColor,
      ),
    );
    if (editedDocument == null || !mounted) return;

    try {
      final now = DateTime.now().toUtc();
      await services.local.upsertLayout(
        ParkingLayout(
          id: layout.id,
          companyId: layout.companyId,
          parkingLotId: layout.parkingLotId,
          name: layout.name,
          version: layout.version,
          status: layout.status,
          widthM: layout.widthM,
          heightM: layout.heightM,
          gridStepM: layout.gridStepM,
          backgroundFileId: layout.backgroundFileId,
          backgroundTransform: layout.backgroundTransform,
          layersJson: editedDocument.encode(),
          createdAt: layout.createdAt,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _refresh(parkingLotId: layout.parkingLotId);
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Plan enregistré'),
          content: Text('Les modifications vectorielles sont enregistrées localement.'),
          severity: InfoBarSeverity.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Enregistrement impossible'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
      );
    }
  }

  Future<ui.Size> _readImageDimensions(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        return ui.Size(
          descriptor.width.toDouble(),
          descriptor.height.toDouble(),
        );
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  Future<void> _importPlanImage() async {
    final services = _services;
    if (services == null) return;

    try {
      final pendingSnapshot = _snapshotFuture;
      if (pendingSnapshot == null) {
        throw StateError('Le plan du parking n’est pas encore chargé.');
      }
      final snapshot = await pendingSnapshot;
      if (!mounted) return;
      final parkingLot = snapshot.selectedLot;
      if (parkingLot == null || snapshot.layouts.isEmpty) {
        throw StateError(
          'Crée d’abord un parking avec un plan vectoriel avant d’importer un fond.',
        );
      }
      final currentLayout = snapshot.layouts.first;

      final selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (selectedFile == null || !mounted) return;
      final fileName = selectedFile.name;
      final extension = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
          : '';
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        _ => throw FormatException('Format d’image non pris en charge.'),
      };

      final bytes = await selectedFile.readAsBytes();
      if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
        throw StateError('L’image doit peser au maximum 20 Mo.');
      }
      final imageSize = await _readImageDimensions(bytes);
      if (imageSize.width < 2 ||
          imageSize.height < 2 ||
          imageSize.width > 12000 ||
          imageSize.height > 12000 ||
          imageSize.width * imageSize.height > 40000000) {
        throw StateError('Dimensions de l’image non prises en charge.');
      }
      if (!mounted) return;

      final calibrationResult =
          await showDialog<_CalibratedBackgroundResult>(
        context: context,
        builder: (context) => _CalibrateBackgroundDialog(
          bytes: bytes,
          fileName: fileName,
          pixelWidth: imageSize.width.toInt(),
          pixelHeight: imageSize.height.toInt(),
        ),
      );
      if (calibrationResult == null || !mounted) return;

      final calibration = calibrationResult.calibration;
      final rotationDegrees = calibrationResult.rotationDegrees;
      calibration.validate();
      final metersPerPixel = calibration.metersPerPixel;
      final angleRadians = rotationDegrees * math.pi / 180;
      final cosine = math.cos(angleRadians).abs();
      final sine = math.sin(angleRadians).abs();
      final importedWidthM =
          (imageSize.width * cosine + imageSize.height * sine) *
              metersPerPixel;
      final importedHeightM =
          (imageSize.width * sine + imageSize.height * cosine) *
              metersPerPixel;
      if (!importedWidthM.isFinite ||
          !importedHeightM.isFinite ||
          importedWidthM <= 0 ||
          importedHeightM <= 0 ||
          importedWidthM > 10000 ||
          importedHeightM > 10000) {
        throw StateError('L’échelle calculée produit un plan trop grand.');
      }

      // Preserve the existing vector geometry. Expand the plan only when the
      // calibrated raster is larger, then center the image in the new extent.
      final layoutWidthM = math.max(
        currentLayout.widthM,
        importedWidthM,
      ).toDouble();
      final layoutHeightM = math.max(
        currentLayout.heightM,
        importedHeightM,
      ).toDouble();

      final now = DateTime.now().toUtc();
      final stamp = now.microsecondsSinceEpoch.toString();
      final fileId = 'planimg_$stamp';
      final mediaId = 'media_$stamp';
      final offsetX =
          (imageSize.width / 2 * math.cos(angleRadians) +
                  imageSize.height / 2 * math.sin(angleRadians)) *
              metersPerPixel;
      final offsetY =
          (imageSize.width / 2 * math.sin(angleRadians) -
                  imageSize.height / 2 * math.cos(angleRadians)) *
              metersPerPixel;
      final transform = ParkingBackgroundTransform(
        originXM: layoutWidthM / 2 - offsetX,
        originYM: layoutHeightM / 2 - offsetY,
        metersPerPixel: metersPerPixel,
        rotationDegrees: rotationDegrees,
        opacity: 0.58,
        calibration: calibration,
      );
      final updatedLayout = ParkingLayout(
        id: currentLayout.id,
        companyId: currentLayout.companyId,
        parkingLotId: currentLayout.parkingLotId,
        name: currentLayout.name,
        version: currentLayout.version,
        status: currentLayout.status,
        widthM: layoutWidthM,
        heightM: layoutHeightM,
        gridStepM: currentLayout.gridStepM,
        backgroundFileId: fileId,
        backgroundTransform: transform,
        layersJson: currentLayout.layersJson,
        createdAt: currentLayout.createdAt,
        updatedAt: now,
      );
      final media = ParkingMedia(
        id: mediaId,
        companyId: services.companyId,
        parkingLotId: parkingLot.id,
        layoutId: currentLayout.id,
        fileId: fileId,
        purpose: ParkingMediaPurpose.layoutBackground,
        fileName: fileName,
        mimeType: mimeType,
        fileSize: bytes.length,
        pixelWidth: imageSize.width.toInt(),
        pixelHeight: imageSize.height.toInt(),
        createdAt: now,
        updatedAt: now,
      );

      await services.files.saveImage(
        fileId: fileId,
        fileName: fileName,
        bytes: bytes,
      );
      try {
        await services.local.attachLayoutBackground(
          layout: updatedLayout,
          media: media,
        );
      } catch (_) {
        await services.files.deleteImage(
          fileId: fileId,
          fileName: fileName,
        );
        rethrow;
      }

      if (!mounted) return;
      _refresh(parkingLotId: parkingLot.id);
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Fond de plan importé'),
          content: Text(
            'Calibration : ${metersPerPixel.toStringAsFixed(4)} '
            'm/pixel. Le fond est stocké localement sur cet appareil.',
          ),
          severity: InfoBarSeverity.success,
        ),
        duration: const Duration(seconds: 6),
      );
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Import impossible'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: const Duration(seconds: 7),
      );
    }
  }

  _SpaceDisplayState _displayState(
    ParkingSpace space,
    List<VehicleParkingAssignment> assignments,
    DateTime instant,
  ) {
    switch (space.status) {
      case ParkingSpaceStatus.blocked:
      case ParkingSpaceStatus.inactive:
        return _SpaceDisplayState.blocked;
      case ParkingSpaceStatus.maintenance:
        return _SpaceDisplayState.maintenance;
      case ParkingSpaceStatus.active:
        break;
    }
    for (final assignment in assignments) {
      if (assignment.parkingSpaceId == space.id &&
          assignment.isEffectiveAt(instant)) {
        return assignment.type == ParkingAssignmentType.reserved
            ? _SpaceDisplayState.reserved
            : _SpaceDisplayState.occupied;
      }
    }
    return _SpaceDisplayState.free;
  }

  Color _stateColor(_SpaceDisplayState state, AppTheme theme) {
    switch (state) {
      case _SpaceDisplayState.free:
        return const Color(0xFF24B47E);
      case _SpaceDisplayState.occupied:
        return theme.color;
      case _SpaceDisplayState.reserved:
        return const Color(0xFFE3A33D);
      case _SpaceDisplayState.blocked:
        return const Color(0xFFE05B67);
      case _SpaceDisplayState.maintenance:
        return const Color(0xFF8B8FA3);
    }
  }

  String _stateLabel(_SpaceDisplayState state) {
    switch (state) {
      case _SpaceDisplayState.free:
        return 'Libre';
      case _SpaceDisplayState.occupied:
        return 'Occupée';
      case _SpaceDisplayState.reserved:
        return 'Réservée';
      case _SpaceDisplayState.blocked:
        return 'Bloquée';
      case _SpaceDisplayState.maintenance:
        return 'Maintenance';
    }
  }


  Future<void> _registerManualEntry(
    _ParkingSnapshot data,
    AppTheme theme,
  ) async {
    final services = _services;
    if (services == null || kIsWeb || data.selectedLot == null) return;

    try {
      final vehicles = await SqliteVehicleSource(
        services.localDatabase,
        companyId: services.companyId,
      ).getVehicles();
      final allAssignments = await services.local.getAssignments();
      final now = DateTime.now().toUtc();
      final blockingAssignments = allAssignments.where((assignment) {
        return assignment.status == ParkingAssignmentStatus.active &&
            (assignment.endAt == null || assignment.endAt!.isAfter(now));
      }).toList(growable: false);
      final busyVehicleIds = blockingAssignments
          .map((assignment) => assignment.vehicleId)
          .toSet();
      final availableVehicles = vehicles
          .where((vehicle) => !busyVehicleIds.contains(vehicle.id))
          .toList(growable: false);
      final busySpaceIds = blockingAssignments
          .map((assignment) => assignment.parkingSpaceId)
          .toSet();
      final availableSpaces = data.spaces
          .where(
            (space) =>
                space.canReceiveAssignment && !busySpaceIds.contains(space.id),
          )
          .toList(growable: false);

      if (availableVehicles.isEmpty) {
        throw StateError(
          vehicles.isEmpty
              ? 'Aucun véhicule local n’est disponible. Synchronise d’abord la flotte.'
              : 'Tous les véhicules disposent déjà d’une affectation active ou d’une réservation.',
        );
      }
      if (availableSpaces.isEmpty) {
        throw StateError(
          'Aucune place libre et disponible n’est configurée dans ce parking.',
        );
      }

      if (!mounted) return;
      final selection = await showDialog<ParkingAccessSelection>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ParkingAccessDialog(
          isEntry: true,
          vehicles: availableVehicles,
          availableSpaces: availableSpaces,
          activeAssignments: const [],
          primaryColor: theme.color,
          backgroundColor: theme.surfaceColor,
          borderColor: theme.borderColor,
          textColor: theme.textColor,
          mutedColor: theme.mutedTextColor,
        ),
      );
      if (selection == null || !mounted) return;

      Vehicle? selectedVehicle;
      for (final vehicle in availableVehicles) {
        if (vehicle.id == selection.vehicleId) {
          selectedVehicle = vehicle;
          break;
        }
      }
      if (selectedVehicle == null || selection.parkingSpaceId == null) {
        throw StateError('La sélection du véhicule ou de la place est invalide.');
      }

      final selectedRegistration = selectedVehicle.registration;
      final instant = DateTime.now().toUtc();
      final stamp = instant.microsecondsSinceEpoch.toString();
      final assignmentId = 'assign_$stamp';
      final eventId = 'entry_$stamp';
      final assignment = VehicleParkingAssignment(
        id: assignmentId,
        companyId: services.companyId,
        vehicleId: selectedVehicle.id,
        parkingSpaceId: selection.parkingSpaceId!,
        type: ParkingAssignmentType.assigned,
        status: ParkingAssignmentStatus.active,
        source: ParkingAssignmentSource.manual,
        startAt: instant,
        entryEventId: eventId,
        notes: selection.notes,
        createdAt: instant,
        updatedAt: instant,
      );
      final event = ParkingAccessEvent(
        id: eventId,
        companyId: services.companyId,
        parkingLotId: data.selectedLot!.id,
        vehicleId: selectedVehicle.id,
        assignmentId: assignmentId,
        type: ParkingAccessEventType.entry,
        source: ParkingEventSource.manual,
        occurredAt: instant,
        recordedAt: instant,
        registrationCaptured: selectedVehicle.registration,
        registrationNormalized: ParkingAccessEvent.normalizeRegistration(
          selectedVehicle.registration,
        ),
        notes: selection.notes,
        createdAt: instant,
        updatedAt: instant,
      );

      await services.local.createAssignment(assignment, event: event);
      if (!mounted) return;
      _selectedSpaceId = selection.parkingSpaceId;
      _refresh(parkingLotId: data.selectedLot!.id);
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Entrée enregistrée'),
          content: Text(
            '$selectedRegistration a été affecté à la place sélectionnée. '
            'L’événement est enregistré localement.',
          ),
          severity: InfoBarSeverity.success,
        ),
        duration: const Duration(seconds: 5),
      );
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Entrée impossible'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: const Duration(seconds: 7),
      );
    }
  }

  Future<void> _registerManualExit(
    _ParkingSnapshot data,
    AppTheme theme,
  ) async {
    final services = _services;
    if (services == null || kIsWeb || data.selectedLot == null) return;

    try {
      final vehicles = await SqliteVehicleSource(
        services.localDatabase,
        companyId: services.companyId,
      ).getVehicles();
      final now = DateTime.now().toUtc();
      final activeAssignments = data.assignments
          .where(
            (assignment) =>
                assignment.type != ParkingAssignmentType.reserved &&
                assignment.isEffectiveAt(now),
          )
          .toList(growable: false);
      final vehicleIds = activeAssignments
          .map((assignment) => assignment.vehicleId)
          .toSet();
      final activeVehicles = vehicles
          .where((vehicle) => vehicleIds.contains(vehicle.id))
          .toList(growable: false);

      if (activeAssignments.isEmpty || activeVehicles.isEmpty) {
        throw StateError(
          'Aucun véhicule avec une entrée active n’est actuellement présent dans ce parking.',
        );
      }

      if (!mounted) return;
      final selection = await showDialog<ParkingAccessSelection>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ParkingAccessDialog(
          isEntry: false,
          vehicles: activeVehicles,
          availableSpaces: data.spaces,
          activeAssignments: activeAssignments,
          primaryColor: theme.color,
          backgroundColor: theme.surfaceColor,
          borderColor: theme.borderColor,
          textColor: theme.textColor,
          mutedColor: theme.mutedTextColor,
        ),
      );
      if (selection == null || !mounted || selection.assignmentId == null) {
        return;
      }

      Vehicle? selectedVehicle;
      for (final vehicle in activeVehicles) {
        if (vehicle.id == selection.vehicleId) {
          selectedVehicle = vehicle;
          break;
        }
      }
      if (selectedVehicle == null) {
        throw StateError('Le véhicule sélectionné est introuvable.');
      }

      final selectedRegistration = selectedVehicle.registration;
      final instant = DateTime.now().toUtc();
      final eventId = 'exit_${instant.microsecondsSinceEpoch}';
      final event = ParkingAccessEvent(
        id: eventId,
        companyId: services.companyId,
        parkingLotId: data.selectedLot!.id,
        vehicleId: selectedVehicle.id,
        assignmentId: selection.assignmentId,
        type: ParkingAccessEventType.exit,
        source: ParkingEventSource.manual,
        occurredAt: instant,
        recordedAt: instant,
        registrationCaptured: selectedVehicle.registration,
        registrationNormalized: ParkingAccessEvent.normalizeRegistration(
          selectedVehicle.registration,
        ),
        notes: selection.notes,
        createdAt: instant,
        updatedAt: instant,
      );

      await services.local.endAssignment(
        assignmentId: selection.assignmentId!,
        endedAt: instant,
        event: event,
      );
      if (!mounted) return;
      _refresh(parkingLotId: data.selectedLot!.id);
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Sortie enregistrée'),
          content: Text(
            '$selectedRegistration a quitté le parking. '
            'La sortie est ajoutée à l’historique local.',
          ),
          severity: InfoBarSeverity.success,
        ),
        duration: const Duration(seconds: 5),
      );
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Sortie impossible'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: const Duration(seconds: 7),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final services = _services;
    final future = _snapshotFuture;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          return ListView(
            padding: EdgeInsets.all(compact ? 16 : 26),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parking',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: compact ? 24 : 29,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Conception et exploitation des stationnements',
                          style: TextStyle(color: theme.mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      Button(
                        onPressed:
                            services == null || kIsWeb ? null : _importPlanImage,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.upload, size: 14),
                            SizedBox(width: 7),
                            Text('Importer un plan'),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed:
                            services == null || kIsWeb ? null : _createParking,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.add, size: 14),
                            SizedBox(width: 8),
                            Text('Créer un parking'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LocalStorageNotice(theme: theme),
              const SizedBox(height: 18),
              if (services == null)
                _EmptyPanel(
                  theme: theme,
                  title: 'Aucune entreprise active',
                  description:
                      'Le module Parking sera disponible après le chargement '
                      'du contexte de l’entreprise.',
                )
              else if (future == null)
                _EmptyPanel(
                  theme: theme,
                  title: 'Initialisation du module',
                  description: 'Le stockage local du Parking est en cours.',
                )
              else
                FutureBuilder<_ParkingSnapshot>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: ProgressRing(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      final webUnavailable =
                          snapshot.error is UnsupportedError;
                      return _EmptyPanel(
                        theme: theme,
                        title: webUnavailable
                            ? 'Parking Web non connecté'
                            : 'Impossible de charger les parkings',
                        description: webUnavailable
                            ? 'Le stockage distant Parking et ses API ne sont '
                                'pas encore provisionnés. Aucune fausse donnée '
                                'ne sera affichée.'
                            : snapshot.error.toString(),
                        actionLabel: 'Réessayer',
                        onAction: () => _refresh(),
                      );
                    }
                    final data = snapshot.data!;
                    if (data.lots.isEmpty) {
                      return _EmptyPanel(
                        theme: theme,
                        title: 'Aucun parking configuré',
                        description:
                            'Commence par créer un site et un parking. '
                            'L’assistant générera les zones et les places '
                            'avec des dimensions modifiables.',
                        actionLabel:
                            kIsWeb ? null : 'Créer mon premier parking',
                        onAction: kIsWeb ? null : _createParking,
                      );
                    }
                    return _buildParking(data, theme);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParking(
    _ParkingSnapshot data,
    AppTheme theme,
  ) {
    final selectedLot = data.selectedLot!;
    final selectedSiteRows =
        data.sites.where((site) => site.id == selectedLot.siteId).toList();
    final selectedSiteName = selectedSiteRows.isEmpty
        ? selectedLot.siteId
        : selectedSiteRows.first.name;
    final now = DateTime.now().toUtc();
    final states = {
      for (final space in data.spaces)
        space.id: _displayState(space, data.assignments, now),
    };
    final total = data.spaces.length;
    final occupied =
        states.values.where((state) => state == _SpaceDisplayState.occupied).length;
    final reserved =
        states.values.where((state) => state == _SpaceDisplayState.reserved).length;
    final blocked = states.values
        .where((state) =>
            state == _SpaceDisplayState.blocked ||
            state == _SpaceDisplayState.maintenance)
        .length;
    final free = total - occupied - reserved - blocked;
    final activePhysicalAssignments = data.assignments
        .where(
          (assignment) =>
              assignment.type != ParkingAssignmentType.reserved &&
              assignment.isEffectiveAt(now),
        )
        .toList(growable: false);
    ParkingSpace? selectedSpace;
    for (final space in data.spaces) {
      if (space.id == _selectedSpaceId) selectedSpace = space;
    }
    selectedSpace ??= data.spaces.isEmpty ? null : data.spaces.first;
    VehicleParkingAssignment? selectedAssignment;
    if (selectedSpace != null) {
      for (final assignment in data.assignments) {
        if (assignment.parkingSpaceId == selectedSpace.id &&
            assignment.isEffectiveAt(now)) {
          selectedAssignment = assignment;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.lots.length > 1)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parking',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ComboBox<String>(
                value: selectedLot.id,
                items: data.lots
                    .map(
                      (lot) => ComboBoxItem<String>(
                        value: lot.id,
                        child: Text(lot.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    _selectedSpaceId = null;
                    _refresh(parkingLotId: value);
                  }
                },
              ),
            ],
          )
        else
          Text(
            selectedLot.name,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Site : $selectedSiteName • ${selectedLot.code} • ${selectedLot.status.name}',
          style: TextStyle(color: theme.mutedTextColor, fontSize: 12),
        ),
        if (data.layouts.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            'Plan v${data.layouts.first.version} — '
            '${data.layouts.first.widthM.toStringAsFixed(1)} × '
            '${data.layouts.first.heightM.toStringAsFixed(1)} m',
            style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              label: 'Capacité',
              value: total.toString(),
              detail: 'Places configurées',
              theme: theme,
              icon: FluentIcons.car,
            ),
            _MetricCard(
              label: 'Occupées',
              value: occupied.toString(),
              detail: 'Occupation physique',
              theme: theme,
              icon: FluentIcons.car,
              accent: theme.color,
            ),
            _MetricCard(
              label: 'Libres',
              value: free.toString(),
              detail: 'Disponibles maintenant',
              theme: theme,
              icon: FluentIcons.check_mark,
              accent: const Color(0xFF24B47E),
            ),
            _MetricCard(
              label: 'Réservées',
              value: reserved.toString(),
              detail: 'Réservation active',
              theme: theme,
              icon: FluentIcons.calendar,
              accent: const Color(0xFFE3A33D),
            ),
            _MetricCard(
              label: 'Indisponibles',
              value: blocked.toString(),
              detail: 'Bloquées ou maintenance',
              theme: theme,
              icon: FluentIcons.blocked,
              accent: const Color(0xFFE05B67),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: kIsWeb ? null : () => _registerManualEntry(data, theme),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.signin, size: 14),
                  SizedBox(width: 7),
                  Text('Entrée manuelle'),
                ],
              ),
            ),
            Button(
              onPressed: kIsWeb || activePhysicalAssignments.isEmpty
                  ? null
                  : () => _registerManualExit(data, theme),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.sign_out, size: 14),
                  SizedBox(width: 7),
                  Text('Sortie manuelle'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (data.layouts.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plan vectoriel — échelle métrique',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Button(
                onPressed: kIsWeb ? null : () => _editVectorPlan(data, theme),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.edit, size: 13),
                    SizedBox(width: 7),
                    Text('Ouvrir le concepteur'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ParkingPlanPreview(
            layout: data.layouts.first,
            zones: data.zones,
            spaces: data.spaces,
            states: states,
            selectedSpaceId: selectedSpace?.id,
            primaryColor: theme.color,
            backgroundColor: theme.surfaceColor,
            borderColor: theme.borderColor,
            textColor: theme.textColor,
            mutedColor: theme.mutedTextColor,
            backgroundBytes: data.backgroundBytes,
            backgroundPixelWidth: data.backgroundPixelWidth,
            backgroundPixelHeight: data.backgroundPixelHeight,
          ),
          const SizedBox(height: 22),
        ],
        if (data.zones.isEmpty)
          _EmptyPanel(
            theme: theme,
            title: 'Aucune zone configurée',
            description: 'Ajoute une zone au plan de ce parking.',
          )
        else
          for (final zone in data.zones) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${zone.name} (${zone.code})',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${data.spaces.where((space) => space.parkingZoneId == zone.id).length} places',
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final space in data.spaces.where(
                  (item) => item.parkingZoneId == zone.id,
                ))
                  _SpaceTile(
                    space: space,
                    selected: space.id == selectedSpace?.id,
                    theme: theme,
                    color: _stateColor(states[space.id]!, theme),
                    label: _stateLabel(states[space.id]!),
                    onPressed: () => setState(() {
                      _selectedSpaceId = space.id;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        if (selectedSpace != null)
          _SpaceInspector(
            space: selectedSpace,
            assignment: selectedAssignment,
            theme: theme,
            stateLabel: _stateLabel(states[selectedSpace.id]!),
            stateColor: _stateColor(states[selectedSpace.id]!, theme),
          ),
        const SizedBox(height: 12),
        _PlanLegend(theme: theme, stateColor: _stateColor),
      ],
    );
  }
}


class _ParkingPlanPreview extends StatefulWidget {
  final ParkingLayout layout;
  final List<ParkingZone> zones;
  final List<ParkingSpace> spaces;
  final Map<String, _SpaceDisplayState> states;
  final String? selectedSpaceId;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final Uint8List? backgroundBytes;
  final int? backgroundPixelWidth;
  final int? backgroundPixelHeight;

  const _ParkingPlanPreview({
    required this.layout,
    required this.zones,
    required this.spaces,
    required this.states,
    required this.selectedSpaceId,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.backgroundBytes,
    required this.backgroundPixelWidth,
    required this.backgroundPixelHeight,
  });

  @override
  State<_ParkingPlanPreview> createState() => _ParkingPlanPreviewState();
}

class _ParkingPlanPreviewState extends State<_ParkingPlanPreview> {
  ui.Image? _backgroundImage;
  int _decodeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _decodeBackground();
  }

  @override
  void didUpdateWidget(covariant _ParkingPlanPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.backgroundBytes, widget.backgroundBytes)) {
      if (widget.backgroundBytes == null) {
        _decodeGeneration++;
        _backgroundImage?.dispose();
        _backgroundImage = null;
      } else {
        _decodeBackground();
      }
    }
  }

  Future<void> _decodeBackground() async {
    final generation = ++_decodeGeneration;
    final bytes = widget.backgroundBytes;
    if (bytes == null || bytes.isEmpty) return;

    ui.Image? decodedImage;
    ui.Codec? codec;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final sourceWidth = widget.backgroundPixelWidth ?? descriptor.width;
      final sourceHeight = widget.backgroundPixelHeight ?? descriptor.height;
      final longestSide = math.max(sourceWidth, sourceHeight);
      final decodeScale = math.min(1.0, 2400 / longestSide);
      final targetWidth =
          math.max(1, (sourceWidth * decodeScale).round()).toInt();
      final targetHeight =
          math.max(1, (sourceHeight * decodeScale).round()).toInt();
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      decodedImage = frame.image;
    } catch (_) {
      decodedImage?.dispose();
      return;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }

    if (!mounted || generation != _decodeGeneration) {
      decodedImage.dispose();
      return;
    }
    final previous = _backgroundImage;
    setState(() => _backgroundImage = decodedImage);
    previous?.dispose();
  }

  @override
  void dispose() {
    _decodeGeneration++;
    _backgroundImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        final ratio = widget.layout.widthM / widget.layout.heightM;
        final height = (width / ratio).clamp(220.0, 420.0).toDouble();
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: _ParkingPlanPainter(
                layout: widget.layout,
                canvasDocument:
                    ParkingCanvasDocument.fromJsonString(widget.layout.layersJson),
                zones: widget.zones,
                spaces: widget.spaces,
                states: widget.states,
                selectedSpaceId: widget.selectedSpaceId,
                primaryColor: widget.primaryColor,
                backgroundColor: widget.backgroundColor,
                borderColor: widget.borderColor,
                textColor: widget.textColor,
                mutedColor: widget.mutedColor,
                backgroundImage: _backgroundImage,
                backgroundPixelWidth: widget.backgroundPixelWidth,
                backgroundPixelHeight: widget.backgroundPixelHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParkingPlanPainter extends CustomPainter {
  final ParkingLayout layout;
  final ParkingCanvasDocument canvasDocument;
  final List<ParkingZone> zones;
  final List<ParkingSpace> spaces;
  final Map<String, _SpaceDisplayState> states;
  final String? selectedSpaceId;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final ui.Image? backgroundImage;
  final int? backgroundPixelWidth;
  final int? backgroundPixelHeight;

  _ParkingPlanPainter({
    required this.layout,
    required this.canvasDocument,
    required this.zones,
    required this.spaces,
    required this.states,
    required this.selectedSpaceId,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.backgroundImage,
    required this.backgroundPixelWidth,
    required this.backgroundPixelHeight,
  });

  Color _canvasTokenColor(String? token) {
    switch (token) {
      case 'primary':
        return primaryColor;
      case 'success':
        return const Color(0xFF24B47E);
      case 'warning':
        return const Color(0xFFE3A33D);
      case 'danger':
        return const Color(0xFFE05B67);
      case 'border':
        return borderColor;
      case 'muted':
        return mutedColor;
      case 'text':
        return textColor;
      case 'surface':
        return backgroundColor;
      default:
        return primaryColor;
    }
  }

  Color _spaceColor(_SpaceDisplayState state) {
    switch (state) {
      case _SpaceDisplayState.free:
        return const Color(0xFF24B47E);
      case _SpaceDisplayState.occupied:
        return primaryColor;
      case _SpaceDisplayState.reserved:
        return const Color(0xFFE3A33D);
      case _SpaceDisplayState.blocked:
        return const Color(0xFFE05B67);
      case _SpaceDisplayState.maintenance:
        return const Color(0xFF8B8FA3);
    }
  }

  List<ParkingPoint> _spacePoints(ParkingSpace space) {
    if (space.polygon != null) return space.polygon!.points;

    final geometry = space.rectangle!;
    final angle = geometry.rotationDegrees * math.pi / 180;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final halfWidth = geometry.width / 2;
    final halfLength = geometry.length / 2;
    final corners = [
      ParkingPoint(x: -halfWidth, y: -halfLength),
      ParkingPoint(x: halfWidth, y: -halfLength),
      ParkingPoint(x: halfWidth, y: halfLength),
      ParkingPoint(x: -halfWidth, y: halfLength),
    ];
    return [
      for (final point in corners)
        ParkingPoint(
          x: geometry.centerX + point.x * cosine - point.y * sine,
          y: geometry.centerY + point.x * sine + point.y * cosine,
        ),
    ];
  }

  ui.Offset _screenPoint(
    ParkingPoint point, {
    required double originX,
    required double originY,
    required double scale,
  }) {
    return ui.Offset(
      originX + point.x * scale,
      originY + (layout.heightM - point.y) * scale,
    );
  }

  ui.Path _pathForPoints(
    List<ParkingPoint> points, {
    required double originX,
    required double originY,
    required double scale,
  }) {
    final path = ui.Path();
    if (points.isEmpty) return path;
    final first = _screenPoint(
      points.first,
      originX: originX,
      originY: originY,
      scale: scale,
    );
    path.moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      final screen = _screenPoint(
        point,
        originX: originX,
        originY: originY,
        scale: scale,
      );
      path.lineTo(screen.dx, screen.dy);
    }
    return path..close();
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    const padding = 18.0;
    final scale = math.min(
      (size.width - padding * 2) / layout.widthM,
      (size.height - padding * 2) / layout.heightM,
    ).toDouble();
    if (!scale.isFinite || scale <= 0) return;

    final planWidth = layout.widthM * scale;
    final planHeight = layout.heightM * scale;
    final originX = (size.width - planWidth) / 2;
    final originY = (size.height - planHeight) / 2;
    final planRect = ui.Rect.fromLTWH(
      originX,
      originY,
      planWidth,
      planHeight,
    );

    canvas.drawRect(
      planRect,
      ui.Paint()
        ..color = backgroundColor.withValues(alpha: .35)
        ..style = ui.PaintingStyle.fill,
    );
    final image = backgroundImage;
    final transform = layout.backgroundTransform;
    ParkingCanvasLayer? backgroundLayer;
    for (final layer in canvasDocument.layers) {
      if (layer.type == ParkingCanvasLayerType.background) {
        backgroundLayer = layer;
        break;
      }
    }
    final showBackground = backgroundLayer?.visible ?? true;
    if (image != null && transform != null && showBackground) {
      final metersPerPixel =
          transform.calibration?.metersPerPixel ?? transform.metersPerPixel;
      final sourceWidth =
          (backgroundPixelWidth ?? image.width).toDouble();
      final sourceHeight =
          (backgroundPixelHeight ?? image.height).toDouble();
      final imageCenterWorld = transform.imageToWorld(
        ParkingPoint(
          x: sourceWidth / 2,
          y: sourceHeight / 2,
        ),
      );
      final imageCenterScreen = _screenPoint(
        imageCenterWorld,
        originX: originX,
        originY: originY,
        scale: scale,
      );
      final imageWidthScreen = sourceWidth * metersPerPixel * scale;
      final imageHeightScreen = sourceHeight * metersPerPixel * scale;
      canvas.save();
      canvas.clipRect(planRect);
      canvas.translate(imageCenterScreen.dx, imageCenterScreen.dy);
      canvas.rotate(-transform.rotationDegrees * math.pi / 180);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        ui.Rect.fromLTWH(
          -imageWidthScreen / 2,
          -imageHeightScreen / 2,
          imageWidthScreen,
          imageHeightScreen,
        ),
        ui.Paint()
          ..color = ui.Color.fromARGB(
            (transform.opacity * 255).round(),
            255,
            255,
            255,
          )
          ..filterQuality = ui.FilterQuality.medium,
      );
      canvas.restore();
    }

    canvas.drawRect(
      planRect,
      ui.Paint()
        ..color = borderColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final gridStep = math.max(
      5.0,
      math.max(layout.widthM, layout.heightM) / 20,
    ).toDouble();
    final gridPaint = ui.Paint()
      ..color = borderColor.withValues(alpha: .38)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = .65;
    for (var x = gridStep; x < layout.widthM; x += gridStep) {
      final screenX = originX + x * scale;
      canvas.drawLine(
        ui.Offset(screenX, originY),
        ui.Offset(screenX, originY + planHeight),
        gridPaint,
      );
    }
    for (var y = gridStep; y < layout.heightM; y += gridStep) {
      final screenY = originY + (layout.heightM - y) * scale;
      canvas.drawLine(
        ui.Offset(originX, screenY),
        ui.Offset(originX + planWidth, screenY),
        gridPaint,
      );
    }

    final zoneFill = ui.Paint()
      ..color = primaryColor.withValues(alpha: .035)
      ..style = ui.PaintingStyle.fill;
    final zoneStroke = ui.Paint()
      ..color = primaryColor.withValues(alpha: .45)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final zone in zones) {
      final boundary = zone.boundary;
      if (boundary == null) continue;
      final path = _pathForPoints(
        boundary.points,
        originX: originX,
        originY: originY,
        scale: scale,
      );
      canvas.drawPath(path, zoneFill);
      canvas.drawPath(path, zoneStroke);
    }

    for (final space in spaces) {
      final points = _spacePoints(space);
      final path = _pathForPoints(
        points,
        originX: originX,
        originY: originY,
        scale: scale,
      );
      final color = _spaceColor(
        states[space.id] ?? _SpaceDisplayState.blocked,
      );
      final selected = space.id == selectedSpaceId;

      canvas.drawPath(
        path,
        ui.Paint()
          ..color = color.withValues(alpha: selected ? .30 : .16)
          ..style = ui.PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = selected ? primaryColor : color
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = selected ? 2.2 : 1.1,
      );

      var minX = double.infinity;
      var minY = double.infinity;
      var maxX = double.negativeInfinity;
      var maxY = double.negativeInfinity;
      var centerX = 0.0;
      var centerY = 0.0;
      for (final point in points) {
        final screen = _screenPoint(
          point,
          originX: originX,
          originY: originY,
          scale: scale,
        );
        minX = math.min(minX, screen.dx).toDouble();
        minY = math.min(minY, screen.dy).toDouble();
        maxX = math.max(maxX, screen.dx).toDouble();
        maxY = math.max(maxY, screen.dy).toDouble();
        centerX += screen.dx;
        centerY += screen.dy;
      }
      final boundsWidth = maxX - minX;
      final boundsHeight = maxY - minY;
      if (boundsWidth < 36 || boundsHeight < 19) continue;

      final label = TextPainter(
        text: TextSpan(
          text: space.code,
          style: TextStyle(
            color: textColor,
            fontSize: math.min(11.0, math.max(8.0, boundsHeight / 2.2)).toDouble(),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: boundsWidth - 6);
      label.paint(
        canvas,
        ui.Offset(
          centerX / points.length - label.width / 2,
          centerY / points.length - label.height / 2,
        ),
      );
    }

    for (final layer in canvasDocument.layers) {
      if (!layer.visible) continue;
      for (final object in layer.objects) {
        if (!object.visible || object.points.isEmpty) continue;
        final closed = object.type == ParkingCanvasObjectType.rectangle ||
            object.type == ParkingCanvasObjectType.polygon ||
            object.type == ParkingCanvasObjectType.obstacle;
        final path = _pathForPoints(
          object.points,
          originX: originX,
          originY: originY,
          scale: scale,
        );
        final strokeColor = _canvasTokenColor(object.strokeColorToken);
        if (closed && object.fillColorToken != null) {
          canvas.drawPath(
            path,
            ui.Paint()
              ..color = _canvasTokenColor(object.fillColorToken)
                  .withValues(alpha: .18)
              ..style = ui.PaintingStyle.fill,
          );
        }
        canvas.drawPath(
          path,
          ui.Paint()
            ..color = strokeColor
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, object.strokeWidthM * scale)
                .toDouble()
            ..strokeCap = ui.StrokeCap.round
            ..strokeJoin = ui.StrokeJoin.round,
        );
        final label = object.label ??
            (object.type == ParkingCanvasObjectType.dimension
                ? '${object.bounds.width.toStringAsFixed(2)} m'
                : null);
        if (label != null && label.isNotEmpty) {
          final anchor = _screenPoint(
            object.points.first,
            originX: originX,
            originY: originY,
            scale: scale,
          );
          final textPainter = TextPainter(
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: strokeColor,
                fontSize: (object.textHeightM ?? 0.5) * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            maxLines: 2,
            ellipsis: '…',
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: 220);
          textPainter.paint(
            canvas,
            anchor.translate(-textPainter.width / 2, -textPainter.height / 2),
          );
        }
      }
    }

    final sizeLabel = '${layout.widthM.toStringAsFixed(1)} × '
        '${layout.heightM.toStringAsFixed(1)} m';
    final labelPainter = TextPainter(
      text: TextSpan(
        text: sizeLabel,
        style: TextStyle(color: mutedColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 8);
    labelPainter.paint(
      canvas,
      ui.Offset(
        size.width - labelPainter.width - 4,
        size.height - labelPainter.height - 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ParkingPlanPainter oldDelegate) => true;
}


class _CalibratedBackgroundResult {
  final ParkingBackgroundCalibration calibration;
  final double rotationDegrees;

  const _CalibratedBackgroundResult({
    required this.calibration,
    required this.rotationDegrees,
  });
}

class _CalibrateBackgroundDialog extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;
  final int pixelWidth;
  final int pixelHeight;

  const _CalibrateBackgroundDialog({
    required this.bytes,
    required this.fileName,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  @override
  State<_CalibrateBackgroundDialog> createState() =>
      _CalibrateBackgroundDialogState();
}

class _CalibrateBackgroundDialogState
    extends State<_CalibrateBackgroundDialog> {
  final _distanceController = TextEditingController(text: '5.00');
  ui.Offset? _first;
  ui.Offset? _second;
  ParkingRowOrientation _referenceAxis = ParkingRowOrientation.horizontal;
  String? _error;

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  void _onImageTap(ui.Offset localPosition, ui.Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final point = ui.Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
    setState(() {
      if (_first == null || _second != null) {
        _first = point;
        _second = null;
      } else {
        _second = point;
      }
      _error = null;
    });
  }

  void _submit() {
    final first = _first;
    final second = _second;
    final distance = double.tryParse(
      _distanceController.text.trim().replaceAll(',', '.'),
    );
    if (first == null || second == null) {
      setState(() => _error = 'Sélectionne les deux points de référence.');
      return;
    }
    if (distance == null || !distance.isFinite || distance <= 0) {
      setState(() => _error = 'La distance réelle doit être positive.');
      return;
    }

    final calibration = ParkingBackgroundCalibration(
      firstPixel: ParkingPoint(
        x: first.dx * widget.pixelWidth,
        y: first.dy * widget.pixelHeight,
      ),
      secondPixel: ParkingPoint(
        x: second.dx * widget.pixelWidth,
        y: second.dy * widget.pixelHeight,
      ),
      realDistanceM: distance,
    );
    try {
      calibration.validate();
      final metersPerPixel = calibration.metersPerPixel;
      if (!metersPerPixel.isFinite || metersPerPixel <= 0) {
        throw ArgumentError('Échelle de calibration invalide.');
      }
      final pixelDx =
          calibration.secondPixel.x - calibration.firstPixel.x;
      final pixelDy =
          calibration.secondPixel.y - calibration.firstPixel.y;
      // Pixel Y grows downwards. Convert the measured vector to the plan's
      // Y-up axis, then rotate it onto the selected plan axis.
      final currentAngle = math.atan2(-pixelDy, pixelDx);
      final targetAngle = _referenceAxis == ParkingRowOrientation.horizontal
          ? 0.0
          : math.pi / 2;
      double normalizeAngle(double angle) =>
          ((angle + math.pi) % (2 * math.pi)) - math.pi;
      final positiveAxisRotation =
          normalizeAngle(targetAngle - currentAngle);
      final oppositeAxisRotation =
          normalizeAngle(targetAngle + math.pi - currentAngle);
      final selectedRotation =
          positiveAxisRotation.abs() <= oppositeAxisRotation.abs()
              ? positiveAxisRotation
              : oppositeAxisRotation;
      final rotationDegrees = selectedRotation * 180 / math.pi;
      Navigator.of(context).pop(
        _CalibratedBackgroundResult(
          calibration: calibration,
          rotationDegrees: rotationDegrees,
        ),
      );
    } on ArgumentError catch (error) {
      setState(() => _error = error.message?.toString() ??
          'Les deux points doivent être distincts.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = (MediaQuery.sizeOf(context).width - 64)
        .clamp(260.0, 620.0)
        .toDouble();

    return ContentDialog(
      title: const Text('Calibrer le fond de plan'),
      content: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.68,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FluentTheme.of(context).typography.caption,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tape deux points dont tu connais la distance réelle '
                  '(par exemple deux poteaux ou deux angles mesurés).',
                ),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: widget.pixelWidth / widget.pixelHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imageSize = ui.Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            _onImageTap(details.localPosition, imageSize),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: FluentTheme.of(context).resources
                                  .controlStrokeColorDefault,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                widget.bytes,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                cacheWidth: widget.pixelWidth > 2400
                                    ? 2400
                                    : widget.pixelWidth,
                                cacheHeight: widget.pixelHeight > 2400
                                    ? 2400
                                    : widget.pixelHeight,
                              ),
                              CustomPaint(
                                painter: _CalibrationMarkerPainter(
                                  first: _first,
                                  second: _second,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _first == null
                      ? 'Point 1 : non sélectionné'
                      : _second == null
                          ? 'Point 1 sélectionné — choisis le point 2'
                          : 'Deux points sélectionnés',
                  style: FluentTheme.of(context).typography.caption,
                ),
                const SizedBox(height: 12),
                const Text('Orientation de la distance de référence'),
                const SizedBox(height: 5),
                ComboBox<ParkingRowOrientation>(
                  value: _referenceAxis,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: ParkingRowOrientation.horizontal,
                      child: Text('Aligner horizontalement'),
                    ),
                    ComboBoxItem(
                      value: ParkingRowOrientation.vertical,
                      child: Text('Aligner verticalement'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _referenceAxis =
                        value ?? ParkingRowOrientation.horizontal;
                  }),
                ),
                const SizedBox(height: 12),
                const Text('Distance réelle entre les deux points (mètres)'),
                const SizedBox(height: 5),
                TextBox(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                const InfoBar(
                  title: Text('Précision de la calibration'),
                  content: Text(
                    'Choisis deux repères éloignés l’un de l’autre. '
                    'Une mesure imprécise faussera toutes les dimensions '
                    'du plan.',
                  ),
                  severity: InfoBarSeverity.info,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  InfoBar(
                    title: Text(_error!),
                    severity: InfoBarSeverity.error,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Valider la calibration'),
        ),
      ],
    );
  }
}

class _CalibrationMarkerPainter extends CustomPainter {
  final ui.Offset? first;
  final ui.Offset? second;

  const _CalibrationMarkerPainter({
    required this.first,
    required this.second,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    ui.Offset toScreen(ui.Offset point) =>
        ui.Offset(point.dx * size.width, point.dy * size.height);

    final firstPoint = first == null ? null : toScreen(first!);
    final secondPoint = second == null ? null : toScreen(second!);

    if (firstPoint != null && secondPoint != null) {
      canvas.drawLine(
        firstPoint,
        secondPoint,
        ui.Paint()
          ..color = const Color(0xFF00A7E1)
          ..strokeWidth = 2.5,
      );
    }

    void drawMarker(ui.Offset? point, String label) {
      if (point == null) return;
      canvas.drawCircle(
        point,
        10,
        ui.Paint()
          ..color = const Color(0xFF00A7E1)
          ..style = ui.PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        10,
        ui.Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        point - ui.Offset(painter.width / 2, painter.height / 2),
      );
    }

    drawMarker(firstPoint, '1');
    drawMarker(secondPoint, '2');
  }

  @override
  bool shouldRepaint(covariant _CalibrationMarkerPainter oldDelegate) =>
      oldDelegate.first != first || oldDelegate.second != second;
}

class _ParkingSetupInput {
  final String siteName;
  final String siteCode;
  final String parkingName;
  final String parkingCode;
  final int rowCount;
  final int spacesPerRow;
  final double spaceWidthM;
  final double spaceLengthM;
  final double spaceGapM;
  final double rowGapM;
  final String zoneCode;
  final String rowPrefix;
  final ParkingRowOrientation orientation;

  const _ParkingSetupInput({
    required this.siteName,
    required this.siteCode,
    required this.parkingName,
    required this.parkingCode,
    required this.rowCount,
    required this.spacesPerRow,
    required this.spaceWidthM,
    required this.spaceLengthM,
    required this.spaceGapM,
    required this.rowGapM,
    required this.zoneCode,
    required this.rowPrefix,
    required this.orientation,
  });
}

class _CreateParkingDialog extends StatefulWidget {
  const _CreateParkingDialog();

  @override
  State<_CreateParkingDialog> createState() => _CreateParkingDialogState();
}

class _CreateParkingDialogState extends State<_CreateParkingDialog> {
  final _siteName = TextEditingController();
  final _siteCode = TextEditingController(text: 'SITE-01');
  final _parkingName = TextEditingController(text: 'Parking principal');
  final _parkingCode = TextEditingController(text: 'P-01');
  final _rows = TextEditingController(text: '3');
  final _spacesPerRow = TextEditingController(text: '8');
  final _spaceWidth = TextEditingController(text: '2.50');
  final _spaceLength = TextEditingController(text: '5.00');
  final _spaceGap = TextEditingController(text: '0.35');
  final _rowGap = TextEditingController(text: '6.00');
  final _zoneCode = TextEditingController(text: 'A');
  final _rowPrefix = TextEditingController(text: 'A');
  ParkingRowOrientation _orientation = ParkingRowOrientation.horizontal;
  bool _advanced = false;
  String? _error;

  @override
  void dispose() {
    _siteName.dispose();
    _siteCode.dispose();
    _parkingName.dispose();
    _parkingCode.dispose();
    _rows.dispose();
    _spacesPerRow.dispose();
    _spaceWidth.dispose();
    _spaceLength.dispose();
    _spaceGap.dispose();
    _rowGap.dispose();
    _zoneCode.dispose();
    _rowPrefix.dispose();
    super.dispose();
  }

  void _submit() {
    final siteName = _siteName.text.trim();
    final siteCode = _siteCode.text.trim();
    final parkingName = _parkingName.text.trim();
    final parkingCode = _parkingCode.text.trim();
    final zoneCode = _zoneCode.text.trim();
    final rowPrefix = _rowPrefix.text.trim();
    final rows = int.tryParse(_rows.text.trim());
    final spaces = int.tryParse(_spacesPerRow.text.trim());
    final width = double.tryParse(_spaceWidth.text.trim().replaceAll(',', '.'));
    final length =
        double.tryParse(_spaceLength.text.trim().replaceAll(',', '.'));
    final gap =
        double.tryParse(_spaceGap.text.trim().replaceAll(',', '.'));
    final rowGap =
        double.tryParse(_rowGap.text.trim().replaceAll(',', '.'));

    if (siteName.isEmpty ||
        siteCode.isEmpty ||
        parkingName.isEmpty ||
        parkingCode.isEmpty ||
        zoneCode.isEmpty ||
        rowPrefix.isEmpty) {
      setState(() => _error = 'Renseigne le site et le parking.');
      return;
    }
    if (zoneCode.length > 40 ||
        rowPrefix.length > 30 ||
        zoneCode.contains('/') ||
        rowPrefix.contains('/') ||
        zoneCode.contains(String.fromCharCode(92)) ||
        rowPrefix.contains(String.fromCharCode(92))) {
      setState(() => _error = 'Vérifie le code de zone et le préfixe de rangée.');
      return;
    }
    if (rows == null || rows < 1 || rows > 40 ||
        spaces == null || spaces < 1 || spaces > 100 ||
        rows * spaces > 1000) {
      setState(() => _error =
          'Le nombre de rangées et de places est invalide (maximum 1 000 places).');
      return;
    }
    if (width == null ||
        length == null ||
        gap == null ||
        rowGap == null ||
        !width.isFinite ||
        !length.isFinite ||
        !gap.isFinite ||
        !rowGap.isFinite ||
        width <= 0 ||
        length <= 0 ||
        gap < 0 ||
        rowGap < 0 ||
        width > 10 ||
        length > 20 ||
        gap > 5 ||
        rowGap > 20) {
      setState(() => _error = 'Vérifie les dimensions en mètres.');
      return;
    }
    Navigator.of(context).pop(
      _ParkingSetupInput(
        siteName: siteName,
        siteCode: siteCode,
        parkingName: parkingName,
        parkingCode: parkingCode,
        rowCount: rows,
        spacesPerRow: spaces,
        spaceWidthM: _advanced ? width : 2.5,
        spaceLengthM: _advanced ? length : 5,
        spaceGapM: _advanced ? gap : 0.35,
        rowGapM: _advanced ? rowGap : 6,
        zoneCode: _advanced ? zoneCode : 'A',
        rowPrefix: _advanced ? rowPrefix : 'A',
        orientation: _advanced
            ? _orientation
            : ParkingRowOrientation.horizontal,
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        TextBox(
          controller: controller,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ContentDialog(
      title: const Text('Créer un parking'),
      content: SizedBox(
        width: width < 600 ? width * 0.82 : 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mode guidé',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Décris ton site et le nombre de places. Parcoto prépare '
                'automatiquement les rangées et le plan.',
                style: FluentTheme.of(context).typography.caption,
              ),
              const SizedBox(height: 14),
              _field('Nom du site', _siteName),
              const SizedBox(height: 10),
              _field('Code du site', _siteCode),
              const SizedBox(height: 10),
              _field('Nom du parking', _parkingName),
              const SizedBox(height: 10),
              _field('Code du parking', _parkingCode),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _field('Rangées', _rows, numeric: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field('Places par rangée', _spacesPerRow,
                        numeric: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Button(
                onPressed: () => setState(() {
                  _advanced = !_advanced;
                  _error = null;
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _advanced ? FluentIcons.chevron_up : FluentIcons.settings,
                      size: 13,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _advanced
                          ? 'Masquer les réglages avancés'
                          : 'Personnalisation avancée',
                    ),
                  ],
                ),
              ),
              if (_advanced) ...[
                const SizedBox(height: 12),
                const Text(
                  'Géométrie et codification',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field('Code de zone', _zoneCode)),
                    const SizedBox(width: 10),
                    Expanded(child: _field('Préfixe des rangées', _rowPrefix)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Orientation des rangées'),
                const SizedBox(height: 4),
                ComboBox<ParkingRowOrientation>(
                  value: _orientation,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: ParkingRowOrientation.horizontal,
                      child: Text('Horizontale'),
                    ),
                    ComboBoxItem(
                      value: ParkingRowOrientation.vertical,
                      child: Text('Verticale'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _orientation =
                        value ?? ParkingRowOrientation.horizontal;
                  }),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dimensions et espacements — en mètres',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _field('Largeur', _spaceWidth, numeric: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field('Longueur', _spaceLength, numeric: true),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _field('Écart entre places', _spaceGap,
                          numeric: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field('Écart entre rangées', _rowGap,
                          numeric: true),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                InfoBar(
                  title: Text(_error!),
                  severity: InfoBarSeverity.error,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Générer le plan'),
        ),
      ],
    );
  }
}

class _LocalStorageNotice extends StatelessWidget {
  final AppTheme theme;
  const _LocalStorageNotice({required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.color.withValues(alpha: .08),
          border: Border.all(color: theme.color.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(theme.cardRadius),
        ),
        child: Row(
          children: [
            Icon(FluentIcons.info, color: theme.color, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Configuration enregistrée localement sur cet appareil. '
                'La synchronisation Appwrite Parking n’est pas encore déployée.',
                style: TextStyle(color: theme.textColor, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _EmptyPanel extends StatelessWidget {
  final AppTheme theme;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyPanel({
    required this.theme,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border.all(color: theme.borderColor),
          borderRadius: BorderRadius.circular(theme.cardRadius),
        ),
        child: Column(
          children: [
            Icon(
              FluentIcons.car,
              color: theme.mutedTextColor,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 12,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final AppTheme theme;
  final IconData icon;
  final Color? accent;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.theme,
    required this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? theme.mutedTextColor;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border.all(color: theme.borderColor),
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: TextStyle(color: theme.mutedTextColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  final ParkingSpace space;
  final bool selected;
  final AppTheme theme;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _SpaceTile({
    required this.space,
    required this.selected,
    required this.theme,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 104,
        height: 82,
        child: Button(
          onPressed: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? .17 : .08),
              border: Border.all(
                color: selected ? color : theme.borderColor,
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SpaceInspector extends StatelessWidget {
  final ParkingSpace space;
  final VehicleParkingAssignment? assignment;
  final AppTheme theme;
  final String stateLabel;
  final Color stateColor;

  const _SpaceInspector({
    required this.space,
    required this.assignment,
    required this.theme,
    required this.stateLabel,
    required this.stateColor,
  });

  @override
  Widget build(BuildContext context) {
    final geometry = space.rectangle;
    final dimensions = geometry == null
        ? 'Forme polygonale'
        : '${geometry.width.toStringAsFixed(2)} × '
            '${geometry.length.toStringAsFixed(2)} m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border.all(color: theme.borderColor),
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Détail de la place',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    color: stateColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            space.code,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _InspectorLine(label: 'Type', value: space.type.name, theme: theme),
          _InspectorLine(label: 'Rangée', value: space.rowCode ?? '—', theme: theme),
          _InspectorLine(label: 'Dimensions', value: dimensions, theme: theme),
          _InspectorLine(
            label: 'Véhicule',
            value: assignment?.vehicleId ?? 'Aucun',
            theme: theme,
          ),
          if (assignment != null)
            _InspectorLine(
              label: 'Depuis',
              value: assignment!.startAt.toLocal().toString().substring(0, 16),
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _InspectorLine extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme theme;

  const _InspectorLine({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PlanLegend extends StatelessWidget {
  final AppTheme theme;
  final Color Function(_SpaceDisplayState, AppTheme) stateColor;

  const _PlanLegend({required this.theme, required this.stateColor});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_SpaceDisplayState.free, 'Libre'),
      (_SpaceDisplayState.occupied, 'Occupée'),
      (_SpaceDisplayState.reserved, 'Réservée'),
      (_SpaceDisplayState.blocked, 'Bloquée'),
      (_SpaceDisplayState.maintenance, 'Maintenance'),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: stateColor(item.$1, theme),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.$2,
                style: TextStyle(color: theme.mutedTextColor, fontSize: 10),
              ),
            ],
          ),
      ],
    );
  }
}
