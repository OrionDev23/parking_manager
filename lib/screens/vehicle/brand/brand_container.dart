import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/services/vehicle_make_service.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../theme.dart';
import '../../../widgets/on_tap_scale.dart';
import '../../sidemenu/pane_items.dart';
import '../manager/vehicle_management.dart';
import '../manager/vehicle_tabs.dart';

class BrandContainer extends StatelessWidget {
  final VehicleMake make;

  const BrandContainer({super.key, required this.make});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final vehicleCount = VehicleProvider.vehicles.values
        .where((vehicle) =>
            VehicleMakeService.canonicalId(vehicle.marque) == make.id)
        .length;

    return OnTapScaleAndFade(
      onTap: () {
        PaneItemsAndFooters.selectPane('vehicle-manager');
        VehicleTabsState.currentIndex.value = 0;
        VehicleManagementState.brandFilterRequest.value = make.id;
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.backGroundColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: theme.borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: VehicleMakeLogo(makeId: make.id, size: 62),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              make.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    make.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.mutedTextColor,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  '$vehicleCount véhicule(s)',
                  style: TextStyle(
                    color: theme.mutedTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
