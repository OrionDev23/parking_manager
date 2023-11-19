import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_form.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/screens/vehicle/vehicles_table.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {


  final tstyle=TextStyle(
    fontSize: 10.sp,
  );



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
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
              children: [
                SizedBox(
                    width:60.w,
                    child: const VehicleTable()),
                const SizedBox(width: 10,),
                Flexible(
                  child: Column(
                    children: [
                      SizedBox(
                        height:20.h,
                                                child: PieChart(
                          PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: 120,
                              color: appTheme.color.darkest,
                            ),
                            PieChartSectionData(
                              value: 60,
                              color: appTheme.color,
                            ),
                            PieChartSectionData(
                              value: 180,
                              color: appTheme.color.lightest,
                            ),
                          ]
                          )
                        ),
                      ),
                      const SizedBox(height: 10,),

                    ],

                  ),
                ),
                const SizedBox(width: 10,),
                Flexible(child: Column(
                  children: [
                    SizedBox(height: 10.h,),
                    Row(children: [
                      Container(color: appTheme.color.darkest,width: 2.w,height: 1.w,),
                      const SizedBox(width: 5,),
                      Text('Bon état',style: tstyle,),
                    ],),
                    const SizedBox(height: 5,),
                    Row(children: [
                      Container(color: appTheme.color,width: 2.w,height: 1.w,),
                      const SizedBox(width: 5,),
                      Text('En panne',style: tstyle,),
                    ],),
                    const SizedBox(height: 5,),
                    Row(children: [
                      Container(color: appTheme.color,width: 2.w,height: 1.w,),
                      const SizedBox(width: 5,),
                      Text('En réparation',style: tstyle,),
                    ],),
                  ],
                )),
                const SizedBox(width: 10,),
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
      icon: const Icon(Bootstrap.car_front),
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
}
