import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';

import '../../main.dart' show authService, driverServices, vehicleServices;
import '../../providers/parts_provider.dart';
import '../../serializables/pieces/part.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/vehicle.dart';
import 'pane_items.dart';
import '../vehicle/manager/vehicles_table.dart';
import '../chauffeur/manager/chauffeur_table.dart';
import '../vehicle/manager/vehicle_management.dart';
import '../workshop/parts/parts_management/parts_table.dart';

/// Chooses the search scope from the active navigation destination.
/// Global search is intentionally available only on the main dashboard.
class ContextualSearchLauncher extends StatelessWidget {
  final String? paneKey;
  final bool compact;

  const ContextualSearchLauncher({
    super.key,
    required this.paneKey,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (paneKey) {
      case 'dashboard':
        return GlobalSearchLauncher(compact: compact);
      case 'vehicle-manager':
        return _ModuleSearchLauncher(
          scope: _ModuleSearchScope.vehicles,
          compact: compact,
        );
      case 'driver-manager':
        return _ModuleSearchLauncher(
          scope: _ModuleSearchScope.drivers,
          compact: compact,
        );
      case 'workshop-parts':
        return _ModuleSearchLauncher(
          scope: _ModuleSearchScope.parts,
          compact: compact,
        );
      default:
        // Other screens keep their existing in-page filters until a dedicated
        // adapter is connected. Never silently fall back to global search.
        return const SizedBox.shrink();
    }
  }
}

enum _ModuleSearchScope { vehicles, drivers, parts }

class _ModuleSearchLauncher extends StatefulWidget {
  final _ModuleSearchScope scope;
  final bool compact;

  const _ModuleSearchLauncher({
    required this.scope,
    this.compact = false,
  });

  @override
  State<_ModuleSearchLauncher> createState() => _ModuleSearchLauncherState();
}

class _ModuleSearchLauncherState extends State<_ModuleSearchLauncher> {
  final TextEditingController _controller = TextEditingController();
  Timer? _crossSearchTimer;
  String? _lastCrossSuggestionQuery;
  String _lastDispatchedQuery = '';

  String get _placeholder => switch (widget.scope) {
        _ModuleSearchScope.vehicles => 'Rechercher un véhicule...',
        _ModuleSearchScope.drivers => 'Rechercher un conducteur...',
        _ModuleSearchScope.parts => 'Rechercher une pièce...',
      };



  @override
  void didUpdateWidget(covariant _ModuleSearchLauncher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) {
      _crossSearchTimer?.cancel();
      _controller.clear();
      _lastCrossSuggestionQuery = null;
      _lastDispatchedQuery = '';
    }
  }

  @override
  void dispose() {
    _crossSearchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dispatchLocalSearch(String value) {
    final query = value.trim();
    if (query != _lastDispatchedQuery) {
      _lastDispatchedQuery = query;
      _lastCrossSuggestionQuery = null;
    }
    switch (widget.scope) {
      case _ModuleSearchScope.vehicles:
        VehicleManagementState.externalSearchRequest.value = query;
        _scheduleVehiclePartSuggestion(query);
        break;
      case _ModuleSearchScope.drivers:
        ChauffeurTableState.filterDocument.value = query;
        ChauffeurTableState.filterNow = true;
        break;
      case _ModuleSearchScope.parts:
        PartsTableState.filterDocument.value = query;
        PartsTableState.filterNow = true;
        break;
    }
  }

  void _scheduleVehiclePartSuggestion(String query) {
    _crossSearchTimer?.cancel();
    if (query.length < 2) return;
    _crossSearchTimer = Timer(
      const Duration(milliseconds: 550),
      () => _suggestMatchingParts(query),
    );
  }

  Future<void> _suggestMatchingParts(String query) async {
    if (!mounted ||
        widget.scope != _ModuleSearchScope.vehicles ||
        _controller.text.trim() != query ||
        _lastCrossSuggestionQuery == query) {
      return;
    }

    // Do not report a cross-module match while the vehicle cache is still
    // loading; wait briefly for the active screen's local result count.
    for (var attempt = 0;
        attempt < 40 && VehicleProvider.downloadingVehicles;
        attempt++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _controller.text.trim() != query) return;
    }
    if (VehicleProvider.downloadingVehicles ||
        VehicleManagementState.visibleResultCount.value != 0) {
      return;
    }

    final matches = await _searchParts(query, limit: 3);
    if (!mounted ||
        _controller.text.trim() != query ||
        VehicleManagementState.visibleResultCount.value != 0 ||
        VehicleProvider.downloadingVehicles ||
        matches.isEmpty) {
      return;
    }

    _lastCrossSuggestionQuery = query;
    displayInfoBar(
      context,
      duration: const Duration(seconds: 9),
      builder: (context, close) => InfoBar(
        title: const Text('Aucun véhicule correspondant'),
        content: Text(
          matches.length == 1
              ? 'Une pièce correspond à « $query ». Elle se trouve dans le module Pièces.'
              : '${matches.length} pièces correspondent à « $query ». Elles se trouvent dans le module Pièces.',
        ),
        severity: InfoBarSeverity.info,
        action: Button(
          child: const Text('Ouvrir Pièces'),
          onPressed: () {
            close();
            PartsTableState.filterDocument.value = query;
            PartsTableState.filterNow = true;
            PaneItemsAndFooters.selectPane('workshop-parts');
          },
        ),
      ),
    );
  }

  Future<void> _openCompactSearch() async {
    final dialogController = TextEditingController(text: _controller.text);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: Text(_placeholder),
        content: TextBox(
          controller: dialogController,
          autofocus: true,
          placeholder: _placeholder,
          onChanged: (value) {
            _controller.text = value;
            _dispatchLocalSearch(value);
          },
          onSubmitted: (value) {
            _controller.text = value;
            _dispatchLocalSearch(value);
            Navigator.of(dialogContext).pop();
          },
          suffix: IconButton(
            icon: const Icon(FluentIcons.cancel, size: 13),
            onPressed: () {
              dialogController.clear();
              _controller.clear();
              _dispatchLocalSearch('');
            },
          ),
        ),
        actions: [
          Button(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
    dialogController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Tooltip(
        message: _placeholder,
        child: IconButton(
          icon: const Icon(FluentIcons.search, size: 19),
          onPressed: _openCompactSearch,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 38,
        child: TextBox(
          controller: _controller,
          placeholder: _placeholder,
          onChanged: _dispatchLocalSearch,
          onSubmitted: _dispatchLocalSearch,
          prefix: const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(FluentIcons.search, size: 15),
          ),
          suffix: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(FluentIcons.cancel, size: 13),
                    onPressed: () {
                      _controller.clear();
                      _dispatchLocalSearch('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class GlobalSearchLauncher extends StatefulWidget {
  final bool compact;

  const GlobalSearchLauncher({super.key, this.compact = false});

  @override
  State<GlobalSearchLauncher> createState() => _GlobalSearchLauncherState();
}

class _GlobalSearchLauncherState extends State<GlobalSearchLauncher> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _GlobalSearchDialog(initialQuery: query),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Tooltip(
        message: 'Recherche globale',
        child: IconButton(
          icon: const Icon(FluentIcons.search, size: 19),
          onPressed: _submitSearch,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 38,
        child: TextBox(
          controller: _controller,
          placeholder: 'Rechercher un module, un véhicule, un conducteur…',
          onSubmitted: (_) => _submitSearch(),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(FluentIcons.search, size: 15),
          ),
          suffix: IconButton(
            icon: const Icon(FluentIcons.chevron_right, size: 12),
            onPressed: _submitSearch,
          ),
        ),
      ),
    );
  }
}

Future<List<VehiclePart>> _searchParts(
  String query, {
  int limit = 6,
}) async {
  final normalized = query.trim().toLowerCase();
  if (normalized.length < 2) return const [];

  final provider = PartsProvider();
  try {
    if (PartsProvider.downloadingParts) {
      for (var attempt = 0;
          attempt < 100 && PartsProvider.downloadingParts;
          attempt++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else if (PartsProvider.errorParts) {
      await provider.downloadAllParts();
    }
    if (PartsProvider.errorParts || PartsProvider.downloadingParts) {
      return const [];
    }

    return PartsProvider.parts.values.where((part) {
      final searchable = [
        part.search,
        part.name,
        part.sku,
        part.barcode,
      ].whereType<String>().join(' ').toLowerCase();
      return searchable.contains(normalized);
    }).take(limit).toList(growable: false);
  } catch (_) {
    return const [];
  } finally {
    provider.dispose();
  }
}

class _GlobalSearchDialog extends StatefulWidget {
  final String initialQuery;

  const _GlobalSearchDialog({this.initialQuery = ''});

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _query = widget.initialQuery.trim();
    if (_query.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runSearch(_query);
      });
    }
  }
  Timer? _debounce;
  bool _searching = false;
  String _query = '';
  String? _error;
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];
  List<VehiclePart> _parts = [];

  static const _destinations = <({String key, String title, String group})>[
    (key: 'dashboard', title: 'Tableau de bord', group: 'Général'),
    (key: 'platform-companies', title: 'Entreprises clientes', group: 'Plateforme'),
    (key: 'vehicle-manager', title: 'Gestion des véhicules', group: 'Véhicules'),
    (key: 'vehicle-brands', title: 'Marques de véhicules', group: 'Véhicules'),
    (key: 'vehicle-states', title: 'États des véhicules', group: 'Véhicules'),
    (key: 'vehicle-documents', title: 'Documents véhicules', group: 'Véhicules'),
    (key: 'driver-manager', title: 'Gestion des conducteurs', group: 'Conducteurs'),
    (key: 'driver-availability', title: 'Disponibilités', group: 'Conducteurs'),
    (key: 'driver-documents', title: 'Documents conducteurs', group: 'Conducteurs'),
    (key: 'workshop-stock', title: 'Stock atelier', group: 'Atelier'),
    (key: 'workshop-suppliers', title: 'Fournisseurs', group: 'Atelier'),
    (key: 'workshop-parts', title: 'Pièces', group: 'Atelier'),
    (key: 'repair-reception', title: 'Fiches de réception', group: 'Réparations'),
    (key: 'repair-orders', title: 'Ordres de réparation', group: 'Réparations'),
    (key: 'repair-clients', title: 'Clients', group: 'Réparations'),
    (key: 'planner', title: 'Planning', group: 'Organisation'),
    (key: 'events', title: 'Journal d’activité', group: 'Organisation'),
    (key: 'usermngmt', title: 'Gestion des utilisateurs', group: 'Administration'),
    (key: 'access', title: 'Équipes et accès', group: 'Administration'),
    (key: 'company', title: 'Mon entreprise', group: 'Entreprise'),
    (key: 'backup', title: 'Sauvegarde et restauration', group: 'Système'),
    (key: 'settings', title: 'Paramètres', group: 'Système'),
    (key: 'tutorials', title: 'Didacticiels', group: 'Aide'),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _error = null;
      _vehicles = [];
      _drivers = [];
      _parts = [];
    });
    if (query.length < 2) {
      setState(() => _searching = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted || query != _query) return;
    setState(() => _searching = true);
    try {
      final session = authService.session;
      if (session?.isPlatformSuperAdmin == true &&
          session?.isPlatformCompanyContext != true) {
        if (!mounted || query != _query) return;
        setState(() => _searching = false);
        return;
      }

      final results = await Future.wait([
        vehicleServices.repository.getVehicles(search: query, limit: 6),
        driverServices.repository.getDrivers(search: query, limit: 6),
      ]);
      final parts = await _searchParts(query, limit: 6);

      if (!mounted || query != _query) return;
      setState(() {
        _vehicles = results[0] as List<Vehicle>;
        _drivers = results[1] as List<Driver>;
        _parts = parts;
        _searching = false;
      });
    } catch (error) {
      if (!mounted || query != _query) return;
      setState(() {
        _error = error.toString();
        _searching = false;
      });
    }
  }

  void _openDestination(String key) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PaneItemsAndFooters.selectPane(key);
    });
  }

  void _openVehicle(Vehicle vehicle) {
    VehicleTableState.filterVehicule.value = vehicle.registration;
    VehicleTableState.filterNow = true;
    _openDestination('vehicle-manager');
  }

  void _openDriver(Driver driver) {
    ChauffeurTableState.filterDocument.value = driver.registration;
    ChauffeurTableState.filterNow = true;
    _openDestination('driver-manager');
  }

  void _openPart(String query) {
    PartsTableState.filterDocument.value = query;
    PartsTableState.filterNow = true;
    _openDestination('workshop-parts');
  }


  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final destinations = _query.length < 2 ? <({String key, String title, String group})>[] : _destinations
        .where((item) => PaneItemsAndFooters.indexForPaneKey(item.key) != null &&
            (item.title.toLowerCase().contains(q) ||
             item.group.toLowerCase().contains(q)))
        .take(6)
        .toList(growable: false);

    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = (viewport.width - 40).clamp(280.0, 620.0).toDouble();
    final dialogHeight = (viewport.height - 100).clamp(300.0, 680.0).toDouble();

    return ContentDialog(
      constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: dialogHeight),
      title: const Text('Recherche globale'),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextBox(
              controller: _controller,
              autofocus: true,
              placeholder: 'Interface, véhicule, conducteur, référence ou pièce…',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(FluentIcons.search, size: 16),
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 10),
            if (_query.length < 2)
              const Text(
                'Saisissez au moins 2 caractères. La recherche couvre les interfaces, véhicules, conducteurs et pièces.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (destinations.isNotEmpty) ...[
              const _SectionLabel('INTERFACES'),
              ...destinations.map((item) => _ResultTile(
                    icon: FluentIcons.navigate_forward,
                    title: item.title,
                    subtitle: item.group,
                    onPressed: () => _openDestination(item.key),
                  )),
            ],
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: ProgressRing()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Recherche de données indisponible : $_error',
                  style:  TextStyle(color: Colors.red),
                ),
              ),
            if (_vehicles.isNotEmpty) ...[
              const _SectionLabel('VÉHICULES'),
              ..._vehicles.map((item) => _ResultTile(
                    icon: FluentIcons.car,
                    title: item.registration,
                    subtitle: [
                      item.brand,
                      item.type,
                      item.serialNumber,
                    ].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
                    onPressed: () => _openVehicle(item),
                  )),
            ],
            if (_parts.isNotEmpty) ...[
              const _SectionLabel('PIÈCES DE RECHANGE'),
              ..._parts.map((item) => _ResultTile(
                    icon: FluentIcons.repair,
                    title: item.name,
                    subtitle: [
                      if (item.sku?.isNotEmpty == true) 'SKU ${item.sku}',
                      if (item.barcode?.isNotEmpty == true) item.barcode!,
                      if (item.brandName?.isNotEmpty == true) item.brandName!,
                    ].join(' • '),
                    onPressed: () => _openPart(_query),
                  )),
            ],
            if (_drivers.isNotEmpty) ...[
              const _SectionLabel('CONDUCTEURS'),
              ..._drivers.map((item) => _ResultTile(
                    icon: FluentIcons.contact,
                    title: '${item.firstName} ${item.lastName}'.trim(),
                    subtitle: [
                      if (item.registration.isNotEmpty) item.registration,
                      item.phone,
                      item.email,
                    ].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
                    onPressed: () => _openDriver(item),
                  )),
            ],
            if (_query.length >= 2 && !_searching && _error == null &&
                destinations.isEmpty &&
                _vehicles.isEmpty &&
                _drivers.isEmpty &&
                _parts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun résultat.'),
              ),
          ],
        ),
      ),
      actions: [
        Button(
          child: const Text('Fermer'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 5),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Colors.grey,
          ),
        ),
      );
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _ResultTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Button(
          onPressed: onPressed,
          child: Row(
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const Icon(FluentIcons.chevron_right, size: 12),
            ],
          ),
        ),
      );
}
