import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../admin_parameters.dart';
import '../../../batch_import/import_vehicles.dart';
import '../../../theme.dart';
import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'vehicle_form.dart';
import 'vehicle_tabs.dart';
import 'vehicles_table.dart';


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
            if (showImportVehicles && ClientDatabase().isAdmin())
              ButtonContainer(
                color: appTheme.color.darkest,
                icon: FluentIcons.add,
                text: 'importlist'.tr(),
                showBottom: false,
                showCounter: false,
                action: importList,
              ),
            if (showImportVehicles && ClientDatabase().isAdmin()) smallSpace,
            ButtonContainer(
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
            ),
          ],
        ),
      ),
      content: const VehicleTable()
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

  void importList() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (pickedFile != null) {
      Future.delayed(const Duration(milliseconds: 50))
          .then((value) => showDialog(
              context: context,
              barrierDismissible: true,
              builder: (c) {
                return ImportVehicles(
                  file: pickedFile,
                );
              }));
    }
  }

  @override
  bool get wantKeepAlive => true;
}
