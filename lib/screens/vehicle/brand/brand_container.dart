import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../sidemenu/pane_items.dart';
import '../../sidemenu/sidemenu.dart';
import '../manager/vehicles_table.dart';

class BrandContainer extends StatefulWidget {
  final int? id;

  const BrandContainer({super.key, this.id});

  @override
  State<BrandContainer> createState() => _BrandContainerState();
}

class _BrandContainerState extends State<BrandContainer> {
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
          Query.equal('marque', widget.id.toString()),
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
        width: 10.w,
        height: 10.h,
        decoration: BoxDecoration(
            color: appTheme.backGroundColor, boxShadow: kElevationToShadow[2]),
        child: Stack(
          children: [
            Positioned.fill(
                child: Image.asset(
              'assets/images/marques/${widget.id ?? 'default'}.webp',
              fit: BoxFit.scaleDown,
            )),
            Positioned(
                bottom: 1.h,
                right: 1.w,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: loading
                      ? const Text('')
                      : Text(
                          '$vCount ${'vehicules'.tr()}',
                          style: appTheme.writingStyle,
                        ),
                )),
          ],
        ),
      ),
      onTap: () {
        PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
            1;
        VehicleTabsState.currentIndex.value = 0;

        VehicleTableState.filterNow = true;
        VehicleTableState.filterMarque.value = widget.id;
      },
    );
  }
}
