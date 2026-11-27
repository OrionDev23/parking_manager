import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_ui/material_ui.dart' show Badge;
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/planning_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/serializables/conducteur/document_chauffeur.dart';
import 'package:parc_oto/serializables/planning.dart';
import 'package:parc_oto/serializables/vehicle/document_vehicle.dart';
import 'package:provider/provider.dart';

import '../../../serializables/notification.dart';
import '../../../theme.dart';
import 'notification_list_tile.dart';

/// Company-scoped operational alerts derived from documents and planning.
///
/// Read/unread state is deliberately not inferred from the badge count:
/// the current legacy source only provides actionable alerts, not persisted
/// per-user read receipts. A user-scoped Appwrite notification-state store
/// is required before we can accurately show shared unread counts.
class NotifList extends StatefulWidget {
  final String? companyId;
  final String? userId;

  const NotifList({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<NotifList> createState() => NotifListState();
}

class NotifListState extends State<NotifList>
    with AutomaticKeepAliveClientMixin {
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static List<PNotification> tiles = [];
  static bool loaded = false;
  static String? _loadedCompanyId;
  static String? _loadedUserId;

  int _loadGeneration = 0;
  bool loading = false;
  String? loadError;

  List<Planning> plannings = [];
  List<DocumentVehicle> docVehic = [];
  List<DocumentChauffeur> docChauf = [];

  DateTime get _throughDate => DateTime.now().add(const Duration(days: 60));

  @override
  void initState() {
    super.initState();
    getNotifs();
  }

  @override
  void didUpdateWidget(covariant NotifList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId ||
        oldWidget.userId != widget.userId) {
      _loadGeneration++;
      loading = false;
      loaded = false;
      _loadedCompanyId = null;
      _loadedUserId = null;
      tiles = [];
      changes.value++;
      getNotifs(force: true);
    }
  }

  static void remove(String id) {
    tiles.removeWhere((item) => item.id == id);
  }

  Future<void> getNotifs({bool force = false}) async {
    final companyId = widget.companyId;
    final userId = widget.userId;
    if (companyId == null ||
        companyId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      tiles = [];
      loaded = false;
      _loadedCompanyId = null;
      _loadedUserId = null;
      loading = false;
      if (mounted) setState(() {});
      changes.value++;
      return;
    }

    if (!force &&
        loaded &&
        _loadedCompanyId == companyId &&
        _loadedUserId == userId) {
      return;
    }
    if (loading) return;

    final generation = ++_loadGeneration;
    loading = true;
    loadError = null;
    if (mounted) setState(() {});
    changes.value++;

    try {
      await Future.wait([
        getVehicDocs(),
        getPlanningDocs(),
        getChaufDocs(),
      ]);

      if (!mounted ||
          generation != _loadGeneration ||
          widget.companyId != companyId ||
          widget.userId != userId ||
          DatabaseGetter.activeCompanyId != companyId) {
        return;
      }

      createNotifListFromLists();
      _loadedCompanyId = companyId;
      _loadedUserId = userId;
      loaded = true;
    } catch (error) {
      if (!mounted ||
          generation != _loadGeneration ||
          widget.companyId != companyId ||
          widget.userId != userId ||
          DatabaseGetter.activeCompanyId != companyId) {
        return;
      }
      loadError = error.toString();
      loaded = false;
    } finally {
      if (mounted && generation == _loadGeneration) {
        loading = false;
        setState(() {});
        changes.value++;
      }
    }
  }

  Future<void> getVehicDocs() async {
    docVehic = await VehicleProvider().getDocumentsBeforeTime(_throughDate);
  }

  Future<void> getChaufDocs() async {
    docChauf =
        await DriverProvider().getConduDocumentsBeforeTime(_throughDate);
  }

  Future<void> getPlanningDocs() async {
    plannings = await PlanningProvider().getPlanningBeforeTime(_throughDate);
  }

  void createNotifListFromLists() {
    final next = <PNotification>[];

    for (final document in docVehic) {
      final expiry = document.dateExpiration;
      if (expiry == null) continue;
      next.add(
        PNotification(
          id: document.id,
          title: document.nom,
          type: 0,
          date: expiry,
        ),
      );
    }

    for (final document in docChauf) {
      final expiry = document.dateExpiration;
      if (expiry == null) continue;
      next.add(
        PNotification(
          id: document.id,
          title: document.nom,
          type: 1,
          date: expiry,
        ),
      );
    }

    for (final planning in plannings) {
      next.add(
        PNotification(
          id: planning.id,
          title: planning.subject,
          type: 2,
          date: planning.startTime,
        ),
      );
    }

    next.sort((a, b) => a.date.compareTo(b.date));
    tiles = next;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appTheme = context.watch<AppTheme>();

    return ValueListenableBuilder<int>(
      valueListenable: changes,
      builder: (context, revision, _) {
        final count = tiles.length;
        final label = count > 99 ? '99+' : count.toString();
        return Tooltip(
          message: 'Notifications et alertes',
          child: IconButton(
            onPressed: showNotifications,
            icon: Badge(
              backgroundColor: count == 0
                  ? appTheme.mutedTextColor
                  : appTheme.color.lightest,
              alignment: Alignment.topRight,
              offset: const Offset(5, -4),
              label: Text(label),
              isLabelVisible: count > 0,
              child: Icon(
                count > 0 ? FluentIcons.ringer_solid : FluentIcons.ringer,
                size: 21,
                color: appTheme.textColor,
              ),
            ),
          ),
        );
      },
    );
  }

  void showNotifications() {
    final viewport = MediaQuery.sizeOf(context);
    final panelWidth = (viewport.width - 28).clamp(300.0, 540.0).toDouble();
    final panelHeight = (viewport.height - 150).clamp(260.0, 520.0).toDouble();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ValueListenableBuilder<int>(
        valueListenable: changes,
        builder: (context, revision, _) {
          final currentCount = tiles.length;
          return ContentDialog(
            constraints: BoxConstraints(
              maxWidth: panelWidth,
              maxHeight: panelHeight + 120,
            ),
            title: Row(
              children: [
                const Icon(FluentIcons.ringer_solid, size: 19),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$currentCount à traiter',
                  style: TextStyle(
                    color: Colors.grey[100],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Actualiser les alertes',
                  child: IconButton(
                    icon: const Icon(FluentIcons.refresh, size: 15),
                    onPressed: loading
                        ? null
                        : () => getNotifs(force: true),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: loading
                  ? const Center(child: ProgressRing())
                  : loadError != null
                      ? _errorState()
                      : tiles.isEmpty
                          ? _emptyState()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Documents arrivant à échéance et plannings à venir dans les 60 prochains jours.',
                                  style: TextStyle(
                                    color: Colors.grey[100],
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: tiles.length,
                                    separatorBuilder: (_, _) => Container(
                                      height: 1,
                                      color: Colors.grey[30],
                                    ),
                                    itemBuilder: (context, index) =>
                                        NotificationTile(
                                      key: ValueKey(tiles[index].id),
                                      pNotification: tiles[index],
                                    ),
                                  ),
                                ),
                              ],
                            ),
            ),
            actions: [
              Button(
                child: const Text('Fermer'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FluentIcons.check_mark,
            size: 34,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucune alerte à traiter',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Les documents et plannings sont à jour pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[100], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.warning, size: 30, color: Colors.orange),
          const SizedBox(height: 10),
          const Text(
            'Impossible de charger les alertes',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            loadError ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[100], fontSize: 10),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => getNotifs(force: true),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
