import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../serializables/vehicle/vehicle.dart' as legacy;
import '../../main.dart' show authService;
import '../../providers/client_database.dart';
import '../../providers/driver_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/planning_provider.dart';
import '../../providers/repair_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../serializables/activity.dart';
import '../../serializables/reparation/reparation.dart';
import '../../theme.dart';
import '../sidemenu/pane_items.dart';
import 'models/dashboard_models.dart';
import 'widgets/dashboard_widgets.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with AutomaticKeepAliveClientMixin {
  late final VehicleProvider _vehicles;
  late final DriverProvider _drivers;
  late final LogProvider _logs;
  late final PlanningProvider _plannings;
  late final RepairProvider _repairs;

  DashboardSnapshot _snapshot = const DashboardSnapshot();
  bool _refreshing = false;
  bool _hasLoaded = false;
  bool _reloadScheduled = false;
  String? _loadMessage;
  String? _loadedCompanyId;

  @override
  void initState() {
    super.initState();

    // Keep provider instances stable. Their caches are tenant-aware and are
    // invalidated by the session runtime when the active company changes.
    _vehicles = VehicleProvider();
    _drivers = DriverProvider();
    _logs = LogProvider();
    _plannings = PlanningProvider();
    _repairs = RepairProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshDashboard());
    });
  }

  @override
  void dispose() {
    _vehicles.dispose();
    _drivers.dispose();
    _logs.dispose();
    _plannings.dispose();
    _repairs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<AppTheme>();
    final companyId = DatabaseGetter.activeCompanyId;

    // Dashboard is kept alive by the navigation system. A tenant switch can
    // therefore return to the same State object; reload before showing metrics
    // from the previous company's cache.
    if (_hasLoaded &&
        companyId != _loadedCompanyId &&
        !_reloadScheduled) {
      // Clear the previous tenant's dashboard immediately; do not leave its
      // values visible while the new tenant's data is loading.
      _snapshot = const DashboardSnapshot();
      _hasLoaded = false;
      _loadMessage = null;
      _reloadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadScheduled = false;
        if (mounted) unawaited(_refreshDashboard());
      });
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final wide = screenWidth >= 1500;
    final compact = screenWidth < 680;
    final sessionName = authService.session?.displayName?.trim();
    final firstName = sessionName == null || sessionName.isEmpty
        ? 'votre espace'
        : sessionName.split(RegExp(r'\s+')).first;
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'fr')
        .format(DateTime.now());

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : (wide ? 26 : 20),
          vertical: compact ? 16 : 22,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour $firstName',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: compact ? 23 : 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Voici la situation de votre parc aujourd’hui.',
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.event,
                        size: 15,
                        color: theme.mutedTextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Actualiser les données',
                child: IconButton(
                  icon: _refreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: ProgressRing(),
                        )
                      : const Icon(FluentIcons.refresh),
                  onPressed: _refreshing ? null : _refreshDashboard,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricGrid(compact: compact),
          const SizedBox(height: 18),
          _buildAnalyticsLayout(wide: wide),
          const SizedBox(height: 18),
          _buildOperationsLayout(wide: wide),
          const SizedBox(height: 18),
          _buildQuickActions(compact: compact),
          if (_loadMessage != null) ...[
            const SizedBox(height: 12),
            InfoBar(
              title: const Text('Certaines données sont indisponibles'),
              content: Text(_loadMessage!),
              severity: InfoBarSeverity.warning,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMetricGrid({required bool compact}) {
    final metrics = <({String label, String value, String detail, IconData icon, Color tone})>[
      (
        label: 'Véhicules',
        value: _metricValue(
          _snapshot.vehicleCount,
          VehicleProvider.downloadedVehicles,
        ),
        detail: VehicleProvider.downloadedVehicles
            ? 'Dans le parc de l’entreprise'
            : 'Données indisponibles',
        icon: FluentIcons.car,
        tone: const Color(0xFF279BFA),
      ),
      (
        label: 'Conducteurs',
        value: _metricValue(
          _snapshot.driverCount,
          DriverProvider.downloadedConducteurs,
        ),
        detail: DriverProvider.downloadedConducteurs
            ? 'Conducteurs enregistrés'
            : 'Données indisponibles',
        icon: FluentIcons.people,
        tone: const Color(0xFF19C997),
      ),
      (
        label: 'En maintenance',
        value: _metricValue(
          _snapshot.maintenanceCount,
          VehicleProvider.downloadedVehicles,
        ),
        detail: VehicleProvider.downloadedVehicles
            ? 'Pannes et réparations'
            : 'Données indisponibles',
        icon: FluentIcons.repair,
        tone: const Color(0xFFE96B8A),
      ),
      (
        label: 'Réservations',
        value: _metricValue(
          _snapshot.reservationsToday,
          PlanningProvider.downloadedPlanning,
        ),
        detail: PlanningProvider.downloadedPlanning
            ? 'Aujourd’hui'
            : 'Données indisponibles',
        icon: FluentIcons.event,
        tone: const Color(0xFFA375F5),
      ),
      (
        label: 'Coût des réparations',
        value: _hasLoaded
            ? _formatAmount(_snapshot.monthlyRepairCosts)
            : '—',
        detail: _snapshot.costsVerified
            ? 'Réparations enregistrées ce mois'
            : 'Montant local, potentiellement partiel',
        icon: FluentIcons.money,
        tone: const Color(0xFFE6A23C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 5
            : constraints.maxWidth < 680
                ? 2
                : 3;
        final gap = 12.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: DashboardMetricCard(
                  label: metric.label,
                  value: metric.value,
                  detail: metric.detail,
                  icon: metric.icon,
                  tone: metric.tone,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsLayout({required bool wide}) {
    final activity = DashboardPanel(
      title: 'Évolution de l’activité',
      icon: FluentIcons.chart,
      height: 310,
      trailing: _PeriodLabel(),
      child: FleetActivityChart(points: _snapshot.activity),
    );
    final states = DashboardPanel(
      title: 'État du parc',
      icon: FluentIcons.health,
      height: 310,
      child: FleetStateDonut(
        total: _snapshot.vehicleCount,
        segments: _snapshot.fleetStatus,
      ),
    );
    final recent = DashboardPanel(
      title: 'Activités récentes',
      icon: FluentIcons.database_activity,
      height: 310,
      trailing: _viewAllButton('events'),
      child: RecentActivityTimeline(
        activities: _snapshot.recentActivities,
      ),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: activity),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: states),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: recent),
        ],
      );
    }

    if (MediaQuery.sizeOf(context).width >= 760) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: activity),
              const SizedBox(width: 14),
              Expanded(child: states),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: recent),
        ],
      );
    }

    return Column(
      children: [
        activity,
        const SizedBox(height: 14),
        states,
        const SizedBox(height: 14),
        recent,
      ],
    );
  }

  Widget _buildOperationsLayout({required bool wide}) {
    final upcoming = DashboardPanel(
      title: 'Interventions à venir',
      icon: FluentIcons.event,
      height: 270,
      trailing: _viewAllButton('planner'),
      child: UpcomingInterventions(items: _snapshot.upcoming),
    );
    final watchlist = DashboardPanel(
      title: 'Véhicules à surveiller',
      icon: FluentIcons.health,
      height: 270,
      trailing: _viewAllButton('vehicle-manager'),
      child: VehiclesWatchlist(alerts: _snapshot.alerts),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: upcoming),
          const SizedBox(width: 14),
          Expanded(child: watchlist),
        ],
      );
    }

    return Column(
      children: [
        upcoming,
        const SizedBox(height: 14),
        watchlist,
      ],
    );
  }

  Widget _buildQuickActions({required bool compact}) {
    final actions = <({
      String label,
      IconData icon,
      Color tone,
      String destination,
    })>[
      (
        label: 'Gérer les véhicules',
        icon: FluentIcons.car,
        tone: const Color(0xFF279BFA),
        destination: 'vehicle-manager',
      ),
      (
        label: 'Ordres de réparation',
        icon: FluentIcons.repair,
        tone: const Color(0xFFA375F5),
        destination: 'repair-orders',
      ),
      (
        label: 'Planning & réservations',
        icon: FluentIcons.event,
        tone: const Color(0xFF19C997),
        destination: 'planner',
      ),
      (
        label: 'Gérer le stock',
        icon: FluentIcons.database_activity,
        tone: const Color(0xFFE6A23C),
        destination: 'workshop-stock',
      ),
      (
        label: 'Gérer les conducteurs',
        icon: FluentIcons.people,
        tone: const Color(0xFF279BFA),
        destination: 'driver-manager',
      ),
      (
        label: 'Journal d’activité',
        icon: FluentIcons.database_activity,
        tone: const Color(0xFF19C997),
        destination: 'events',
      ),
    ];

    return DashboardPanel(
      title: 'Accès rapides',
      icon: FluentIcons.chart,
      height: compact ? 228 : 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1050
              ? 6
              : constraints.maxWidth < 480
                  ? 2
                  : constraints.maxWidth < 760
                      ? 3
                      : 4;
          final gap = 9.0;
          final width =
              (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final action in actions.take(compact ? 4 : 6))
                SizedBox(
                  width: width,
                  child: DashboardQuickActionTile(
                    label: action.label,
                    icon: action.icon,
                    tone: action.tone,
                    onPressed: () =>
                        PaneItemsAndFooters.selectPane(action.destination),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _viewAllButton(String destination) {
    return Button(
      onPressed: () => PaneItemsAndFooters.selectPane(destination),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tout voir'),
          const SizedBox(width: 5),
          const Icon(FluentIcons.chevron_right, size: 11),
        ],
      ),
    );
  }

  String _metricValue(int value, bool available) =>
      _hasLoaded && available ? value.toString() : '—';

  String _formatAmount(double value) =>
      '${NumberFormat('#,##0', 'fr').format(value)} DA';

  Future<void> _refreshDashboard() async {
    if (_refreshing) return;

    final companyId = DatabaseGetter.activeCompanyId;
    setState(() {
      _refreshing = true;
      _loadMessage = null;
    });

    List<Reparation> history = [];
    var costsVerified = DatabaseGetter.database != null;

    try {
      await Future.wait<void>([
        _vehicles.refreshVehicles(),
        _vehicles.refreshDocuments(),
        _drivers.refreshConducteurs(),
        _drivers.refreshDocuments(),
        _logs.refreshLogs(),
        _plannings.refreshPlannings(),
        _repairs.refreshReparations(),
        _repairs.refreshPrestataires(),
      ]).timeout(const Duration(seconds: 30));
    } catch (error) {
      _loadMessage = 'Synchronisation incomplète : $error';
    }

    await _waitForProviderLoads();

    if (!VehicleProvider.downloadedVehicles ||
        !DriverProvider.downloadedConducteurs ||
        !PlanningProvider.downloadedPlanning ||
        !LogProvider.downloadedActivities ||
        !RepairProvider.downloadedReparations ||
        !VehicleProvider.downloadedDocuments) {
      _loadMessage ??=
          'Certaines données du tableau de bord ne sont pas synchronisées.';
    }

    final now = DateTime.now();
    final historyStart = now.subtract(const Duration(days: 180));

    try {
      history = await _repairs
          .getReparationInMarge(historyStart, now)
          .timeout(const Duration(seconds: 30));
    } catch (error) {
      costsVerified = false;
      history = RepairProvider.reparations.values
          .where((repair) =>
              !repair.date.isBefore(historyStart) &&
              !repair.date.isAfter(now))
          .toList(growable: false);
      _loadMessage ??=
          'Les coûts affichés proviennent du cache local et peuvent être partiels.';
      debugPrint('[ParcOto Dashboard] repair history fallback: $error');
    }

    try {
      await RepairProvider.downloadFicheReparations()
          .timeout(const Duration(seconds: 25));
      if (!RepairProvider.receptionSheetsVerified) {
        _loadMessage ??=
            'Les relevés kilométriques affichés proviennent du cache local et peuvent être partiels.';
      }
    } catch (error) {
      _loadMessage ??= 'Les relevés kilométriques ne sont pas disponibles.';
      debugPrint('[ParcOto Dashboard] reception sheets load failed: $error');
    }

    if (!mounted) return;
    if (companyId != DatabaseGetter.activeCompanyId) {
      setState(() {
        _snapshot = const DashboardSnapshot();
        _hasLoaded = false;
        _loadedCompanyId = null;
        _refreshing = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_refreshing) unawaited(_refreshDashboard());
      });
      return;
    }

    late final DashboardSnapshot snapshot;
    try {
      snapshot = _createSnapshot(
        history: history,
        costsVerified: costsVerified,
        now: now,
      );
    } catch (error, stackTrace) {
      debugPrint('[ParcOto Dashboard] snapshot failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _loadMessage ??= 'Certaines statistiques n’ont pas pu être calculées.';
      if (!mounted) return;
      setState(() {
        _snapshot = const DashboardSnapshot();
        _loadedCompanyId = companyId;
        _hasLoaded = true;
        _refreshing = false;
      });
      return;
    }

    setState(() {
      _snapshot = snapshot;
      _loadedCompanyId = companyId;
      _hasLoaded = true;
      _refreshing = false;
    });
  }

  Future<void> _waitForProviderLoads() async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    bool pending() =>
        VehicleProvider.downloadingVehicles ||
        VehicleProvider.downloadingDocuments ||
        DriverProvider.downloadingConducteurs ||
        DriverProvider.downloadingDocuments ||
        LogProvider.downloadingActivities ||
        PlanningProvider.downloadingPlanning ||
        RepairProvider.downloadingReparations ||
        RepairProvider.downloadingPrestataires;

    while (pending() && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 60));
    }
    if (pending()) {
      _loadMessage ??=
          'La synchronisation prend plus de temps que prévu. Certaines valeurs peuvent être incomplètes.';
    }
  }

  DashboardSnapshot _createSnapshot({
    required List<Reparation> history,
    required bool costsVerified,
    required DateTime now,
  }) {
    final vehicles = VehicleProvider.vehicles.values.toList(growable: false);
    final drivers = DriverProvider.conducteurs.values.toList(growable: false);
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrow = todayStart.add(const Duration(days: 1));
    final currentMonthRepairs = history.where((repair) =>
        repair.date.year == now.year && repair.date.month == now.month);
    final monthlyCost = currentMonthRepairs.fold<double>(
      0,
      (total, repair) => total + repair.getPrixTTC(),
    );

    final reservations = PlanningProvider.plannings.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final reservationsToday = reservations.where((item) =>
        !item.startTime.isBefore(todayStart) &&
        item.startTime.isBefore(tomorrow)).length;
    final upcoming = reservations
        .where((item) => item.endTime.isAfter(now))
        .take(4)
        .toList(growable: false);

    var available = 0;
    var broken = 0;
    var repairing = 0;
    var onMission = 0;
    var otherState = 0;
    var maintenance = 0;

    for (final vehicle in vehicles) {
      final state = vehicle.etatactuel ?? 0;
      switch (state) {
        case 5:
          available++;
          break;
        case 6:
          broken++;
          maintenance++;
          break;
        case 7:
          repairing++;
          maintenance++;
          break;
        case 8:
          onMission++;
          break;
        default:
          otherState++;
      }
    }

    final fleetStatus = <DashboardStatusSegment>[
      DashboardStatusSegment(
        label: 'Disponible',
        value: available,
        color: const Color(0xFF19C997),
      ),
      DashboardStatusSegment(
        label: 'En panne',
        value: broken,
        color: const Color(0xFFF05D76),
      ),
      DashboardStatusSegment(
        label: 'En réparation',
        value: repairing,
        color: const Color(0xFFE6A23C),
      ),
      DashboardStatusSegment(
        label: 'En mission',
        value: onMission,
        color: const Color(0xFF279BFA),
      ),
      DashboardStatusSegment(
        label: 'Autre état',
        value: otherState,
        color: const Color(0xFF929CB7),
      ),
    ];

    final activity = _buildActivitySeries(history, now);
    final recentActivities =
        LogProvider.activities.values.where((item) => item.createdAt != null || item.updatedAt != null).toList()
          ..sort((a, b) => _activityDate(b).compareTo(_activityDate(a)));

    final alerts = _buildAlerts(vehicles, now);

    return DashboardSnapshot(
      vehicleCount: vehicles.length,
      driverCount: drivers.length,
      maintenanceCount: maintenance,
      reservationsToday: reservationsToday,
      monthlyRepairCosts: monthlyCost,
      costsVerified: costsVerified,
      fleetStatus: fleetStatus,
      activity: activity,
      upcoming: upcoming,
      recentActivities: recentActivities.take(6).toList(growable: false),
      alerts: alerts,
    );
  }

  List<DashboardActivityPoint> _buildActivitySeries(
    List<Reparation> history,
    DateTime now,
  ) {
    final receptions = RepairProvider.repPerVeh.values
        .expand((items) => items)
        .where((fiche) => fiche.kilometrage != null && fiche.kilometrage! > 0)
        .toList(growable: false);

    final start = now.subtract(const Duration(days: 30));
    // Six complete five-day buckets cover the full 30-day period. Each point
    // is plotted at the end of its bucket so the final point reaches today.
    return List.generate(6, (index) {
      final bucketStart = start.add(Duration(days: index * 5));
      final bucketBoundary = bucketStart.add(const Duration(days: 5));
      final isLastBucket = index == 5;
      final bucketEnd = isLastBucket
          ? now.add(const Duration(milliseconds: 1))
          : bucketBoundary;

      final repairsCount = history.where((repair) =>
          !repair.date.isBefore(bucketStart) &&
          repair.date.isBefore(bucketEnd)).length;

      // Reception sheets store odometer readings, not travelled distance.
      // Keep the highest reading per vehicle in each five-day bucket to avoid
      // summing several visits for the same vehicle in that bucket.
      final mileageByVehicle = <String, int>{};
      for (final fiche in receptions) {
        if (fiche.dateEntre.isBefore(bucketStart) ||
            !fiche.dateEntre.isBefore(bucketEnd)) {
          continue;
        }
        final key = fiche.vehiculemat?.trim().isNotEmpty == true
            ? fiche.vehiculemat!.trim()
            : fiche.vehicule?.trim().isNotEmpty == true
                ? fiche.vehicule!.trim()
                : fiche.id;
        final mileage = fiche.kilometrage!;
        final previous = mileageByVehicle[key] ?? 0;
        if (mileage > previous) mileageByVehicle[key] = mileage;
      }

      final readings = mileageByVehicle.values.toList(growable: false);
      final mileageThousands = readings.isEmpty
          ? 0.0
          : readings.reduce((a, b) => a + b) /
              readings.length /
              1000.0;

      return DashboardActivityPoint(
        date: isLastBucket ? now : bucketBoundary,
        mileageThousands: mileageThousands,
        interventions: repairsCount,
      );
    });
  }

  List<DashboardAlert> _buildAlerts(
    List<legacy.Vehicle> vehicles,
    DateTime now,
  ) {
    final alerts = <DashboardAlert>[];
    final horizon = now.add(const Duration(days: 45));

    for (final document in VehicleProvider.documentsVehicules.values) {
      final expiration = document.dateExpiration;
      if (expiration == null || expiration.isAfter(horizon)) continue;

      final vehicle = _findVehicle(
        vehicles,
        id: document.vehicle,
        registration: document.vehiclemat,
      );
      final days = expiration.difference(now).inDays;
      final overdue = expiration.isBefore(now);
      alerts.add(
        DashboardAlert(
          title: vehicle?.matricule ??
              document.vehiclemat ??
              document.nom,
          subtitle: document.nom,
          tag: overdue ? 'Échu' : 'J-$days',
          severity: overdue
              ? DashboardAlertSeverity.danger
              : DashboardAlertSeverity.warning,
          dueDate: expiration,
        ),
      );
    }

    for (final vehicle in vehicles) {
      final currentMileage = vehicle.currentMileage;
      final nextService = vehicle.nextServiceMileage;
      if (currentMileage != null && nextService != null) {
        final remaining = nextService - currentMileage;
        if (remaining <= 500) {
          alerts.add(
            DashboardAlert(
              title: vehicle.matricule,
              subtitle: 'Révision kilométrique à prévoir',
              tag: remaining < 0 ? 'Dépassé' : '$remaining km',
              severity: remaining < 0
                  ? DashboardAlertSeverity.danger
                  : DashboardAlertSeverity.warning,
            ),
          );
        }
      }

      if (vehicle.etatactuel == 6 || vehicle.etatactuel == 7) {
        alerts.add(
          DashboardAlert(
            title: vehicle.matricule,
            subtitle: vehicle.etatactuel == 6
                ? 'Véhicule signalé en panne'
                : 'Véhicule actuellement en réparation',
            tag: vehicle.etatactuel == 6 ? 'Panne' : 'Atelier',
            severity: vehicle.etatactuel == 6
                ? DashboardAlertSeverity.danger
                : DashboardAlertSeverity.warning,
          ),
        );
      }
    }

    alerts.sort((a, b) {
      final severity = a.severity.index.compareTo(b.severity.index);
      if (severity != 0) return severity;
      return (a.dueDate ?? DateTime(9999))
          .compareTo(b.dueDate ?? DateTime(9999));
    });
    return alerts.take(6).toList(growable: false);
  }

  legacy.Vehicle? _findVehicle(
    List<legacy.Vehicle> vehicles, {
    String? id,
    String? registration,
  }) {
    for (final vehicle in vehicles) {
      if ((id != null && id.isNotEmpty && vehicle.id == id) ||
          (registration != null &&
              registration.isNotEmpty &&
              vehicle.matricule == registration)) {
        return vehicle;
      }
    }
    return null;
  }

  DateTime _activityDate(Activity activity) =>
      activity.createdAt ?? activity.updatedAt ?? DateTime(1970);

  @override
  bool get wantKeepAlive => true;
}

class _PeriodLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.fillColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.borderColor),
      ),
      child: Text(
        '30 derniers jours',
        style: TextStyle(
          color: theme.mutedTextColor,
          fontSize: 10,
        ),
      ),
    );
  }
}
