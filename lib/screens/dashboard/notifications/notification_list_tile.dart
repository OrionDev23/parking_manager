import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/planning_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/screens/dashboard/notifications/notif_list.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_dismissal_service.dart';

import '../../../main.dart';
import '../../../providers/client_database.dart';
import '../../../serializables/notification.dart';
import '../../sidemenu/pane_items.dart';

class NotificationTile extends StatefulWidget {
  final String companyId;
  final String userId;
  final PNotification pNotification;

  const NotificationTile({
    super.key,
    required this.companyId,
    required this.userId,
    required this.pNotification,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool confirmingDismiss = false;

  DateTime get _day => DateTime(
        widget.pNotification.date.year,
        widget.pNotification.date.month,
        widget.pNotification.date.day,
      );

  int get _daysFromToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _day.difference(today).inDays;
  }

  String get _description {
    final days = _daysFromToday;
    final subject = '«${widget.pNotification.title}»';

    if (widget.pNotification.type == 2) {
      if (days < 0) {
        return 'Le planning $subject a commencé il y a ${days.abs()} jour(s).';
      }
      if (days == 0) return 'Le planning $subject commence aujourd’hui.';
      if (days == 1) return 'Le planning $subject commence demain.';
      return 'Le planning $subject commence dans $days jours.';
    }

    if (days < 0) {
      return 'Le document $subject est expiré depuis ${days.abs()} jour(s).';
    }
    if (days == 0) return 'Le document $subject expire aujourd’hui.';
    if (days == 1) return 'Le document $subject expire demain.';
    return 'Le document $subject expire dans $days jours.';
  }

  String get _dateLabel {
    return DateFormat('dd/MM/yyyy').format(widget.pNotification.date);
  }

  Color _severityColor(AppTheme theme) {
    if (_daysFromToday < 0) return Colors.red;
    if (_daysFromToday <= 7) return Colors.orange;
    return theme.color;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final severityColor = _severityColor(theme);
    final icon = widget.pNotification.type == 2
        ? FluentIcons.event
        : FluentIcons.document;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: severityColor.withValues(alpha: .22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: severityColor, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: confirmingDismiss
                ? _dismissConfirmation(theme)
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: goThere,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.pNotification.type == 2 ? 'Date du planning' : 'Date d’expiration'} : $_dateLabel',
                          style: TextStyle(
                            color: theme.mutedTextColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          if (!confirmingDismiss)
            Tooltip(
              message: 'Masquer cette alerte pour ce compte',
              child: IconButton(
                icon: Icon(
                  FluentIcons.cancel,
                  size: 14,
                  color: theme.mutedTextColor,
                ),
                onPressed: () => setState(() => confirmingDismiss = true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dismissConfirmation(AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Masquer cette alerte pour ce compte ? La synchronisation se fera dès que possible.',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          children: [
            Button(
              onPressed: dismiss,
              child: const Text('Masquer'),
            ),
            Button(
              onPressed: () => setState(() => confirmingDismiss = false),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> dismiss() async {
    final basePreferenceKey = widget.pNotification.type == 0
        ? 'removedDocs'
        : widget.pNotification.type == 1
            ? 'removedCondDocs'
            : 'removedPlanning';
    final recordName = userScopedPreferenceKey(basePreferenceKey);

    try {
      late List<String> storedData;
      if (widget.pNotification.type == 0) {
        VehicleProvider.removedVehiDocs = prefs.getStringList(recordName) ?? [];
        storedData = VehicleProvider.removedVehiDocs;
      } else if (widget.pNotification.type == 1) {
        DriverProvider.removedCondDocs = prefs.getStringList(recordName) ?? [];
        storedData = DriverProvider.removedCondDocs;
      } else {
        PlanningProvider.removedPlanDocs = prefs.getStringList(recordName) ?? [];
        storedData = PlanningProvider.removedPlanDocs;
      }

      if (!storedData.contains(widget.pNotification.id)) {
        storedData.add(widget.pNotification.id);
      }
      await prefs.setStringList(recordName, storedData);
      unawaited(
        NotificationDismissalService.syncDismissal(
          companyId: widget.companyId,
          userId: widget.userId,
          type: widget.pNotification.type,
          id: widget.pNotification.id,
        ),
      );

      if (!mounted) return;
      if (widget.pNotification.type == 0) {
        VehicleProvider.removedVehiDocs = storedData;
      } else if (widget.pNotification.type == 1) {
        DriverProvider.removedCondDocs = storedData;
      } else {
        PlanningProvider.removedPlanDocs = storedData;
      }

      NotifListState.remove(
        widget.pNotification.id,
        type: widget.pNotification.type,
      );
      NotifListState.changes.value++;
    } catch (error) {
      if (!mounted) return;
      setState(() => confirmingDismiss = false);
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible de masquer cette alerte'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
      );
    }
  }

  void goThere() {
    switch (widget.pNotification.type) {
      case 0:
        PaneItemsAndFooters.selectPane('vehicle-documents');
        break;
      case 1:
        PaneItemsAndFooters.selectPane('driver-documents');
        break;
      case 2:
        PaneItemsAndFooters.selectPane('planner');
        break;
    }
    Navigator.of(context).pop();
  }
}
