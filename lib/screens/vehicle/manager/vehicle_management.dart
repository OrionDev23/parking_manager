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
import '../../../ui/design_system/parcoto_tokens.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../utilities/vehicle_util.dart';
import '../../../widgets/forms/parcoto_form_field.dart';
import 'vehicle_details_page.dart';
import 'vehicle_form.dart';
import 'vehicle_tabs.dart';

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => VehicleManagementState();
}

class VehicleManagementState extends State<VehicleManagement>
    with AutomaticKeepAliveClientMixin<VehicleManagement> {
  static ValueNotifier<int> stateChanges = ValueNotifier(0);
  static final ValueNotifier<int?> brandFilterRequest = ValueNotifier<int?>(null);
  static final ValueNotifier<String?> externalSearchRequest =
      ValueNotifier<String?>(null);

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  int? selectedState;
  int? selectedBrand;

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
    VehicleTabsState.currentIndex.addListener(_handleEditorTabChanged);
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

  void _handleEditorTabChanged() {
    if (!mounted || VehicleTabsState.currentIndex.value != 0) return;
    context.read<VehicleProvider>().refreshVehicles();
  }

  @override
  void dispose() {
    externalSearchRequest.removeListener(_handleExternalSearchRequest);
    brandFilterRequest.removeListener(_handleExternalBrandFilter);
    VehicleTabsState.currentIndex.removeListener(_handleEditorTabChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    context.watch<VehicleProvider>();
    final theme = context.watch<AppTheme>();
    final vehicles = _visibleVehicles();
    final allVehicles = VehicleProvider.vehicles.values.toList();
    final loading = VehicleProvider.downloadingVehicles &&
        VehicleProvider.vehicles.isEmpty;
    final compact =
        MediaQuery.sizeOf(context).width < ParcotoTokens.mobileBreakpoint;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 26,
              compact ? 18 : 24,
              compact ? 16 : 26,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
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
                                Icon(
                                  FluentIcons.refresh,
                                  size: 14,
                                  color: theme.mutedTextColor,
                                ),
                                if (!compact) ...[
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
                        FilledButton(
                          onPressed: _openNewVehicle,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.add, size: 14),
                              SizedBox(width: 7),
                              Text('Ajouter un véhicule'),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 740) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _pageTitle(theme),
                          const SizedBox(height: 14),
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
                        actions,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMetrics(theme, allVehicles),
                const SizedBox(height: 18),
                _buildFilters(theme, allVehicles),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: ProgressRing())
                : vehicles.isEmpty
                    ? _buildEmptyState(theme)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final maxExtent = constraints.maxWidth < 520
                              ? constraints.maxWidth
                              : 390.0;
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 12 : 26,
                              4,
                              compact ? 12 : 26,
                              28,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxExtent,
                              mainAxisExtent: 330,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              return _VehicleCard(
                                vehicle: vehicle,
                                onOpen: () => _openDetails(vehicle),
                                onEdit: () => _openEditor(vehicle),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
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
    final availableState = conducteurEmploye ? 0 : 5;
    final issueStates = conducteurEmploye ? const [1, 2] : const [6, 7];
    final available = vehicles
        .where((vehicle) => (vehicle.etatactuel ?? (conducteurEmploye ? 0 : 5)) == availableState)
        .length;
    final attention = vehicles
        .where((vehicle) => issueStates.contains(vehicle.etatactuel))
        .length;
    final documents = VehicleProvider.documentsVehicules.length;

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
        label: 'Disponibles',
        value: available.toString(),
        detail: 'Prêts à être affectés',
        icon: FluentIcons.check_mark,
        color: Colors.green,
      ),
      (
        label: 'À surveiller',
        value: attention.toString(),
        detail: 'Panne ou immobilisation',
        icon: FluentIcons.warning,
        color: Colors.orange,
      ),
      (
        label: 'Documents',
        value: documents.toString(),
        detail: 'Documents enregistrés',
        icon: FluentIcons.document_set,
        color: Colors.blue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 540 ? 2 : 4;
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
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 18),
                    ),
                    const SizedBox(width: 11),
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
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metric.value,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 21,
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
                              fontSize: 10,
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

  Widget _buildFilters(AppTheme theme, List<Vehicle> vehicles) {
    final brandIds = vehicles
        .map((vehicle) => int.tryParse(vehicle.marque ?? ''))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList()
      ..sort();

    final stateIds = conducteurEmploye
        ? List<int>.generate(5, (index) => index)
        : List<int>.generate(4, (index) => index + 5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final searchWidth =
            compact ? constraints.maxWidth : constraints.maxWidth * .42;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: ParcotoTextBox(
                controller: searchController,
                placeholder: 'Rechercher par immatriculation, VIN, modèle…',
                style: theme.writingStyle,
                placeholderStyle: TextStyle(color: theme.mutedTextColor),
                cursorColor: theme.color,
                onChanged: (value) => setState(() => searchQuery = value),
                suffix: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(FluentIcons.cancel, size: 13),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      ),
              ),
            ),
            SizedBox(
              width: compact ? (constraints.maxWidth - 10) / 2 : 170,
              child: ComboBox<int?>(
                isExpanded: true,
                value: selectedState,
                placeholder: const Text('Tous les états'),
                items: [
                  const ComboBoxItem<int?>(
                    value: null,
                    child: Text('Tous les états'),
                  ),
                  ...stateIds.map(
                    (id) => ComboBoxItem<int?>(
                      value: id,
                      child: Text(VehiclesUtilities.getEtatName(id).tr()),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedState = value),
              ),
            ),
            SizedBox(
              width: compact ? (constraints.maxWidth - 10) / 2 : 190,
              child: ComboBox<int?>(
                isExpanded: true,
                value: selectedBrand,
                placeholder: const Text('Toutes les marques'),
                items: [
                  const ComboBoxItem<int?>(
                    value: null,
                    child: Text('Toutes les marques'),
                  ),
                  ...brandIds.map(
                    (id) => ComboBoxItem<int?>(
                      value: id,
                      child: Text(
                        VehiclesUtilities.getMarqueName(id.toString()),
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
            if (selectedState != null || selectedBrand != null)
              Button(
                onPressed: () => setState(() {
                  selectedState = null;
                  selectedBrand = null;
                  brandFilterRequest.value = null;
                  externalSearchRequest.value = null;
                }),
                child: const Text('Effacer les filtres'),
              ),
            Text(
              _visibleVehicles().length.toString() + ' véhicule(s)',
              style: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Vehicle> _visibleVehicles() {
    final query = searchQuery.trim().toLowerCase();
    return VehicleProvider.vehicles.values.where((vehicle) {
      if (selectedState != null &&
          (vehicle.etatactuel ?? (conducteurEmploye ? 0 : 5)) != selectedState) {
        return false;
      }
      if (selectedBrand != null &&
          int.tryParse(vehicle.marque ?? '') != selectedBrand) {
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
      ];
      return values.any(
        (value) => value?.toLowerCase().contains(query) == true,
      );
    }).toList()
      ..sort((a, b) => a.matricule.compareTo(b.matricule));
  }

  Widget _buildEmptyState(AppTheme theme) {
    final hasFilters = searchQuery.trim().isNotEmpty ||
        selectedState != null ||
        selectedBrand != null;
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
                      selectedState = null;
                      selectedBrand = null;
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
    late final Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text(
        vehicle == null ? 'Nouveau véhicule' : 'Modifier ' + vehicle.matricule,
      ),
      semanticLabel: vehicle == null
          ? 'Nouveau véhicule'
          : 'Modifier ' + vehicle.matricule,
      icon: Icon(vehicle == null ? FluentIcons.add : FluentIcons.edit),
      body: VehicleForm(vehicle: vehicle),
      onClosed: () {
        final index = VehicleTabsState.tabs.indexOf(tab);
        if (index < 0) return;
        VehicleTabsState.tabs.removeAt(index);
        if (VehicleTabsState.tabs.isEmpty) {
          VehicleTabsState.currentIndex.value = 0;
        } else if (VehicleTabsState.currentIndex.value >=
            VehicleTabsState.tabs.length) {
          VehicleTabsState.currentIndex.value =
              VehicleTabsState.tabs.length - 1;
        } else if (VehicleTabsState.currentIndex.value > index) {
          VehicleTabsState.currentIndex.value--;
        }
      },
    );

    VehicleTabsState.tabs.add(tab);
    VehicleTabsState.currentIndex.value = VehicleTabsState.tabs.length - 1;
  }

  void _openDetails(Vehicle vehicle) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return ContentDialog(
          constraints: BoxConstraints.loose(
            Size(size.width * .96, size.height * .94),
          ),
          content: SizedBox(
            width: size.width < 900 ? size.width * .88 : 1180,
            height: size.height * .78,
            child: VehicleDetailsPage(
              vehicle: vehicle,
              onEdit: () {
                Navigator.of(dialogContext).pop();
                _openEditor(vehicle);
              },
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
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

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _VehicleCard({
    required this.vehicle,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final status = vehicle.etatactuel ?? (conducteurEmploye ? 0 : 5);
    final statusColor = _statusColor(status);
    final brand = VehiclesUtilities.getMarqueName(vehicle.marque);
    final model = vehicle.type?.trim().isNotEmpty == true
        ? vehicle.type!.trim()
        : 'Modèle non renseigné';
    final year = vehicle.modelYear ?? vehicle.anneeUtil;
    final driver = [
      vehicle.prenom,
      vehicle.nom,
    ].where((value) => value?.trim().isNotEmpty == true).join(' ');
    final imageUrl = vehicle.imageUrl?.trim();

    return ParcotoSurface(
      padding: EdgeInsets.zero,
      elevated: true,
      child: GestureDetector(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _VehicleImagePlaceholder(color: theme.color),
                    )
                  else
                    _VehicleImagePlaceholder(color: theme.color),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _VehicleStatusBadge(
                      label: VehiclesUtilities.getEtatName(status).tr(),
                      color: statusColor,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Tooltip(
                      message: 'Modifier le véhicule',
                      child: IconButton(
                        icon: const Icon(FluentIcons.edit, size: 14),
                        onPressed: onEdit,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        vehicle.service ? 'Véhicule de service' : 'Flotte',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.matricule,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (brand.isNotEmpty) brand,
                        model,
                        if (year != null) year.toString(),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Container(height: 1, color: theme.borderColor),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FluentIcons.car,
                          size: 14,
                          color: theme.mutedTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vehicle.currentMileage == null
                                ? 'Kilométrage non renseigné'
                                : vehicle.currentMileage.toString() + ' km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          FluentIcons.people,
                          size: 14,
                          color: theme.mutedTextColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            driver.isEmpty ? 'Non affecté' : driver,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.mutedTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (vehicle.fleetNumber?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Parc ' + vehicle.fleetNumber!,
                        style: TextStyle(
                          color: theme.mutedTextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    if (conducteurEmploye) {
      switch (status) {
        case 0:
          return Colors.green;
        case 1:
          return Colors.orange;
        case 2:
          return Colors.red;
        case 3:
          return Colors.blue;
        case 4:
          return Colors.grey;
      }
    } else {
      switch (status) {
        case 5:
          return Colors.green;
        case 6:
          return Colors.red;
        case 7:
          return Colors.orange;
        case 8:
          return Colors.blue;
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
