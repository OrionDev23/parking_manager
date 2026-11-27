import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:provider/provider.dart';

import '../../../admin_parameters.dart';
import '../../../batch_import/import_vehicles.dart';
import '../../../theme.dart';
import '../../../ui/design_system/parcoto_surface.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../core/business/fleet_dashboard_status.dart';
import '../../../core/services/vehicle_make_service.dart';
import '../../../utilities/vehicle_util.dart';
import '../../../widgets/forms/parcoto_form_field.dart';
import 'vehicle_details_page.dart';
import 'vehicle_form.dart';

enum _VehicleWorkspaceView { fleet, details, editor }

enum _FleetQuickFilter { all, inService, maintenance }

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => VehicleManagementState();
}

class VehicleManagementState extends State<VehicleManagement>
    with AutomaticKeepAliveClientMixin<VehicleManagement> {
  static ValueNotifier<int> stateChanges = ValueNotifier(0);
  static final ValueNotifier<String?> brandFilterRequest = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> externalSearchRequest =
      ValueNotifier<String?>(null);

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? selectedAssignment;
  String? selectedBrand;
  _FleetQuickFilter _quickFilter = _FleetQuickFilter.all;
  _VehicleWorkspaceView _workspaceView = _VehicleWorkspaceView.fleet;
  Vehicle? _selectedVehicle;
  Vehicle? _editingVehicle;

  @override
  void initState() {
    super.initState();
    selectedBrand = brandFilterRequest.value;
    brandFilterRequest.value = null;
    final initialSearch = externalSearchRequest.value;
    if (initialSearch != null && initialSearch.trim().isNotEmpty) {
      searchQuery = initialSearch.replaceAll('"', '').trim();
      searchController.text = searchQuery;
    }
    externalSearchRequest.value = null;
    externalSearchRequest.addListener(_handleExternalSearchRequest);
    brandFilterRequest.addListener(_handleExternalBrandFilter);
    VehicleMakeService.load().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!VehicleProvider.downloadedVehicles &&
          !VehicleProvider.downloadingVehicles) {
        context.read<VehicleProvider>().refreshVehicles();
      }
    });
  }

  void _handleExternalSearchRequest() {
    final request = externalSearchRequest.value;
    if (!mounted || request == null || request.trim().isEmpty) return;
    final normalized = request.replaceAll('"', '').trim();
    setState(() {
      searchQuery = normalized;
      searchController.text = normalized;
    });
    externalSearchRequest.value = null;
  }

  void _handleExternalBrandFilter() {
    final requestedBrand = brandFilterRequest.value;
    if (!mounted || requestedBrand == null) return;
    setState(() => selectedBrand = requestedBrand);
    brandFilterRequest.value = null;
  }

  @override
  void dispose() {
    externalSearchRequest.removeListener(_handleExternalSearchRequest);
    brandFilterRequest.removeListener(_handleExternalBrandFilter);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_workspaceView == _VehicleWorkspaceView.editor) {
      return VehicleForm(
        vehicle: _editingVehicle,
        onCancel: _cancelEditor,
        onSaved: _handleVehicleSaved,
      );
    }

    context.watch<VehicleProvider>();
    final theme = context.watch<AppTheme>();
    final vehicles = _visibleVehicles();
    final allVehicles = VehicleProvider.vehicles.values.toList();
    final loading = VehicleProvider.downloadingVehicles &&
        VehicleProvider.vehicles.isEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final splitLayout = screenWidth >= 1080;

    // On narrow screens the list and the vehicle sheet are separate views.
    if (!splitLayout &&
        _workspaceView == _VehicleWorkspaceView.details &&
        _selectedVehicle != null) {
      return VehicleDetailsPage(
        vehicle: _selectedVehicle!,
        onEdit: () => _openEditor(_selectedVehicle),
        onBack: _backToFleet,
      );
    }

    Vehicle? selectedVehicle;
    for (final vehicle in vehicles) {
      if (vehicle.id == _selectedVehicle?.id) {
        selectedVehicle = vehicle;
        break;
      }
    }
    // No vehicle is selected by default. The right pane starts in fleet overview mode.
    final activeVehicle = selectedVehicle;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth < 720 ? 16 : 26,
              screenWidth < 720 ? 12 : 14,
              screenWidth < 720 ? 16 : 22,
              8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tooltip(
                      message: 'Actualiser le parc',
                      child: Button(
                        onPressed: VehicleProvider.downloadingVehicles
                            ? null
                            : _refreshVehicles,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.refresh,
                                size: 14, color: theme.mutedTextColor),
                            if (constraints.maxWidth >= 680) ...[
                              const SizedBox(width: 7),
                              const Text('Actualiser'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (showImportVehicles && DatabaseGetter().isAdmin())
                      Button(
                        onPressed: importList,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.open_file, size: 14),
                            SizedBox(width: 7),
                            Text('Importer'),
                          ],
                        ),
                      ),
                    if (screenWidth < 1080)
                      FilledButton(
                        onPressed: _openNewVehicle,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.add, size: 14),
                            SizedBox(width: 7),
                            Text('Ajouter'),
                          ],
                        ),
                      ),
                  ],
                );
                final search = _buildGlobalSearch(theme);

                if (constraints.maxWidth < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _pageTitle(theme),
                      const SizedBox(height: 14),
                      search,
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: actions,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _pageTitle(theme)),
                    const SizedBox(width: 18),
                    SizedBox(width: 260, child: search),
                    const SizedBox(width: 10),
                    actions,
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth < 720 ? 16 : 26),
            child: _buildMetrics(theme, allVehicles),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading
                ? const Center(child: ProgressRing())
                : vehicles.isEmpty
                    ? _buildEmptyState(theme)
                    : splitLayout
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFleetListPane(
                                theme,
                                vehicles,
                                allVehicles,
                                activeVehicle,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 18, bottom: 18),
                                  child: activeVehicle == null
                                      ? _buildFleetOverview(theme, vehicles)
                                      : VehicleDetailsPage(
                                          key: ValueKey(activeVehicle.id),
                                          vehicle: activeVehicle,
                                          onEdit: () => _openEditor(activeVehicle),
                                        ),
                                ),
                              ),
                            ],
                          )
                        : _buildMobileFleetList(theme, vehicles, allVehicles),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSearch(AppTheme theme) {
    return ParcotoTextBox(
      controller: searchController,
      placeholder: 'Rechercher un véhicule...',
      style: theme.writingStyle,
      placeholderStyle: TextStyle(color: theme.mutedTextColor),
      cursorColor: theme.color,
      onChanged: (value) => setState(() => searchQuery = value),
      prefix: const Padding(
        padding: EdgeInsetsDirectional.only(start: 10, end: 6),
        child: Icon(FluentIcons.search, size: 14),
      ),
      suffix: searchQuery.isEmpty
          ? null
          : IconButton(
              icon: const Icon(FluentIcons.cancel, size: 13),
              onPressed: () {
                searchController.clear();
                setState(() => searchQuery = '');
              },
            ),
    );
  }

  Widget _buildFleetListPane(
    AppTheme theme,
    List<Vehicle> vehicles,
    List<Vehicle> allVehicles,
    Vehicle? selectedVehicle,
  ) {
    return SizedBox(
      width: 284,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 18),
        child: ParcotoSurface(
          padding: EdgeInsets.zero,
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Véhicules (${vehicles.length})',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _openNewVehicle,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.add, size: 13),
                          SizedBox(width: 5),
                          Text('Ajouter'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildQuickFilters(theme),
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildFilters(theme, allVehicles),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 1,
                      color: theme.borderColor.withValues(alpha: .55),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return _VehicleListTile(
                      vehicle: vehicle,
                      selected: vehicle.id == selectedVehicle?.id,
                      onTap: () => _openDetails(vehicle),
                      theme: theme,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFleetList(
    AppTheme theme,
    List<Vehicle> vehicles,
    List<Vehicle> allVehicles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Véhicules (${vehicles.length})',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Sélectionnez un véhicule',
                style: TextStyle(color: theme.mutedTextColor, fontSize: 10),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildQuickFilters(theme),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildFilters(theme, allVehicles),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _VehicleListTile(
              vehicle: vehicles[index],
              selected: false,
              onTap: () => _openDetails(vehicles[index]),
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageTitle(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parc automobile',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Retrouvez vos véhicules, leur état et leurs informations essentielles.',
          style: TextStyle(color: theme.mutedTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMetrics(AppTheme theme, List<Vehicle> vehicles) {
    var inService = 0;
    var inMaintenance = 0;
    var immobilized = 0;
    var outsideParking = 0;

    for (final vehicle in vehicles) {
      switch (FleetDashboardStatusMapper.fromLegacyCode(vehicle.etatactuel)) {
        case FleetDashboardStatus.available:
        case FleetDashboardStatus.onMission:
          inService++;
          break;
        case FleetDashboardStatus.workshop:
          inMaintenance++;
          break;
        case FleetDashboardStatus.broken:
          immobilized++;
          break;
        case FleetDashboardStatus.reformed:
        case FleetDashboardStatus.other:
          break;
      }
      // Perimeter 4 is explicitly "horsparking" in Parcoto's existing data.
      if (vehicle.perimetre == 4) outsideParking++;
    }

    final metrics = <({
      String label,
      String value,
      String detail,
      IconData icon,
      Color color,
    })>[
      (
        label: 'Véhicules',
        value: vehicles.length.toString(),
        detail: 'Parc total',
        icon: FluentIcons.car,
        color: theme.color,
      ),
      (
        label: 'En service',
        value: inService.toString(),
        detail: 'Disponibles et en mission',
        icon: FluentIcons.check_mark,
        color: Colors.green,
      ),
      (
        label: 'En maintenance',
        value: inMaintenance.toString(),
        detail: 'Au garage / réparation',
        icon: FluentIcons.repair,
        color: Colors.orange,
      ),
      (
        label: 'Immobilisés',
        value: immobilized.toString(),
        detail: 'Véhicules en panne',
        icon: FluentIcons.blocked,
        color: Colors.red,
      ),
      (
        label: 'Hors parc',
        value: outsideParking.toString(),
        detail: 'Hors du parking',
        icon: FluentIcons.car,
        color: Colors.blue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 540
            ? 2
            : constraints.maxWidth < 900
                ? 3
                : 5;
        const gap = 10.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics.map((metric) {
            return SizedBox(
              width: cardWidth,
              child: ParcotoSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 17),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.mutedTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.value,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 19,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.mutedTextColor,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuickFilters(AppTheme theme) {
    final items = <({String label, _FleetQuickFilter value})>[
      (label: 'Tous', value: _FleetQuickFilter.all),
      (label: 'En service', value: _FleetQuickFilter.inService),
      (label: 'Maintenance', value: _FleetQuickFilter.maintenance),
    ];

    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: _quickFilterButton(
              theme,
              items[index].label,
              items[index].value,
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickFilterButton(
    AppTheme theme,
    String label,
    _FleetQuickFilter value,
  ) {
    final selected = _quickFilter == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _quickFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.color
              : theme.fillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.color : theme.borderColor,
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : theme.textColor,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(AppTheme theme, List<Vehicle> vehicles) {
    final brandIds = vehicles
        .map((vehicle) => VehicleMakeService.canonicalId(vehicle.marque))
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => VehicleMakeService.nameFor(a)
          .compareTo(VehicleMakeService.nameFor(b)));
    final assignments = vehicles
        .map(_assignmentLabel)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final filterWidth = compact ? (constraints.maxWidth - 8) / 2 : 140.0;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: filterWidth,
              child: ComboBox<String?>(
                isExpanded: true,
                value: selectedBrand,
                placeholder: const Text('Marque'),
                items: [
                  const ComboBoxItem<String?>(
                    value: null,
                    child: Text('Toutes les marques'),
                  ),
                  ...brandIds.map(
                    (id) => ComboBoxItem<String?>(
                      value: id,
                      child: Text(
                        VehicleMakeService.nameFor(id),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  selectedBrand = value;
                  brandFilterRequest.value = null;
                }),
              ),
            ),
            SizedBox(
              width: filterWidth,
              child: ComboBox<String?>(
                isExpanded: true,
                value: selectedAssignment,
                placeholder: const Text('Affectation'),
                items: [
                  const ComboBoxItem<String?>(
                    value: null,
                    child: Text('Toutes les affectations'),
                  ),
                  ...assignments.map(
                    (assignment) => ComboBoxItem<String?>(
                      value: assignment,
                      child: Text(
                        assignment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => selectedAssignment = value),
              ),
            ),
            if (selectedBrand != null || selectedAssignment != null)
              Button(
                onPressed: () => setState(() {
                  selectedBrand = null;
                  selectedAssignment = null;
                  _quickFilter = _FleetQuickFilter.all;
                  brandFilterRequest.value = null;
                  externalSearchRequest.value = null;
                }),
                child: const Text('Effacer'),
              ),
          ],
        );
      },
    );
  }

  String _assignmentLabel(Vehicle vehicle) {
    return [
      vehicle.filliale,
      vehicle.direction,
      vehicle.departement,
    ].where((value) => value?.trim().isNotEmpty == true).join(' · ');
  }

  List<Vehicle> _visibleVehicles() {
    final query = searchQuery.trim().toLowerCase();
    return VehicleProvider.vehicles.values.where((vehicle) {
      final canonicalStatus =
          FleetDashboardStatusMapper.fromLegacyCode(vehicle.etatactuel);
      if (_quickFilter == _FleetQuickFilter.inService &&
          canonicalStatus != FleetDashboardStatus.available &&
          canonicalStatus != FleetDashboardStatus.onMission) {
        return false;
      }
      if (_quickFilter == _FleetQuickFilter.maintenance &&
          canonicalStatus != FleetDashboardStatus.workshop) {
        return false;
      }
      if (selectedBrand != null &&
          VehicleMakeService.canonicalId(vehicle.marque) != selectedBrand) {
        return false;
      }
      if (selectedAssignment != null &&
          _assignmentLabel(vehicle) != selectedAssignment) {
        return false;
      }
      if (query.isEmpty) return true;

      final brand = VehiclesUtilities.getMarqueName(vehicle.marque);
      final values = [
        vehicle.matricule,
        vehicle.numeroSerie,
        vehicle.type,
        vehicle.trim,
        brand,
        vehicle.fleetNumber,
        vehicle.matriculeConducteur,
        vehicle.nom,
        vehicle.prenom,
        vehicle.filliale,
        vehicle.direction,
        vehicle.departement,
      ];
      return values.any(
        (value) => value?.toLowerCase().contains(query) == true,
      );
    }).toList()
      ..sort((a, b) => a.matricule.compareTo(b.matricule));
  }

  Widget _buildFleetOverview(
    AppTheme theme,
    List<Vehicle> vehicles,
  ) {
    var available = 0;
    var maintenance = 0;
    var immobilized = 0;
    var other = 0;

    for (final vehicle in vehicles) {
      switch (FleetDashboardStatusMapper.fromLegacyCode(vehicle.etatactuel)) {
        case FleetDashboardStatus.available:
        case FleetDashboardStatus.onMission:
          available++;
          break;
        case FleetDashboardStatus.workshop:
          maintenance++;
          break;
        case FleetDashboardStatus.broken:
          immobilized++;
          break;
        case FleetDashboardStatus.reformed:
        case FleetDashboardStatus.other:
          other++;
          break;
      }
    }

    final total = vehicles.length;
    final statusItems = <({
      String label,
      int count,
      Color color,
      IconData icon,
    })>[
      (label: 'En service', count: available, color: Colors.green, icon: FluentIcons.check_mark),
      (label: 'En maintenance', count: maintenance, color: Colors.orange, icon: FluentIcons.repair),
      (label: 'Immobilisés', count: immobilized, color: Colors.red, icon: FluentIcons.blocked),
      (label: 'Autres états', count: other, color: theme.mutedTextColor, icon: FluentIcons.more),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 18, bottom: 18),
      child: ParcotoSurface(
        padding: const EdgeInsets.all(24),
        elevated: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(FluentIcons.view_dashboard, color: theme.color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vue d’ensemble du parc',
                            style: TextStyle(color: theme.textColor, fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Suivez la situation de votre flotte en un coup d’œil.',
                            style: TextStyle(color: theme.mutedTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.fillColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Text(
                        '$total véhicule${total > 1 ? 's' : ''}',
                        style: TextStyle(color: theme.textColor, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'ÉTAT OPÉRATIONNEL',
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (compact)
                  Column(
                    children: [
                      for (final item in statusItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _fleetStatusRow(theme, item, total),
                        ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < statusItems.length; index++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index == statusItems.length - 1 ? 0 : 12),
                            child: _fleetStatusCard(theme, statusItems[index], total),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(color: theme.color.withValues(alpha: .10), shape: BoxShape.circle),
                          child: Icon(FluentIcons.car, size: 34, color: theme.color),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sélectionnez un véhicule',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textColor, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choisissez un véhicule dans la liste à gauche pour afficher sa fiche complète, ses caractéristiques, son affectation et son historique.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.mutedTextColor, fontSize: 12, height: 1.6),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _fleetFeatureChip(theme, FluentIcons.info, 'Identification'),
                            _fleetFeatureChip(theme, FluentIcons.settings, 'Caractéristiques'),
                            _fleetFeatureChip(theme, FluentIcons.account_management, 'Affectation'),
                            _fleetFeatureChip(theme, FluentIcons.document, 'Historique'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(height: 1, color: theme.borderColor),
                Row(
                  children: [
                    Icon(FluentIcons.info, size: 15, color: theme.mutedTextColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La fiche détaillée s’affichera ici dès que vous sélectionnerez un véhicule.',
                        style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fleetStatusCard(
    AppTheme theme,
    ({String label, int count, Color color, IconData icon}) item,
    int total,
  ) {
    final ratio = total == 0 ? 0.0 : item.count / total;
    return ParcotoSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.count.toString(), style: TextStyle(color: theme.textColor, fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: theme.fillColor),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: constraints.maxWidth * ratio,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: item.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(ratio * 100).round()} % du parc', style: TextStyle(color: theme.mutedTextColor, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _fleetStatusRow(
    AppTheme theme,
    ({String label, int count, Color color, IconData icon}) item,
    int total,
  ) {
    final ratio = total == 0 ? 0.0 : item.count / total;
    return Row(
      children: [
        Icon(item.icon, color: item.color, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(item.label, style: TextStyle(color: theme.textColor, fontSize: 12))),
        Text(item.count.toString(), style: TextStyle(color: theme.textColor, fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(color: theme.fillColor),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: constraints.maxWidth * ratio,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: item.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fleetFeatureChip(AppTheme theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: theme.fillColor,
        border: Border.all(color: theme.borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme) {
    final hasFilters = searchQuery.trim().isNotEmpty ||
        selectedAssignment != null ||
        selectedBrand != null ||
        _quickFilter != _FleetQuickFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ParcotoSurface(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.color.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasFilters ? FluentIcons.search : FluentIcons.car,
                    color: theme.color,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hasFilters
                      ? 'Aucun véhicule ne correspond'
                      : 'Votre parc est encore vide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  hasFilters
                      ? 'Modifiez votre recherche ou réinitialisez les filtres.'
                      : 'Ajoutez votre premier véhicule pour commencer à organiser votre parc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.mutedTextColor,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (hasFilters)
                  Button(
                    onPressed: () => setState(() {
                      searchController.clear();
                      searchQuery = '';
                      selectedAssignment = null;
                      selectedBrand = null;
                      _quickFilter = _FleetQuickFilter.all;
                      brandFilterRequest.value = null;
                      externalSearchRequest.value = null;
                    }),
                    child: const Text('Réinitialiser'),
                  )
                else
                  FilledButton(
                    onPressed: _openNewVehicle,
                    child: const Text('Ajouter un véhicule'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshVehicles() async {
    await context.read<VehicleProvider>().refreshVehicles();
  }

  void _openNewVehicle() => _openEditor();

  void _openEditor([Vehicle? vehicle]) {
    setState(() {
      _editingVehicle = vehicle;
      _selectedVehicle = vehicle;
      _workspaceView = _VehicleWorkspaceView.editor;
    });
  }

  void _openDetails(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _editingVehicle = null;
      _workspaceView = _VehicleWorkspaceView.details;
    });
  }

  void _cancelEditor() {
    setState(() {
      _workspaceView = _editingVehicle == null
          ? _VehicleWorkspaceView.fleet
          : _VehicleWorkspaceView.details;
      if (_workspaceView == _VehicleWorkspaceView.fleet) {
        _selectedVehicle = null;
      }
      _editingVehicle = null;
    });
  }

  void _handleVehicleSaved(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _editingVehicle = null;
      _workspaceView = _VehicleWorkspaceView.details;
    });
    context.read<VehicleProvider>().refreshVehicles();
  }

  void _backToFleet() {
    setState(() {
      _selectedVehicle = null;
      _editingVehicle = null;
      _workspaceView = _VehicleWorkspaceView.fleet;
    });
    context.read<VehicleProvider>().refreshVehicles();
  }

  Future<void> importList() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (pickedFile == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (c) => ImportVehicles(file: pickedFile),
    );
    if (mounted) {
      await context.read<VehicleProvider>().refreshVehicles();
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _VehicleListTile extends StatelessWidget {
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  final AppTheme theme;

  const _VehicleListTile({
    required this.vehicle,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final status = vehicle.etatactuel ?? (conducteurEmploye ? 0 : 5);
    final statusColor = _statusColor(status);
    final brand = VehicleMakeService.nameFor(
      VehicleMakeService.canonicalId(vehicle.marque),
    );
    final model = [
      if (brand.trim().isNotEmpty) brand,
      vehicle.type?.trim() ?? '',
      (vehicle.modelYear ?? vehicle.anneeUtil)?.toString() ?? '',
    ].where((value) => value.isNotEmpty).join(' · ');
    final imageUrl = vehicle.imageUrl?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: selected
                ? theme.color.withValues(alpha: .10)
                : theme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.color.withValues(alpha: .75)
                  : theme.borderColor.withValues(alpha: .65),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: 70,
                  height: 58,
                  child: imageUrl.isEmpty
                      ? _VehicleImagePlaceholder(color: theme.color)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _VehicleImagePlaceholder(color: theme.color),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.matricule,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          FluentIcons.chevron_right,
                          size: 12,
                          color: selected ? theme.color : theme.mutedTextColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      model.isEmpty ? 'Modèle non renseigné' : model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(
                          child: _VehicleStatusBadge(
                            label: VehiclesUtilities.getEtatName(status).tr(),
                            color: statusColor,
                          ),
                        ),
                        if (vehicle.fleetNumber?.trim().isNotEmpty == true) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Parc ${vehicle.fleetNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.mutedTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    if (conducteurEmploye) {
      switch (status) {
        case 0: return Colors.green;
        case 1: return Colors.orange;
        case 2: return Colors.red;
        case 3: return Colors.blue;
        case 4: return Colors.grey;
      }
    } else {
      switch (status) {
        case 5: return Colors.green;
        case 6: return Colors.red;
        case 7: return Colors.orange;
        case 8: return Colors.blue;
      }
    }
    return Colors.grey;
  }
}

class _VehicleImagePlaceholder extends StatelessWidget {
  final Color color;

  const _VehicleImagePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: .16),
            color.withValues(alpha: .035),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          FluentIcons.car,
          size: 58,
          color: color.withValues(alpha: .55),
        ),
      ),
    );
  }
}

class _VehicleStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _VehicleStatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        border: Border.all(color: color.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
