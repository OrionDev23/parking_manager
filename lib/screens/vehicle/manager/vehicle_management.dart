import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import '../../../batch_import/import_vehicles.dart';
import '../../logs/logging/log_table.dart';
import 'vehicle_form.dart';
import 'vehicle_tabs.dart';
import 'vehicles_table.dart';
import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../providers/counters.dart';
import '../../../theme.dart';
import '../../dashboard/pie_chart/pie_chart.dart';

const showImportButton=false;

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
        trailing: Row(
          children: [
            if(showImportButton && ClientDatabase().isAdmin())
            SizedBox(
                width: 200.px,
                height: 70.px,
                child: ButtonContainer(
                  color: appTheme.color.darkest,
                  icon: FluentIcons.add,
                  text: 'importlist'.tr(),
                  showBottom: false,
                  showCounter: false,
                  action: importList,
                )),
            if(showImportButton && ClientDatabase().isAdmin())
            smallSpace,
            SizedBox(
                width: 200.px,
                height: 70.px,
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
          ],
        ),
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
                      Flexible(
                        child: ValueListenableBuilder(
                            valueListenable: stateChanges,
                            builder: (context, val, w) {
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: ParcOtoPie(
                                  radius: kIsWeb?60:80,
                                  title: 'vstates'.tr(),
                                  labels: [
                                    MapEntry('gstate', DatabaseCounters().countVehicles(etat: 0)),
                                    MapEntry('bstate', DatabaseCounters().countVehicles(etat: 1)),
                                    MapEntry('rstate', DatabaseCounters().countVehicles(etat: 2)),
                                    MapEntry('ostate', DatabaseCounters().countVehicles(etat: 3)),
                                    MapEntry('restate', DatabaseCounters().countVehicles(etat: 4)),
                                  ],
                                ),
                              );
                            }),
                      ),
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


  void importList() async{
    FilePickerResult? pickedFile =await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if(pickedFile!=null){
      Future.delayed(const Duration(milliseconds: 50)).then((value) =>
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (c) {
                return ImportVehicles(file: pickedFile,);
              }));
    }
  }


  @override
  bool get wantKeepAlive => true;
}
