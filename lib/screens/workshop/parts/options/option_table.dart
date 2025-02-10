import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/workshop/option/option_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../data_table_parcoto.dart';


class OptionTable extends StatefulWidget {
  final bool selectD;

  const OptionTable(
      {super.key, this.selectD = false,});

  @override
  State<OptionTable> createState() => OptionTableState();
}

class OptionTableState extends State<OptionTable> {
  late OptionDatasource optionDataSource;

  late final bool startedWithFiltersOn;

  static ValueNotifier<String?> filterDocument = ValueNotifier(null);

  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = false;

  late List<DataColumn2> columns;

  bool initialized = false;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  String getCollectionID() {
    return optionsID;
  }

  void initValues() {
    if (!initialized) {
      initialized = true;
      if (filterDocument.value != null) {
        startedWithFiltersOn = true;
        searchController.text = filterDocument.value!;
        optionDataSource = OptionDatasource(
            current: context,
            selectC: widget.selectD,
            collectionID: getCollectionID(),
            searchKey: filterDocument.value);
        filterDocument.value = null;
      } else {
        startedWithFiltersOn = false;

        optionDataSource = OptionDatasource(
            current: context,
            collectionID: getCollectionID(),
            selectC: widget.selectD,);
      }
      initColumns();
    }
  }

  int sortColumn = 3;

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'code',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.S,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          optionDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'name',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.S,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          optionDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'values',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          optionDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;
          optionDataSource.sort(sortColumn, assending);
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

  int rowPerPage = 6;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    optionDataSource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
          if (!startedWithFiltersOn && v != null && filterNow) {
            searchController.text = v;
            optionDataSource.search(v);
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
                    width: 350.px,
                    height: 45.px,
                    child: TextBox(
                      onChanged: (s) {
                        if (s.isEmpty) {
                          notEmpty = false;
                          optionDataSource.search('');
                        } else {
                          notEmpty = true;
                        }
                        setState(() {});
                      },
                      controller: searchController,
                      placeholder: 'search'.tr(),
                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          optionDataSource.search(s);
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
                            optionDataSource.search('');
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
            source: optionDataSource,
          );
        });
  }

  @override
  void dispose() {
    optionDataSource.dispose();
    super.dispose();
  }
}
