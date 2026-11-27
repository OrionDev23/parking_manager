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
  final String? latestActivityLabel;
  final String? latestActivityDate;
  final String? latestActivityNote;
  final List<({String title, String date, String? note})> recentActivities;
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
    required this.latestActivityLabel,
    required this.latestActivityDate,
    required this.latestActivityNote,
    this.recentActivities = const [],
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
    final statusColor = _vehicleStatusColor(vehicle.etatactuel, accent);
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
            final wide = constraints.maxWidth >= 620;
            final summary = _summary(
              context,
              accent,
              mileage,
              nextService,
              driverName,
              assignment,
              vehicle.emplacement,
            );
            final status = _statusPanel(context, accent, statusColor);
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
                Expanded(child: summary),
                const SizedBox(width: 12),
                SizedBox(
                  width: (constraints.maxWidth * .34).clamp(230.0, 280.0).toDouble(),
                  child: status,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 620;
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
    final metrics = <({IconData icon, String label, String value})>[
      (icon: FluentIcons.car, label: 'Kilométrage', value: mileage),
      (icon: FluentIcons.repair, label: 'Prochaine révision', value: nextService),
      (
        icon: FluentIcons.people,
        label: 'Conducteur',
        value: driver?.isNotEmpty == true ? driver! : 'Non affecté',
      ),
      (
        icon: FluentIcons.account_management,
        label: 'Affectation',
        value: assignment.isNotEmpty ? assignment : 'Non renseignée',
      ),
      (
        icon: FluentIcons.car,
        label: 'Emplacement',
        value: location?.trim().isNotEmpty == true ? location! : 'Non renseigné',
      ),
      (
        icon: FluentIcons.calendar,
        label: 'Prochaine échéance',
        value: documentsCount == null
            ? 'Non vérifiée'
            : nearestDocumentLabel ?? 'Aucune échéance enregistrée',
      ),
    ];

    return _panel(
      context,
      'Synthèse',
      FluentIcons.view_dashboard,
      accent,
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final columns = compact ? 1 : 2;
          const spacing = 8.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: itemWidth,
                  child: _metric(
                    metric.icon,
                    metric.label,
                    metric.value,
                    accent,
                    compact: compact,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusPanel(
    BuildContext context,
    Color accent,
    Color statusColor,
  ) {
    final documentsToWatch = registeredDocuments
        .where((document) => document.warning)
        .length;
    final latestEvent = latestActivityLabel == null
        ? 'Aucune activité enregistrée'
        : [
            latestActivityLabel!,
            if (latestActivityDate?.isNotEmpty == true) latestActivityDate!,
          ].join(' • ');

    return _panel(
      context,
      'État du véhicule',
      FluentIcons.info,
      accent,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pill(statusLabel, statusColor, expanded: true),
          const SizedBox(height: 7),
          _infoLine(
            FluentIcons.document,
            'Dernière activité',
            latestEvent,
          ),
          _infoLine(
            FluentIcons.document,
            'Documents à surveiller',
            documentsCount == null
                ? 'Non vérifié'
                : documentsToWatch.toString(),
          ),
          _infoLine(
            FluentIcons.info,
            'Garantie',
            vehicle.warrantyEndDate?.isNotEmpty == true
                ? vehicle.warrantyEndDate!
                : 'Non renseignée',
          ),
        ],
      ),
    );
  }

  Widget _activityPanel(BuildContext context, Color accent) {
    final visibleActivities = recentActivities.take(3).toList(growable: false);
    return _panel(
      context,
      'Activité récente',
      FluentIcons.document,
      accent,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loadingActivity && visibleActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: ProgressRing(),
              ),
            )
          else if (activityError && visibleActivities.isEmpty)
            _emptyState(
              'Impossible de charger l’historique.',
              action: Button(
                onPressed: onRetryActivity,
                child: const Text('Réessayer'),
              ),
            )
          else if (visibleActivities.isNotEmpty)
            ...visibleActivities.asMap().entries.map((entry) {
              final activity = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == visibleActivities.length - 1 ? 0 : 8,
                ),
                child: _timelineItem(
                  accent,
                  activity.title,
                  activity.date,
                  activity.note,
                ),
              );
            })
          else if (latestActivityLabel == null)
            _emptyState('Aucune activité récente enregistrée.')
          else
            _timelineItem(
              accent,
              latestActivityLabel!,
              latestActivityDate ?? 'Date non renseignée',
              latestActivityNote,
            ),
          const SizedBox(height: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (documentsCount == null)
            _emptyState('Les documents du véhicule n’ont pas pu être vérifiés.')
          else if (registeredDocuments.isEmpty)
            _emptyState('Aucun document enregistré pour ce véhicule.')
          else ...[
            for (final document in registeredDocuments.take(3))
              _documentLine(
                document.title,
                document.expiryLabel,
                document.statusLabel,
                document.warning
                    ? (document.expired ? Colors.red : Colors.orange)
                    : Colors.green,
                document.expired
                    ? FluentIcons.blocked
                    : document.warning
                        ? FluentIcons.warning
                        : FluentIcons.check_mark,
              ),
            if (registeredDocuments.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '+ ${registeredDocuments.length - 3} autres documents',
                  style: TextStyle(color: Colors.grey[100], fontSize: 10),
                ),
              ),
          ],
          const SizedBox(height: 5),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _textAction('Voir tout', onOpenDocuments),
          ),
        ],
      ),
    );
  }

  Color _vehicleStatusColor(int? status, Color fallback) {
    switch (status) {
      case 0:
      case 5:
        return Colors.green;
      case 1:
      case 6:
        return Colors.red;
      case 2:
      case 7:
        return Colors.orange;
      case 3:
      case 8:
        return Colors.blue;
      case 4:
        return Colors.grey;
      default:
        return fallback;
    }
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
      padding: const EdgeInsets.all(13),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _metric(
    IconData icon,
    String label,
    String value,
    Color accent, {
    required bool compact,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[30]),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 17),
          const SizedBox(width: 8),
          if (compact) ...[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[100], fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[100], fontSize: 9.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[100]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentLine(
    String title,
    String subtitle,
    String status,
    Color statusColor,
    IconData statusIcon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(FluentIcons.document, size: 16, color: Colors.grey[100]),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey[100]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: status,
            child: Icon(statusIcon, size: 15, color: statusColor),
          ),
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
                  child: Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.grey[100])),
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
