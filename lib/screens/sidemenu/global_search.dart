import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

import '../../main.dart' show driverServices, vehicleServices;
import '../../domain/entities/driver.dart';
import '../../domain/entities/vehicle.dart';
import 'pane_items.dart';

class GlobalSearchLauncher extends StatelessWidget {
  const GlobalSearchLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Button(
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (_) => const _GlobalSearchDialog(),
        ),
        child: Row(
          children: [
            const Icon(FluentIcons.search, size: 15),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Rechercher dans Parcoto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalSearchDialog extends StatefulWidget {
  const _GlobalSearchDialog();

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  String _query = '';
  String? _error;
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];

  static const _destinations = <({String key, String title, String group})>[
    (key: 'dashboard', title: 'Tableau de bord', group: 'Général'),
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
    });
    if (query.length < 2) {
      setState(() => _searching = false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    try {
      final results = await Future.wait([
        vehicleServices.repository.getVehicles(search: query, limit: 6),
        driverServices.repository.getDrivers(search: query, limit: 6),
      ]);
      if (!mounted || query != _query) return;
      setState(() {
        _vehicles = results[0] as List<Vehicle>;
        _drivers = results[1] as List<Driver>;
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

  void _openVehicle(Vehicle vehicle) => _openDestination('vehicle-manager');
  void _openDriver(Driver driver) => _openDestination('driver-manager');

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final destinations = _query.length < 2 ? <({String key, String title, String group})>[] : _destinations
        .where((item) => item.title.toLowerCase().contains(q) ||
            item.group.toLowerCase().contains(q))
        .take(6)
        .toList(growable: false);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
      title: const Text('Recherche globale'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextBox(
              controller: _controller,
              autofocus: true,
              placeholder: 'Interface, immatriculation, véhicule, conducteur…',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(FluentIcons.search, size: 16),
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 10),
            if (_query.length < 2)
              const Text(
                'Saisissez au moins 2 caractères. La recherche couvre les interfaces, véhicules et conducteurs.',
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
                destinations.isEmpty && _vehicles.isEmpty && _drivers.isEmpty)
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
