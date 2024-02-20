import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';
import '../vehicle/manager/vehicles_table.dart';

class AppartenanceContainer extends StatefulWidget {
  final String fieldToSearch;
  final bool filliale;
  final String name;

  const AppartenanceContainer(
      {super.key,
      this.filliale = true,
      required this.fieldToSearch,
      required this.name});

  @override
  State<AppartenanceContainer> createState() => _AppartenanceContainerState();
}

class _AppartenanceContainerState extends State<AppartenanceContainer> {
  bool loading = true;
  int? vCount;

  @override
  void initState() {
    getCount();
    super.initState();
  }

  void getCount() async {
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehiculeid,
        queries: [
          Query.equal(widget.fieldToSearch, widget.name.replaceAll(' ', '').toUpperCase()),
          Query.limit(1),
        ]).then((value) {
      vCount = value.total;
    });
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return OnTapScaleAndFade(
      child: Container(
        width: 200.px,
        height: 80.px,
        decoration: BoxDecoration(
            borderRadius:BorderRadius.circular(5),
            color: appTheme.backGroundColor,
            boxShadow: kElevationToShadow[2]),
        child: Column(
          children: [
            if (widget.filliale)
              Text(
                VehiclesUtilities.getAppartenance(widget.name),
                style:
                    TextStyle(fontSize: 18.px, color: appTheme.color.lightest),
              ),
            if (!widget.filliale)
              Text(
                VehiclesUtilities.getDirection(widget.name),
                style:
                    TextStyle(fontSize: 18.px, color: appTheme.color.lightest),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(5),
              child: loading
                  ? const Text('')
                  : Text(
                      '$vCount ${'vehicules'.tr()}',
                      style: appTheme.writingStyle,
                    ),
            ),
          ],
        ),
      ),
      onTap: () {
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
            1;
        VehicleTabsState.currentIndex.value = 0;

        VehicleTableState.filterNow = true;
        VehicleTableState.filterVehicule.value =
            '"${widget.name.replaceAll(' ', '').toUpperCase()}"';
      },
    );
  }
}
