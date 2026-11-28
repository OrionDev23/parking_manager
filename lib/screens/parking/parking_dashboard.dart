import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../core/services/parking_services.dart';
import '../../domain/parking/parking_geometry.dart';
import '../../domain/parking/parking_models.dart';
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

  const _ParkingSnapshot({
    required this.sites,
    required this.lots,
    required this.selectedLot,
    required this.layouts,
    required this.zones,
    required this.spaces,
    required this.assignments,
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

    return _ParkingSnapshot(
      sites: sites,
      lots: lots,
      selectedLot: selected,
      layouts: layouts,
      zones: zones,
      spaces: spaces,
      assignments: assignments,
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
      final suffix = '-' + suffixNumber.toString().padLeft(2, '0');
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
      final widthM = margin * 2 +
          input.spacesPerRow * input.spaceWidthM +
          (input.spacesPerRow - 1) * input.spaceGapM;
      final heightM = margin * 2 +
          input.rowCount * input.spaceLengthM +
          (input.rowCount - 1) * input.rowGapM;

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
        code: 'A',
        name: 'Zone A',
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
        final rowCode = 'A' + (rowIndex + 1).toString();
        final generated = rowGenerator.generate(
          ParkingRowSpec(
            zoneCode: 'A',
            rowCode: rowCode,
            spacePrefix: rowCode + '-',
            count: input.spacesPerRow,
            numberPadding: 3,
            anchorX: margin + input.spaceWidthM / 2,
            anchorY: margin +
                input.spaceLengthM / 2 +
                rowIndex * (input.spaceLengthM + input.rowGapM),
            spaceWidth: input.spaceWidthM,
            spaceLength: input.spaceLengthM,
            gap: input.spaceGapM,
            orientation: ParkingRowOrientation.horizontal,
          ),
        );
        for (final generatedSpace in generated) {
          final ordinal = spaces.length + 1;
          spaces.add(
            ParkingSpace(
              id: 'space_' + stamp + '_' + ordinal.toString(),
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
        builder: (context, close) => const InfoBar(
          title: Text('Parking créé'),
          content: Text(
            'Code du site : ' + site.code + '. Le plan et ses places sont '
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
                  FilledButton(
                    onPressed: services == null ? null : _createParking,
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
                        actionLabel: 'Créer mon premier parking',
                        onAction: _createParking,
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
          'Site : ' + selectedSiteName +
              ' • ' + selectedLot.code + ' • ' + selectedLot.status.name,
          style: TextStyle(color: theme.mutedTextColor, fontSize: 12),
        ),
        if (data.layouts.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            'Plan v' +
                data.layouts.first.version.toString() +
                ' — ' +
                data.layouts.first.widthM.toStringAsFixed(1) +
                ' × ' +
                data.layouts.first.heightM.toStringAsFixed(1) +
                ' m',
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
        const SizedBox(height: 22),
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
                    zone.name + ' (' + zone.code + ')',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  data.spaces
                      .where((space) => space.parkingZoneId == zone.id)
                      .length
                      .toString() +
                      ' places',
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
    super.dispose();
  }

  void _submit() {
    final siteName = _siteName.text.trim();
    final siteCode = _siteCode.text.trim();
    final parkingName = _parkingName.text.trim();
    final parkingCode = _parkingCode.text.trim();
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
        parkingCode.isEmpty) {
      setState(() => _error = 'Renseigne le site et le parking.');
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
        : geometry.width.toStringAsFixed(2) +
            ' × ' +
            geometry.length.toStringAsFixed(2) +
            ' m';

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
