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

  VehiculesDataSource vehicleDataSource=VehiculesDataSource();

  bool assending=false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    initColumns();
    super.initState();
  }

  void initColumns(){
    columns=[

      DataColumn2(
        label: const Text('id'),
        onSort: (s,c)=>vehicleDataSource.sort(0,assending),
      ), DataColumn2(
        label: const Text('matricule'),
        onSort: (s,c)=>vehicleDataSource.sort(1,assending),
      ), DataColumn2(
        label: const Text('marque'),
        onSort:(s,c)=> vehicleDataSource.sort(2,assending),
      ), DataColumn2(
        label: const Text('modele'),
        onSort:(s,c)=> vehicleDataSource.sort(3,assending),
      ), DataColumn2(
        label: const Text('annee'),
        onSort:(s,c)=> vehicleDataSource.sort(4,assending),
      ), DataColumn2(
        label: const Text('dateC'),
        onSort:(s,c)=> vehicleDataSource.sort(5,assending),
      ), DataColumn2(
        label: const Text('dateM'),
        onSort:(s,c)=> vehicleDataSource.sort(6,assending),
      ), const DataColumn2(
        label: Text(''),
        onSort: null,
      ),
    ];
  }
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

          SizedBox(
            width: 80.w,
            height: 70.h,
            child: AsyncPaginatedDataTable2(
              key: GlobalKey(),
                renderEmptyRowsInTheEnd: false,
                autoRowsToHeight: true,
                columns: columns,
                source: vehicleDataSource,
                  sortArrowAlwaysVisible: true,
              hidePaginator: false,
              errorBuilder: (s){
                  return Center(child: Text('Error $s',style: TextStyle(color:Colors.grey[100]),));
              },
            ),
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
