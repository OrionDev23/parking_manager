import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/screens/vehicle/vehicle_form.dart';
import 'package:parc_oto/screens/vehicle/vehicle_tabs.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageTitle(text:'gestionvehicles'.tr()),
      content: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                  width: 15.w,
                  height: 10.h,
                  child: ButtonContainer(
                    icon: FluentIcons.add,
                    text: 'add'.tr(),
                    showBottom: false,
                    showCounter: false,
                    action: (){
                      final index = VehicleTabsState.tabs.length + 1;
                      final tab = generateTab(index);
                      VehicleTabsState.tabs.add(tab);
                      VehicleTabsState.currentIndex.value=index-1;
                    },

                  )),
            ],
          ),
        ],
      ),
    );
  }


  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      text: Text('nouvvehicule'.tr()),
      semanticLabel: 'nouvvehicule'.tr(),
      icon: const Icon(Bootstrap.car_front),
      body: const VehicleForm(),
      onClosed: () {
        VehicleTabsState.tabs.remove(tab);

        if (VehicleTabsState.currentIndex.value > 0) VehicleTabsState.currentIndex.value--;
      },
    );
    return tab;
  }
}
