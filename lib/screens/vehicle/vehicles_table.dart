import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../datasources/vehicules_datasource.dart';

class VehicleTable extends StatefulWidget {
  const VehicleTable({super.key});

  @override
  State<VehicleTable> createState() => _VehicleTableState();
}

class _VehicleTableState extends State<VehicleTable> {

  late VehiculesDataSource vehicleDataSource;

  bool assending = false;

  late List<DataColumn2> columns;



  @override
  void initState() {
    vehicleDataSource=VehiculesDataSource(current: context);
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
        label:  Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text('nummat',style: tstyle,).tr(),
        ),
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
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text('type',style: tstyle,).tr(),
        ),
        size:ColumnSize.L,
        onSort: (s, c)  {
          sortColumn=1;
          assending=!assending;

          vehicleDataSource.sort(2, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text('year',style: tstyle,).tr(),
        ),
        size:ColumnSize.M,
        onSort: (s, c)  {
          sortColumn=2;
          assending=!assending;

          vehicleDataSource.sort(4, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text('dateModif',style: tstyle,).tr(),
        ),
        size:ColumnSize.L,
        onSort: (s, c)  {
          sortColumn=3;
          assending=!assending;
          vehicleDataSource.sort(6, assending);
          setState(() {

          });
        },
      ),
      DataColumn2(
        label: const Text(''),
        size:ColumnSize.S,
        fixedWidth: 2.w,
        onSort: null,
      ),
    ];
  }

  int rowPerPage=12;
  @override
  Widget build(BuildContext context) {
    return AsyncPaginatedDataTable2(
      header:
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(icon: const Icon(FluentIcons.filter), onPressed: (){}),
            const SizedBox(width: 10,),

            SizedBox(
              width: 30.w,
              height: 7.h,
              child: TextBox(
                placeholder: 'search'.tr(),
              ),
            ),
          ],
        ),
      ),
      sortAscending: assending,
      horizontalMargin: 8,
      columnSpacing: 0,
      dataRowHeight: 3.5.h,
      onPageChanged: (s){

      },
      sortColumnIndex: sortColumn,
      rowsPerPage: rowPerPage,
      onRowsPerPageChanged: (nbr){
         rowPerPage=nbr??12;
      },
      availableRowsPerPage: const [
        12,24,50,100,200
      ],
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: false,
      fit: FlexFit.tight,
      columns: columns,
      source: vehicleDataSource,
      sortArrowAlwaysVisible: true,
      hidePaginator: false,
    );
  }


  @override
  void dispose() {
    vehicleDataSource.dispose();
    super.dispose();
  }
}
