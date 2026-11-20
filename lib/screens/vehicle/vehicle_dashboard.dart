import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../../ui/design_system/parcoto_tokens.dart';
import 'brand/brand_list.dart';
import 'documents/document_tabs.dart';
import 'manager/vehicle_tabs.dart';
import 'states/state_tabs.dart';

/// Unified workspace for the vehicle domain.
/// Legacy destinations are mapped to sections inside this workspace.
class VehicleDashboard extends StatelessWidget {
  const VehicleDashboard({super.key});

  static final ValueNotifier<int> selectedSection = ValueNotifier<int>(0);
  static final ValueNotifier<int> selectedReference = ValueNotifier<int>(0);

  static void selectLegacySection(String key) {
    switch (key) {
      case 'vehicle-manager':
        selectedSection.value = 0;
        break;
      case 'vehicle-documents':
        selectedSection.value = 1;
        break;
      case 'vehicle-brands':
        selectedSection.value = 2;
        selectedReference.value = 0;
        break;
      case 'vehicle-states':
        selectedSection.value = 2;
        selectedReference.value = 1;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkspaceHeader(),
          _WorkspaceNavigation(),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: selectedSection,
              builder: (context, section, _) => IndexedStack(
                index: section.clamp(0, 2).toInt(),
                children: const [
                  VehicleTabs(),
                  DocumentTabs(),
                  _VehicleReferencesWorkspace(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final compact =
        MediaQuery.sizeOf(context).width < ParcotoTokens.mobileBreakpoint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 28,
        vertical: compact ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 42 : 48,
            height: compact ? 42 : 48,
            decoration: BoxDecoration(
              color: theme.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              FluentIcons.car,
              color: theme.color,
              size: compact ? 21 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Véhicules',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: compact ? 21 : 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  compact
                      ? 'Votre parc automobile'
                      : 'Pilotez votre parc, ses documents et ses référentiels depuis un seul espace.',
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: VehicleDashboard.selectedSection,
        builder: (context, selected, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _WorkspaceTab(
              label: 'Parc automobile',
              icon: FluentIcons.car,
              selected: selected == 0,
              onPressed: () => VehicleDashboard.selectedSection.value = 0,
            ),
            _WorkspaceTab(
              label: 'Documents',
              icon: FluentIcons.document_set,
              selected: selected == 1,
              onPressed: () => VehicleDashboard.selectedSection.value = 1,
            ),
            _WorkspaceTab(
              label: 'Référentiels',
              icon: FluentIcons.settings,
              selected: selected == 2,
              onPressed: () => VehicleDashboard.selectedSection.value = 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _WorkspaceTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        backgroundColor: WidgetStateProperty.all(
          selected ? theme.color.withValues(alpha: .12) : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.all(
          selected ? theme.color : theme.mutedTextColor,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleReferencesWorkspace extends StatelessWidget {
  const _VehicleReferencesWorkspace();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          decoration: BoxDecoration(
            color: theme.backGroundColor,
            border: Border(bottom: BorderSide(color: theme.borderColor)),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: VehicleDashboard.selectedReference,
            builder: (context, selected, _) => Wrap(
              spacing: 8,
              children: [
                _WorkspaceTab(
                  label: 'Marques',
                  icon: FluentIcons.verified_brand,
                  selected: selected == 0,
                  onPressed: () =>
                      VehicleDashboard.selectedReference.value = 0,
                ),
                _WorkspaceTab(
                  label: 'États du véhicule',
                  icon: FluentIcons.health,
                  selected: selected == 1,
                  onPressed: () =>
                      VehicleDashboard.selectedReference.value = 1,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: VehicleDashboard.selectedReference,
            builder: (context, selected, _) => IndexedStack(
              index: selected.clamp(0, 1).toInt(),
              children: const [
                BrandList(),
                StateTabs(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
