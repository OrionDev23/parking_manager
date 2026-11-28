import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';

enum _DemoSpaceStatus { free, occupied, reserved, blocked }

class _DemoSpace {
  final String code;
  final _DemoSpaceStatus status;
  final String? registration;

  const _DemoSpace(this.code, this.status, [this.registration]);
}

/// First visual workspace for the Parking module.
///
/// The data is deliberately local demonstration data. It is not connected to
/// Appwrite and must not be mistaken for a live occupancy dashboard.
class ParkingDashboard extends StatefulWidget {
  const ParkingDashboard({super.key});

  @override
  State<ParkingDashboard> createState() => _ParkingDashboardState();
}

class _ParkingDashboardState extends State<ParkingDashboard> {
  static const _spaces = <_DemoSpace>[
    _DemoSpace('A-01', _DemoSpaceStatus.occupied, '12345-116-23'),
    _DemoSpace('A-02', _DemoSpaceStatus.free),
    _DemoSpace('A-03', _DemoSpaceStatus.occupied, '08721-118-16'),
    _DemoSpace('A-04', _DemoSpaceStatus.free),
    _DemoSpace('A-05', _DemoSpaceStatus.reserved),
    _DemoSpace('A-06', _DemoSpaceStatus.occupied, '05518-120-16'),
    _DemoSpace('A-07', _DemoSpaceStatus.free),
    _DemoSpace('A-08', _DemoSpaceStatus.blocked),
    _DemoSpace('B-01', _DemoSpaceStatus.occupied, '09122-117-23'),
    _DemoSpace('B-02', _DemoSpaceStatus.free),
    _DemoSpace('B-03', _DemoSpaceStatus.free),
    _DemoSpace('B-04', _DemoSpaceStatus.occupied, '04461-119-16'),
    _DemoSpace('B-05', _DemoSpaceStatus.reserved),
    _DemoSpace('B-06', _DemoSpaceStatus.free),
    _DemoSpace('B-07', _DemoSpaceStatus.occupied, '07731-121-16'),
    _DemoSpace('B-08', _DemoSpaceStatus.free),
    _DemoSpace('C-01', _DemoSpaceStatus.free),
    _DemoSpace('C-02', _DemoSpaceStatus.occupied, '02114-122-16'),
    _DemoSpace('C-03', _DemoSpaceStatus.free),
    _DemoSpace('C-04', _DemoSpaceStatus.blocked),
    _DemoSpace('C-05', _DemoSpaceStatus.free),
    _DemoSpace('C-06', _DemoSpaceStatus.occupied, '06124-123-16'),
    _DemoSpace('C-07', _DemoSpaceStatus.free),
    _DemoSpace('C-08', _DemoSpaceStatus.free),
  ];

  int _selectedIndex = 6;
  String _activeZone = 'Toutes les zones';

  Color _statusColor(_DemoSpaceStatus status, AppTheme theme) {
    switch (status) {
      case _DemoSpaceStatus.free:
        return const Color(0xFF24B47E);
      case _DemoSpaceStatus.occupied:
        return theme.color;
      case _DemoSpaceStatus.reserved:
        return const Color(0xFFE3A33D);
      case _DemoSpaceStatus.blocked:
        return const Color(0xFFE05B67);
    }
  }

  String _statusLabel(_DemoSpaceStatus status) {
    switch (status) {
      case _DemoSpaceStatus.free:
        return 'Libre';
      case _DemoSpaceStatus.occupied:
        return 'Occupée';
      case _DemoSpaceStatus.reserved:
        return 'Réservée';
      case _DemoSpaceStatus.blocked:
        return 'Bloquée';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final selected = _spaces[_selectedIndex];
    final visibleSpaces = _spaces.where((space) {
      if (_activeZone == 'Toutes les zones') return true;
      return space.code.startsWith(_activeZone.substring(5));
    }).toList(growable: false);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          return ListView(
            padding: EdgeInsets.all(compact ? 16 : 26),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parking',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: compact ? 24 : 29,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Conception et exploitation des stationnements',
                          style: TextStyle(color: theme.mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  if (!compact)
                    FilledButton(
                      onPressed: () => _showNotConnected(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.add, size: 14),
                          SizedBox(width: 8),
                          Text('Créer un parking'),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _DemoNotice(theme: theme),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricCard(
                    label: 'Capacité',
                    value: '24',
                    detail: 'Places configurées',
                    icon: FluentIcons.car,
                    theme: theme,
                  ),
                  _MetricCard(
                    label: 'Occupées',
                    value: '8',
                    detail: '33 % du parking',
                    icon: FluentIcons.car_solid,
                    theme: theme,
                    accent: theme.color,
                  ),
                  _MetricCard(
                    label: 'Disponibles',
                    value: '12',
                    detail: 'Prêtes à affecter',
                    icon: FluentIcons.check_mark,
                    theme: theme,
                    accent: const Color(0xFF24B47E),
                  ),
                  _MetricCard(
                    label: 'Indisponibles',
                    value: '4',
                    detail: 'Réservées ou bloquées',
                    icon: FluentIcons.blocked,
                    theme: theme,
                    accent: const Color(0xFFE3A33D),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Vue du parking',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!compact)
                    ComboBox<String>(
                      value: _activeZone,
                      items: [
                        'Toutes les zones',
                        'Zone A',
                        'Zone B',
                        'Zone C',
                      ].map((zone) => ComboBoxItem(
                        value: zone,
                        child: Text(zone),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _activeZone = value);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (compact) ...[
                _PlanLegend(theme: theme, statusColor: _statusColor),
                const SizedBox(height: 12),
                _PlanGrid(
                  spaces: visibleSpaces,
                  selectedCode: selected.code,
                  theme: theme,
                  statusColor: _statusColor,
                  onSelect: (space) => setState(
                    () => _selectedIndex = _spaces.indexOf(space),
                  ),
                ),
                const SizedBox(height: 14),
                _SpaceInspector(
                  space: selected,
                  theme: theme,
                  statusLabel: _statusLabel,
                  statusColor: _statusColor,
                  onAction: () => _showNotConnected(context),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _PlanGrid(
                        spaces: visibleSpaces,
                        selectedCode: selected.code,
                        theme: theme,
                        statusColor: _statusColor,
                        onSelect: (space) => setState(
                          () => _selectedIndex = _spaces.indexOf(space),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _SpaceInspector(
                        space: selected,
                        theme: theme,
                        statusLabel: _statusLabel,
                        statusColor: _statusColor,
                        onAction: () => _showNotConnected(context),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              _PlanLegend(theme: theme, statusColor: _statusColor),
            ],
          );
        },
      ),
    );
  }

  void _showNotConnected(BuildContext context) {
    displayInfoBar(
      context,
      builder: (context, close) => const InfoBar(
        title: Text('Fonction en cours de développement'),
        content: Text(
          'Cette maquette utilise des données de démonstration. '
          'Aucune opération réelle n’est envoyée.',
        ),
        severity: InfoBarSeverity.info,
      ),
      duration: const Duration(seconds: 4),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  final AppTheme theme;
  const _DemoNotice({required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.color.withValues(alpha: .08),
          border: Border.all(color: theme.color.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(theme.cardRadius),
        ),
        child: Row(
          children: [
            Icon(FluentIcons.info, color: theme.color, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aperçu de conception — données fictives, sans connexion Appwrite',
                style: TextStyle(color: theme.textColor, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final AppTheme theme;
  final Color? accent;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.theme,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? theme.mutedTextColor;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: TextStyle(color: theme.mutedTextColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PlanGrid extends StatelessWidget {
  final List<_DemoSpace> spaces;
  final String selectedCode;
  final AppTheme theme;
  final Color Function(_DemoSpaceStatus) statusColor;
  final ValueChanged<_DemoSpace> onSelect;

  const _PlanGrid({
    required this.spaces,
    required this.selectedCode,
    required this.theme,
    required this.statusColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.map_pin, color: theme.color, size: 16),
              const SizedBox(width: 8),
              Text(
                'Dépôt principal · Plan de démonstration',
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Niveau 01',
                style: TextStyle(color: theme.mutedTextColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final zone in ['A', 'B', 'C'])
            if (spaces.any((space) => space.code.startsWith(zone)))
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONE $zone',
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final space in spaces.where(
                          (item) => item.code.startsWith(zone),
                        ))
                          _SpaceTile(
                            space: space,
                            selected: space.code == selectedCode,
                            color: statusColor(space.status),
                            theme: theme,
                            onTap: () => onSelect(space),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.backGroundColor,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: theme.borderColor),
            ),
            child: Text(
              'VOIE DE CIRCULATION',
              style: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  final _DemoSpace space;
  final bool selected;
  final Color color;
  final AppTheme theme;
  final VoidCallback onTap;

  const _SpaceTile({
    required this.space,
    required this.selected,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 76,
        height: 54,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? .24 : .12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? theme.color : color.withValues(alpha: .65),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              space.status == _DemoSpaceStatus.occupied
                  ? FluentIcons.car
                  : space.status == _DemoSpaceStatus.blocked
                      ? FluentIcons.blocked
                      : space.status == _DemoSpaceStatus.reserved
                          ? FluentIcons.calendar
                          : FluentIcons.check_mark,
              size: 13,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              space.code,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceInspector extends StatelessWidget {
  final _DemoSpace space;
  final AppTheme theme;
  final String Function(_DemoSpaceStatus) statusLabel;
  final Color Function(_DemoSpaceStatus) statusColor;
  final VoidCallback onAction;

  const _SpaceInspector({
    required this.space,
    required this.theme,
    required this.statusLabel,
    required this.statusColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(space.status);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Détail de la place',
                  style: TextStyle(
                    color: theme.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(FluentIcons.more, color: theme.mutedTextColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            space.code,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel(space.status),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _InspectorLine(label: 'Zone', value: space.code.substring(0, 1), theme: theme),
          _InspectorLine(label: 'Rangée', value: space.code.substring(0, 1), theme: theme),
          _InspectorLine(label: 'Dimensions', value: '2,50 × 5,00 m', theme: theme),
          _InspectorLine(
            label: 'Véhicule',
            value: space.registration ?? 'Aucun',
            theme: theme,
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: onAction,
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('Voir la fiche véhicule')),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onAction,
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('Affecter / déplacer')),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorLine extends StatelessWidget {
  final String label;
  final String value;
  final AppTheme theme;

  const _InspectorLine({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: theme.mutedTextColor, fontSize: 11),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PlanLegend extends StatelessWidget {
  final AppTheme theme;
  final Color Function(_DemoSpaceStatus) statusColor;

  const _PlanLegend({required this.theme, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final items = [
      (_DemoSpaceStatus.free, 'Libre'),
      (_DemoSpaceStatus.occupied, 'Occupée'),
      (_DemoSpaceStatus.reserved, 'Réservée'),
      (_DemoSpaceStatus.blocked, 'Bloquée'),
    ];
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor(item.$1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.$2,
                style: TextStyle(color: theme.mutedTextColor, fontSize: 10),
              ),
            ],
          ),
      ],
    );
  }
}
