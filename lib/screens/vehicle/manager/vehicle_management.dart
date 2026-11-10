import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';

import '../../../admin_parameters.dart';
import '../../../batch_import/import_vehicles.dart';
import '../../../theme.dart';
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
  static ValueNotifier<int> stateChanges = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      header: PageTitle(
        text: 'gestionvehicles'.tr(),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showImportVehicles && DatabaseGetter().isAdmin()) ...[
                Button(
                  onPressed: importList,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.open_file, size: 14),
                      const SizedBox(width: 7),
                      const Text('importlist').tr(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: () {
                  final index = VehicleTabsState.tabs.length + 1;
                  final tab = generateTab(index);
                  VehicleTabsState.tabs.add(tab);
                  VehicleTabsState.currentIndex.value = index - 1;
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.add, size: 14),
                    const SizedBox(width: 7),
                    const Text('add').tr(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[30]),
        ),
        clipBehavior: Clip.antiAlias,
        child: const VehicleTable(),
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

  Future<void> importList() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (pickedFile == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (c) {
        return ImportVehicles(
          file: pickedFile,
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
