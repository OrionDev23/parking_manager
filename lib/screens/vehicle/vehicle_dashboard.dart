import 'package:fluent_ui/fluent_ui.dart';

import 'brand/brand_list.dart';
import 'documents/document_tabs.dart';
import 'manager/vehicle_management.dart';
import 'states/state_tabs.dart';

/// Single entry point for the vehicle workspace.
/// Legacy destinations remain reachable through the existing deep-link notifier.
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
    return ValueListenableBuilder<int>(
      valueListenable: selectedSection,
      builder: (context, section, _) {
        switch (section) {
          case 1:
            return const DocumentTabs();
          case 2:
            return ValueListenableBuilder<int>(
              valueListenable: selectedReference,
              builder: (context, reference, _) =>
                  reference == 1 ? const StateTabs() : const BrandList(),
            );
          default:
            return const VehicleManagement();
        }
      },
    );
  }
}
