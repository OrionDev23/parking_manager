import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
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
                    action: (){},

                  )),
            ],
          ),
        ],
      ),
    );
  }
}
