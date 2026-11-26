import 'package:fluent_ui/fluent_ui.dart';

import '../../../serializables/vehicle/vehicle.dart';
import '../../../core/services/vehicle_make_service.dart';
import '../../../ui/design_system/parcoto_tokens.dart';

/// Visual-first vehicle overview. It deliberately presents only information
/// already available on the vehicle record or supplied by the parent page.
class VehicleOverviewDashboard extends StatelessWidget {
  final Vehicle vehicle;
  final String statusLabel;
  final String? driverName;
  final int? documentsCount;
  final int? documentsWithDeadline;
  final String? latestActivityLabel;
  final String? latestActivityDate;
  final String? latestActivityNote;
  final bool loadingActivity;
  final bool activityError;
  final VoidCallback onRetryActivity;
  final VoidCallback onOpenIdentification;
  final VoidCallback onOpenAssignment;
  final VoidCallback onOpenLocation;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenMaintenance;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenAcquisition;
  final bool showHero;

  const VehicleOverviewDashboard({
    super.key,
    required this.vehicle,
    required this.statusLabel,
    required this.driverName,
    required this.documentsCount,
    required this.documentsWithDeadline,
    required this.latestActivityLabel,
    required this.latestActivityDate,
    required this.latestActivityNote,
    required this.loadingActivity,
    required this.activityError,
    required this.onRetryActivity,
    required this.onOpenIdentification,
    required this.onOpenAssignment,
    required this.onOpenLocation,
    required this.onOpenDocuments,
    required this.onOpenMaintenance,
    required this.onOpenHistory,
    required this.onOpenAcquisition,
    this.showHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = FluentTheme.of(context).accentColor;
    final compact = MediaQuery.sizeOf(context).width < ParcotoTokens.mobileBreakpoint;
    final make = VehicleMakeService.nameFor(
      VehicleMakeService.canonicalId(vehicle.marque),
    );
    final model = [make, vehicle.type, vehicle.modelYear?.toString()]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ');
    final mileage = vehicle.currentMileage == null
        ? 'Non renseigné'
        : '${_number(vehicle.currentMileage!)} km';
    final nextService = vehicle.nextServiceMileage == null
        ? 'Non planifiée'
        : '${_number(vehicle.nextServiceMileage!)} km';
    final assignment = [
      vehicle.filliale,
      vehicle.direction,
      vehicle.departement,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHero) ...[
          _hero(context, accent, model, compact),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= ParcotoTokens.tabletBreakpoint;
            final summary = _summary(
              context,
              accent,
              mileage,
              nextService,
              driverName,
              assignment,
              vehicle.emplacement,
            );
            final status = _statusPanel(context, accent);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: 14),
                  status,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: summary),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: status),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= ParcotoTokens.tabletBreakpoint;
            final activity = _activityPanel(context, accent);
            final documents = _documentsPanel(context, accent);
            if (!wide) {
              return Column(
                children: [
                  activity,
                  const SizedBox(height: 14),
                  documents,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: activity),
                const SizedBox(width: 14),
                Expanded(flex: 5, child: documents),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _quickAccess(context, accent),
      ],
    );
  }

  Widget _hero(
    BuildContext context,
    Color accent,
    String model,
    bool compact,
  ) {
    final theme = FluentTheme.of(context);
    final image = vehicle.imageUrl?.trim() ?? '';
    final imageWidth = compact ? double.infinity : 210.0;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: theme.micaBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[30]),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _vehicleImage(image, accent, imageWidth, 170),
                const SizedBox(height: 14),
                _vehicleIdentity(accent, model),
              ],
            )
          : Row(
              children: [
                _vehicleImage(image, accent, imageWidth, 142),
                const SizedBox(width: 20),
                Expanded(child: _vehicleIdentity(accent, model)),
              ],
            ),
    );
  }

  Widget _vehicleImage(String image, Color accent, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: width,
        height: height,
        color: accent.withValues(alpha: .08),
        child: image.isEmpty
            ? Icon(FluentIcons.car, color: accent, size: 42)
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(FluentIcons.car, color: accent, size: 42),
              ),
      ),
    );
  }

  Widget _vehicleIdentity(Color accent, String model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                model.isEmpty ? 'Véhicule' : model,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
            ),
            _pill(statusLabel, accent),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          vehicle.trim?.trim().isNotEmpty == true
              ? vehicle.trim!
              : 'Fiche véhicule',
          style: TextStyle(color: Colors.grey[100], fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(
          vehicle.matricule,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (vehicle.fleetNumber?.isNotEmpty == true)
              _tag(FluentIcons.info, 'Parc : ${vehicle.fleetNumber}'),
            if (vehicle.energie?.isNotEmpty == true)
              _tag(FluentIcons.car, vehicle.energie!),
            if (vehicle.transmission?.isNotEmpty == true)
              _tag(FluentIcons.settings, vehicle.transmission!),
            if (vehicle.numeroSerie?.isNotEmpty == true)
              _tag(FluentIcons.document, 'VIN : ${vehicle.numeroSerie}'),
          ],
        ),
      ],
    );
  }

  Widget _summary(
    BuildContext context,
    Color accent,
    String mileage,
    String nextService,
    String? driver,
    String assignment,
    String? location,
  ) {
    return _panel(
      context,
      'Synthèse',
      FluentIcons.view_dashboard,
      accent,
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _metric(context, FluentIcons.car, 'Kilométrage', mileage, accent),
          _metric(context, FluentIcons.repair, 'Prochaine révision', nextService, accent),
          _metric(context, FluentIcons.people, 'Conducteur',
              driver?.isNotEmpty == true ? driver! : 'Non affecté', accent),
          _metric(context, FluentIcons.account_management, 'Affectation',
              assignment.isNotEmpty ? assignment : 'Non renseignée', accent),
          _metric(context, FluentIcons.car, 'Emplacement',
              location?.trim().isNotEmpty == true ? location! : 'Non renseigné', accent),
          _metric(context, FluentIcons.calendar, 'Prochaine échéance',
              documentsWithDeadline == null
                  ? 'Non vérifiée'
                  : documentsWithDeadline == 0
                      ? 'Aucune échéance enregistrée'
                      : '$documentsWithDeadline document(s)', accent),
        ],
      ),
    );
  }

  Widget _statusPanel(BuildContext context, Color accent) {
    return _panel(
      context,
      'État du véhicule',
      FluentIcons.info,
      accent,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pill(statusLabel, accent, expanded: true),
          const SizedBox(height: 12),
          _infoLine(FluentIcons.repair, 'Kilométrage actuel',
              vehicle.currentMileage == null
                  ? 'Non renseigné'
                  : '${_number(vehicle.currentMileage!)} km'),
          _infoLine(FluentIcons.document, 'Documents enregistrés',
              documentsCount == null ? 'Non vérifiés' : documentsCount.toString()),
          _infoLine(FluentIcons.info, 'Garantie',
              vehicle.warrantyEndDate?.isNotEmpty == true
                  ? vehicle.warrantyEndDate!
                  : 'Non renseignée'),
          const SizedBox(height: 8),
          Text(
            'La position GPS en temps réel n’est pas configurée.',
            style: TextStyle(color: Colors.grey[100], fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _activityPanel(BuildContext context, Color accent) {
    return _panel(
      context,
      'Activité récente',
      FluentIcons.document,
      accent,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loadingActivity)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: ProgressRing(),
            ))
          else if (activityError)
            _emptyState(
              'Impossible de charger l’historique.',
              action: Button(
                onPressed: onRetryActivity,
                child: const Text('Réessayer'),
              ),
            )
          else if (latestActivityLabel == null)
            _emptyState('Aucune activité récente enregistrée.')
          else ...[
            _timelineItem(
              accent,
              latestActivityLabel!,
              latestActivityDate ?? 'Date non renseignée',
              latestActivityNote,
            ),
            const SizedBox(height: 8),
            Text(
              'Les autres événements sont disponibles dans l’historique complet.',
              style: TextStyle(color: Colors.grey[100], fontSize: 11),
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _textAction('Voir tout', onOpenHistory),
          ),
        ],
      ),
    );
  }

  Widget _documentsPanel(BuildContext context, Color accent) {
    return _panel(
      context,
      'Documents clés',
      FluentIcons.document_set,
      accent,
      Column(
        children: [
          _documentLine('Carte grise', documentsCount == null
              ? 'Statut non vérifié'
              : documentsCount! > 0 ? 'Document(s) enregistré(s)' : 'À ajouter',
              documentsCount == null ? FluentIcons.help : FluentIcons.check_mark),
          _documentLine('Assurance', 'Échéance à vérifier', FluentIcons.warning),
          _documentLine('Contrôle technique', 'Échéance à vérifier', FluentIcons.warning),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _textAction('Voir les documents', onOpenDocuments),
          ),
          Text(
            'Les lignes ci-dessus sont des catégories de suivi, pas une validation de conformité.',
            style: TextStyle(color: Colors.grey[100], fontSize: 10, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _quickAccess(BuildContext context, Color accent) {
    final items = <(String, IconData, VoidCallback)>[
      ('Identification', FluentIcons.info, onOpenIdentification),
      ('Affectation', FluentIcons.people, onOpenAssignment),
      ('Localisation', FluentIcons.car, onOpenLocation),
      ('Maintenance', FluentIcons.repair, onOpenMaintenance),
      ('Acquisition', FluentIcons.shopping_cart, onOpenAcquisition),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((item) => Button(
                onPressed: item.$3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$2, size: 13, color: accent),
                    const SizedBox(width: 7),
                    Text(item.$1),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _panel(
    BuildContext context,
    String title,
    IconData icon,
    Color accent,
    Widget child,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[30]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color accent,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: 220,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[30]),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[100], fontSize: 10)),
                    const SizedBox(height: 3),
                    Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[100]),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 8),
          Flexible(child: Text(value, textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _documentLine(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(FluentIcons.document, size: 16, color: Colors.grey[100]),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[100])),
              ],
            ),
          ),
          Icon(icon, size: 15, color: icon == FluentIcons.warning ? Colors.orange : Colors.green),
        ],
      ),
    );
  }

  Widget _timelineItem(Color accent, String title, String date, String? note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[100])),
              if (note?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(note!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[100])),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(text, style: TextStyle(color: Colors.grey[100], fontSize: 11)),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  Widget _pill(String label, Color accent, {bool expanded = false}) {
    return Container(
      width: expanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(FluentIcons.check_mark, size: 12, color: accent),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[20],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[40]),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _textAction(String label, VoidCallback action) => Button(
        onPressed: action,
        child: Text(label, style: const TextStyle(fontSize: 11)),
      );

  String _number(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ' ',
      );
}
