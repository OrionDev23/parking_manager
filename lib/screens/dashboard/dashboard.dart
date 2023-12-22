import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_tabs.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_form.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import '../../theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import '../vehicle/manager/vehicle_form.dart';
import '../vehicle/manager/vehicle_tabs.dart';
import 'transaction_chart.dart';
import 'table_stats.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const smallSpace = SizedBox(
      width: 5,
    );
    var appTheme = context.watch<AppTheme>();

    return ScaffoldPage(
      header: const PageTitle(text: 'home'),
      content: ListView(
        padding: const EdgeInsets.all(5),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 90.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ButtonContainer(
                    icon: FluentIcons.car,
                    text: 'vehicules'.tr(),
                    getCount: ClientDatabase().countVehicles,
                    action: (){
                      PanesListState.index.value=2;
                    },
                    actionList: (){
                      PanesListState.index.value=2;
                    },
                    actionNouveau: () {
                      PanesListState.index.value=2;
                      Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
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
                        final index = VehicleTabsState.tabs.length + 1;
                        VehicleTabsState.tabs.add(tab);
                        VehicleTabsState.currentIndex.value = index - 1;
                      });
                    },
                  ),
                  smallSpace,
                  ButtonContainer(
                      icon: FluentIcons.edit_event, text: 'reservation'.tr()),
                  smallSpace,
                  ButtonContainer(
                      icon: FluentIcons.people, text: 'chauffeurs'.tr(),
                    getCount:  ClientDatabase().countChauffeur,
                    action: (){
                      PanesListState.index.value=10;
                    },
                    actionList: (){
                      PanesListState.index.value=10;
                    },
                    actionNouveau: () {
                      PanesListState.index.value=10;
                      Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
                        late Tab tab;
                        tab = Tab(
                          key: UniqueKey(),
                          text: Text('nouvchauf'.tr()),
                          semanticLabel: 'nouvchauf'.tr(),
                          icon: const Icon(FluentIcons.people_add),
                          body: const ChauffeurForm(),
                          onClosed: () {
                            ChauffeurTabsState.tabs.remove(tab);

                            if (ChauffeurTabsState.currentIndex.value > 0) {
                              ChauffeurTabsState.currentIndex.value--;
                            }
                          },
                        );
                        final index = ChauffeurTabsState.tabs.length + 1;
                        ChauffeurTabsState.tabs.add(tab);
                        ChauffeurTabsState.currentIndex.value = index - 1;
                      });
                    },
                      ),
                  smallSpace,
                  ButtonContainer(
                    icon: FluentIcons.report_alert,
                    text: 'aide'.tr(),
                    textList: "oaide".tr(),
                    showBothLN: false,
                    showCounter: false,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: TableStats(),
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          boxShadow: kElevationToShadow[2],
                          borderRadius: BorderRadius.circular(5),
                          color: appTheme.mode == ThemeMode.dark
                              ? Colors.grey
                              : appTheme.mode == ThemeMode.light
                                  ? Colors.white
                                  : ThemeMode.system == ThemeMode.light
                                      ? Colors.white
                                      : Colors.grey),
                      height: 50.h,
                      child: const TransactionChart()),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TableStats(),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: TableStats(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
