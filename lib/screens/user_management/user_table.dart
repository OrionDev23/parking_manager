import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/user_management/user_datasource.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';
import '../data_table_parcoto.dart';

class UsersTable extends StatefulWidget {
  final bool selectD;
  final bool archive;

  const UsersTable({super.key, this.selectD = false, this.archive = false});

  @override
  State<UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<UsersTable> {
  late UsersManagementDatasource userDataSource;

  late final bool startedWithFiltersOn;

  static ValueNotifier<String?> filterDocument = ValueNotifier(null);

  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = true;
  int sortColumn = 0;
  late List<DataColumn2> columns;

  int rowPerPage = 12;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;

  @override
  void initState() {
    if (filterDocument.value != null) {
      startedWithFiltersOn = true;
      searchController.text = filterDocument.value!;
      userDataSource = UsersManagementDatasource(
          current: context,
          selectC: widget.selectD,
          searchKey: filterDocument.value);
      filterDocument.value = null;
    } else {
      startedWithFiltersOn = false;

      userDataSource = UsersManagementDatasource(
          current: context, selectC: widget.selectD, archive: widget.archive);
    }
    initColumns();
    super.initState();
  }

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'nom',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          userDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'email',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          userDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'ID',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          userDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'role',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          userDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'dateajout',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;
          userDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: const Text(''),
        size: ColumnSize.S,
        fixedWidth: 2.w,
        onSort: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    userDataSource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
          if (!startedWithFiltersOn && v != null && filterNow) {
            searchController.text = v;
            userDataSource.search(v);
            notEmpty = true;
            filtered = true;
            filterNow = false;
          }
          return DataTableParc(
            header: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 30.w,
                    height: 7.h,
                    child: TextBox(
                      controller: searchController,
                      placeholder: 'search'.tr(),
                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: BoxDecoration(color: appTheme.fillColor),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          userDataSource.search(s);
                          if (!notEmpty) {
                            setState(() {
                              notEmpty = true;
                            });
                          }
                        } else {
                          if (notEmpty) {
                            setState(() {
                              notEmpty = false;
                            });
                          }
                        }
                      },
                      suffix: notEmpty
                          ? IconButton(
                              icon: const Icon(FluentIcons.cancel),
                              onPressed: () {
                                searchController.text = "";
                                notEmpty = false;
                                setState(() {});
                                userDataSource.search('');
                              })
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            sortAscending: assending,
            sortColumnIndex: sortColumn,
            columns: columns,
            source: userDataSource,
            hidePaginator: false,
          );
        });
  }
}
