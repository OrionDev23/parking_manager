import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/screens/vehicle/vehicle_form.dart';
import 'package:parc_oto/screens/vehicle/vehicle_tabs.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../datasources/vehicules_datasource.dart';

class VehicleManagement extends StatefulWidget {
  const VehicleManagement({super.key});

  @override
  State<VehicleManagement> createState() => _VehicleManagementState();
}

class _VehicleManagementState extends State<VehicleManagement> {
  VehiculesDataSource vehicleDataSource = VehiculesDataSource();

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    initColumns();
    super.initState();
  }

  final tstyle=TextStyle(
    fontSize: 10.sp,
  );

  int sortColumn=0;

  void initColumns() {
    columns = [
      DataColumn2(
        label:  Text('nummat',style: tstyle,).tr(),
        size:ColumnSize.L,
        onSort: (s, c) {
          sortColumn=0;
          assending=!assending;

          vehicleDataSource.sort(1, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: Text('marque',style: tstyle,).tr(),
        size:ColumnSize.M,
        onSort: (s, c)  {
          sortColumn=1;
          assending=!assending;

          vehicleDataSource.sort(2, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: Text('type',style: tstyle,).tr(),
        size:ColumnSize.M,
        onSort: (s, c)  {
          sortColumn=2;
          assending=!assending;

          vehicleDataSource.sort(3, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: Text('year',style: tstyle,).tr(),
        size:ColumnSize.M,
        onSort: (s, c)  {
          sortColumn=3;
          assending=!assending;

          vehicleDataSource.sort(4, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: Text('dateModif',style: tstyle,).tr(),
        size:ColumnSize.L,
        onSort: (s, c)  {
          sortColumn=4;
          assending=!assending;

          vehicleDataSource.sort(6, assending);
          setState(() {

          });
        },
      ),
      const DataColumn2(
        label: Text(''),
        size:ColumnSize.S,
        onSort: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
      content: AsyncPaginatedDataTable2(
        sortAscending: assending,
        horizontalMargin: 5,
        sortColumnIndex: sortColumn,
        pageSyncApproach: PageSyncApproach.goToLast,
        showFirstLastButtons: true,
        renderEmptyRowsInTheEnd: false,
        fit: FlexFit.tight,
        columns: columns,
        source: vehicleDataSource,
        sortArrowAlwaysVisible: true,
        hidePaginator: false,
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
