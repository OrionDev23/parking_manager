import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/logs/logging/log_table.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_form.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicles_table.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../dashboard/pie_chart/pie_chart.dart';

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => VehicleManagementState();
}

class VehicleManagementState extends State<VehicleManagement>
    with AutomaticKeepAliveClientMixin<VehicleManagement> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  static ValueNotifier<int> stateChanges = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'gestionvehicles'.tr(),
        trailing: SizedBox(
            width: 15.w,
            height: 10.h,
            child: ButtonContainer(
              icon: FluentIcons.add,
              text: 'add'.tr(),
              showBottom: false,
              showCounter: false,
              action: () {
                final index = VehicleTabsState.tabs.length + 1;
                final tab = generateTab(index);
                VehicleTabsState.tabs.add(tab);
                VehicleTabsState.currentIndex.value = index - 1;
              },
            )),
      ),
      content: Column(
        children: [
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 60.w, child: const VehicleTable()),
                smallSpace,
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder(
                          valueListenable: stateChanges,
                          builder: (context, val, w) {
                            return ParcOtoPie(
                              title: 'vstates'.tr(),
                              labels: [
                                MapEntry('gstate',
                                    ClientDatabase().countVehicles(etat: 0)),
                                MapEntry('bstate',
                                    ClientDatabase().countVehicles(etat: 1)),
                                MapEntry('rstate',
                                    ClientDatabase().countVehicles(etat: 2))
                              ],
                            );
                          }),
                      smallSpace,
                      Text(
                        'lactivities',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appTheme.writingStyle.color),
                      ).tr(),
                      smallSpace,
                      const Flexible(
                        child: LogTable(
                          statTable: true,
                          pages: false,
                          numberOfRows: 3,
                          filters: {'typemin': '0', 'typemax': '9'},
                          fieldsToShow: ['act', 'date'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvvehicule'.tr()),
      semanticLabel: 'nouvvehicule'.tr(),
      icon: const Icon(FluentIcons.new_folder),
      body: const VehicleForm(),
      onClosed: () {
        VehicleTabsState.tabs.remove(tab);

        if (VehicleTabsState.currentIndex.value > 0) {
          VehicleTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }

  @override
  bool get wantKeepAlive => true;
}
