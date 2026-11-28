import 'package:fluent_ui/fluent_ui.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/parking/parking_models.dart';

class ParkingAccessSelection {
  final String vehicleId;
  final String? parkingSpaceId;
  final String? assignmentId;
  final String? notes;

  const ParkingAccessSelection({
    required this.vehicleId,
    this.parkingSpaceId,
    this.assignmentId,
    this.notes,
  });
}

/// Collects a selection only. The dashboard performs the atomic SQLite write.
class ParkingAccessDialog extends StatefulWidget {
  final bool isEntry;
  final List<Vehicle> vehicles;
  final List<ParkingSpace> availableSpaces;
  final List<VehicleParkingAssignment> activeAssignments;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  const ParkingAccessDialog({
    super.key,
    required this.isEntry,
    required this.vehicles,
    required this.availableSpaces,
    required this.activeAssignments,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  State<ParkingAccessDialog> createState() => _ParkingAccessDialogState();
}

class _ParkingAccessDialogState extends State<ParkingAccessDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedVehicleId;
  String? _selectedSpaceId;
  String? _selectedAssignmentId;

  @override
  void initState() {
    super.initState();
    if (widget.availableSpaces.isNotEmpty) {
      _selectedSpaceId = widget.availableSpaces.first.id;
    }
    if (widget.activeAssignments.isNotEmpty) {
      _selectedAssignmentId = widget.activeAssignments.first.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _vehicleSubtitle(Vehicle vehicle) {
    final details = <String>[
      if ((vehicle.brand ?? '').trim().isNotEmpty) vehicle.brand!.trim(),
      if ((vehicle.type ?? '').trim().isNotEmpty) vehicle.type!.trim(),
      if (vehicle.modelYear != null) vehicle.modelYear.toString(),
      if ((vehicle.fleetNumber ?? '').trim().isNotEmpty)
        'Parc ${vehicle.fleetNumber!.trim()}',
    ];
    return details.isEmpty ? 'Véhicule de la flotte' : details.join(' • ');
  }

  List<Vehicle> get _filteredVehicles {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.vehicles;
    final normalizedQuery = ParkingAccessEvent.normalizeRegistration(query);
    return widget.vehicles.where((vehicle) {
      final registration = vehicle.registration.toLowerCase();
      final normalizedRegistration =
          ParkingAccessEvent.normalizeRegistration(vehicle.registration);
      final details = [
        vehicle.brand,
        vehicle.type,
        vehicle.fleetNumber,
        vehicle.ownerLastName,
        vehicle.ownerFirstName,
      ].whereType<String>().join(' ').toLowerCase();
      return registration.contains(query) ||
          normalizedRegistration.contains(normalizedQuery) ||
          details.contains(query);
    }).toList(growable: false);
  }

  Map<String, Vehicle> get _vehiclesById => {
        for (final vehicle in widget.vehicles) vehicle.id: vehicle,
      };

  List<VehicleParkingAssignment> get _filteredAssignments {
    final query = _searchController.text.trim().toLowerCase();
    final normalizedQuery = ParkingAccessEvent.normalizeRegistration(query);
    final vehiclesById = _vehiclesById;
    return widget.activeAssignments.where((assignment) {
      final vehicle = vehiclesById[assignment.vehicleId];
      if (vehicle == null) return false;
      if (query.isEmpty) return true;
      final registration = vehicle.registration.toLowerCase();
      final normalizedRegistration =
          ParkingAccessEvent.normalizeRegistration(vehicle.registration);
      final details = [
        vehicle.brand,
        vehicle.type,
        vehicle.fleetNumber,
        vehicle.ownerLastName,
        vehicle.ownerFirstName,
      ].whereType<String>().join(' ').toLowerCase();
      return registration.contains(query) ||
          normalizedRegistration.contains(normalizedQuery) ||
          details.contains(query);
    }).toList(growable: false);
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? widget.primaryColor.withValues(alpha: 0.10)
              : widget.backgroundColor,
          border: Border.all(
            color: selected ? widget.primaryColor : widget.borderColor,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? FluentIcons.radio_bullet : FluentIcons.car,
              size: 16,
              color: selected ? widget.primaryColor : widget.mutedColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: widget.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: widget.mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                FluentIcons.check_mark,
                size: 15,
                color: widget.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleOptions() {
    final options = _filteredVehicles;
    if (options.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'Aucun véhicule disponible dans la flotte locale.'
              : 'Aucun véhicule ne correspond à cette recherche.',
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.mutedColor),
        ),
      );
    }
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final vehicle = options[index];
        return _optionTile(
          title: vehicle.registration,
          subtitle: _vehicleSubtitle(vehicle),
          selected: vehicle.id == _selectedVehicleId,
          onPressed: () => setState(() => _selectedVehicleId = vehicle.id),
        );
      },
    );
  }

  Widget _assignmentOptions() {
    final options = _filteredAssignments;
    final vehiclesById = _vehiclesById;
    if (options.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.trim().isEmpty
              ? 'Aucun véhicule actuellement présent dans ce parking.'
              : 'Aucune entrée active ne correspond à cette recherche.',
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.mutedColor),
        ),
      );
    }
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final assignment = options[index];
        final vehicle = vehiclesById[assignment.vehicleId]!;
        var spaceLabel = assignment.parkingSpaceId;
        for (final space in widget.availableSpaces) {
          if (space.id == assignment.parkingSpaceId) {
            spaceLabel = space.code;
            break;
          }
        }
        final startedAt = assignment.startAt.toLocal().toString();
        return _optionTile(
          title: vehicle.registration,
          subtitle: '$spaceLabel • Depuis ${startedAt.substring(0, 16)}',
          selected: assignment.id == _selectedAssignmentId,
          onPressed: () =>
              setState(() => _selectedAssignmentId = assignment.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = (screen.width - 32).clamp(240.0, 560.0).toDouble();
    final dialogHeight = (screen.height - 32).clamp(240.0, 680.0).toDouble();
    final contentWidth = (dialogWidth - 40).clamp(200.0, 520.0).toDouble();
    final listHeight = widget.isEntry
        ? (dialogHeight * 0.28).clamp(96.0, 180.0).toDouble()
        : (dialogHeight * 0.36).clamp(110.0, 220.0).toDouble();
    final canSubmit = widget.isEntry
        ? _selectedVehicleId != null &&
            _selectedSpaceId != null &&
            widget.availableSpaces.any((space) => space.id == _selectedSpaceId)
        : _selectedAssignmentId != null &&
            widget.activeAssignments
                .any((assignment) => assignment.id == _selectedAssignmentId);

    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: dialogWidth,
        maxHeight: dialogHeight,
      ),
      title: Text(
        widget.isEntry ? 'Enregistrer une entrée' : 'Enregistrer une sortie',
      ),
      content: SizedBox(
        width: contentWidth,
        height: dialogHeight - 130,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              widget.isEntry
                  ? 'Sélectionne le véhicule entrant et sa place de stationnement.'
                  : 'Sélectionne le véhicule qui quitte le parking.',
              style: TextStyle(color: widget.mutedColor),
            ),
            const SizedBox(height: 12),
            TextBox(
              controller: _searchController,
              placeholder: 'Rechercher par immatriculation ou véhicule',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(FluentIcons.search, size: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEntry ? 'VÉHICULE' : 'VÉHICULES PRÉSENTS',
              style: FluentTheme.of(context).typography.caption?.copyWith(
                    color: widget.mutedColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: listHeight,
              child: widget.isEntry
                  ? _vehicleOptions()
                  : _assignmentOptions(),
            ),
            if (widget.isEntry) ...[
              const SizedBox(height: 12),
              Text(
                'PLACE DE STATIONNEMENT',
                style: FluentTheme.of(context).typography.caption?.copyWith(
                      color: widget.mutedColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 6),
              ComboBox<String>(
                value: _selectedSpaceId,
                isExpanded: true,
                placeholder: const Text('Choisir une place libre'),
                items: [
                  for (final space in widget.availableSpaces)
                    ComboBoxItem<String>(
                      value: space.id,
                      child: Text(space.code),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedSpaceId = value),
              ),
            ],
            const SizedBox(height: 12),
            TextBox(
              controller: _notesController,
              maxLines: 2,
              placeholder: 'Note (facultative)',
            ),
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
          onPressed: canSubmit
              ? () {
                  final notes = _notesController.text.trim();
                  String vehicleId;
                  if (widget.isEntry) {
                    vehicleId = _selectedVehicleId!;
                  } else {
                    vehicleId = widget.activeAssignments
                        .firstWhere(
                          (item) => item.id == _selectedAssignmentId,
                        )
                        .vehicleId;
                  }
                  Navigator.of(context).pop(
                    ParkingAccessSelection(
                      vehicleId: vehicleId,
                      parkingSpaceId:
                          widget.isEntry ? _selectedSpaceId : null,
                      assignmentId:
                          widget.isEntry ? null : _selectedAssignmentId,
                      notes: notes.isEmpty ? null : notes,
                    ),
                  );
                }
              : null,
          child: Text(
            widget.isEntry ? 'Confirmer l’entrée' : 'Confirmer la sortie',
          ),
        ),
      ],
    );
  }
}
