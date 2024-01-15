import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:parc_oto/datasources/vehicle_states/vehicle_states_datasrouce.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/vehicle/states/state_form.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';
import '../../../widgets/empty_table_widget.dart';
import '../../../widgets/zone_box.dart';
import '../manager/vehicles_table.dart';

class StateTable extends StatefulWidget {
  final bool selectD;
  const StateTable({super.key, this.selectD = false});

  @override
  State<StateTable> createState() => StateTableState();
}

class StateTableState extends State<StateTable> {
  late VStatesDatasource vehicleStateDatasource;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    vehicleStateDatasource = VStatesDatasource(
        current: context, collectionID: etatId, selectC: widget.selectD);
    initColumns();
    super.initState();
  }

  int sortColumn = 5;

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'vehicule',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          vehicleStateDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'etat',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          vehicleStateDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'date',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          vehicleStateDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'notes',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          vehicleStateDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'reparation',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;

          vehicleStateDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 5;
          assending = !assending;
          vehicleStateDatasource.sort(sortColumn, assending);
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

  int rowPerPage = 12;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  bool filtered = false;

  FlyoutController filterFlyout = FlyoutController();
  Vehicle? selectedVehicle;
  DateTime? dateMin;
  DateTime? dateMax;

  int? type;

  Map<String, String> filters = {};
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    vehicleStateDatasource.appTheme = appTheme;
    return AsyncPaginatedDataTable2(
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 75.px,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlyoutTarget(
                      controller: filterFlyout,
                      child: IconButton(
                          icon: Row(
                            children: [
                              Text(
                                'filter',
                                style: TextStyle(fontSize: 12.sp),
                              ).tr(),
                              const SizedBox(
                                width: 5,
                              ),
                              filtered
                                  ? Icon(
                                      FluentIcons.filter_solid,
                                      color: appTheme.color,
                                    )
                                  : const Icon(FluentIcons.filter),
                            ],
                          ),
                          onPressed: () {
                            filterFlyout.showFlyout(builder: (context) {
                              return FlyoutContent(
                                  color: appTheme.backGroundColor,
                                  child: filterBuilder(appTheme));
                            });
                          }),
                    ),
                  ),
                  if (filtered)
                    Positioned(
                        bottom: 10,
                        right: 0,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 4),
                            decoration: BoxDecoration(
                              color: appTheme.color,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: kElevationToShadow[2],
                            ),
                            child: Text(
                              '${filters.length}',
                              style: TextStyle(fontSize: 10.sp),
                            ))),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
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
                    vehicleStateDatasource.search(s);
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
                          vehicleStateDatasource.search('');
                        })
                    : null,
              ),
            ),
          ],
        ),
      ),
      sortAscending: assending,
      headingRowHeight: 25,
      headingRowDecoration: BoxDecoration(
          color: appTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5))
      ),
      dividerThickness: 0.5,
      autoRowsToHeight: true,

      empty: NoDataWidget(
        datasource: vehicleStateDatasource,
      ),
      horizontalMargin: 8,
      columnSpacing: 0,
      dataRowHeight: rowHeight,
      onPageChanged: (s) {},
      showCheckboxColumn: false,
      sortColumnIndex: sortColumn,
      rowsPerPage: rowPerPage,
      onRowsPerPageChanged: (nbr) {
        rowPerPage = nbr ?? 12;
      },
      availableRowsPerPage: const [12, 24, 50, 100, 200],
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: false,
      fit: FlexFit.tight,
      columns: columns,
      source: vehicleStateDatasource,
      sortArrowAlwaysVisible: true,
      hidePaginator: false,
    );
  }

  Widget filterBuilder(AppTheme appTheme) {
    return StatefulBuilder(builder: (context, setS) {
      return SizedBox(
        width: 30.w,
        height: 49.h,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
              leading: Row(
                children: [
                  Icon(FluentIcons.category_classification,
                      color: appTheme.color.lightest),
                  bigSpace,
                  Text('chstates',
                          style:
                              placeStyle.copyWith(fontWeight: FontWeight.bold))
                      .tr(),
                ],
              ),
              title: ComboBox<int>(
                items: types
                    .map((e) => ComboBoxItem<int>(
                          value: types.indexOf(e),
                          child: Text(e).tr(),
                        ))
                    .toList(),
                value: type,
                onChanged: (s) {
                  setState(() {
                    type = s ?? 0;
                  });
                  setS(() {});
                },
              ),
              trailing: type != null
                  ? IconButton(
                      icon: const Icon(FluentIcons.cancel),
                      onPressed: () {
                        setState(() {
                          type = null;
                        });
                        setS(() {});
                      })
                  : null,
            ),
            smallSpace,
            Flexible(
              child: ZoneBox(
                label: 'dateexp'.tr(),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 5.w, child: const Text('min').tr()),
                          smallSpace,
                          smallSpace,
                          Flexible(
                            child: DatePicker(
                              selected: dateMin,
                              endDate: dateMax,
                              onChanged: (d) {
                                dateMin = d;
                                setState(() {});
                                setS(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      smallSpace,
                      Row(
                        children: [
                          SizedBox(width: 5.w, child: const Text('max').tr()),
                          smallSpace,
                          smallSpace,
                          Flexible(
                            child: DatePicker(
                              selected: dateMax,
                              startDate: dateMin,
                              onChanged: (d) {
                                dateMax = d;
                                setState(() {});
                                setS(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            smallSpace,
            Flexible(
              child: ZoneBox(
                label: 'vehicule'.tr(),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListTile(
                    title: Text(selectedVehicle?.matricule ?? '/'),
                    onPressed: () async {
                      selectedVehicle = await showDialog<Vehicle>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return ContentDialog(
                              constraints:
                                  BoxConstraints.tight(Size(60.w, 60.h)),
                              title: const Text('selectvehicle').tr(),
                              style: ContentDialogThemeData(
                                  titleStyle: appTheme.writingStyle
                                      .copyWith(fontWeight: FontWeight.bold)),
                              content: Container(
                                  color: appTheme.backGroundColor,
                                  width: 60.w,
                                  height: 60.h,
                                  child: const VehicleTable(
                                    selectV: true,
                                  )),
                            );
                          });
                      setState(() {});
                      setS(() {});
                    },
                  ),
                ),
              ),
            ),
            smallSpace,
            smallSpace,
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor:
                          ButtonState.all<Color>(appTheme.color.lightest),
                    ),
                    onPressed: filtered
                        ? () {
                      Navigator.of(context).pop();
                            setState(() {
                              type = null;
                              dateMax = null;
                              dateMin = null;
                              selectedVehicle = null;
                              filtered = false;
                              filters.clear();
                            });
                            vehicleStateDatasource.filter(filters);
                          }
                        : null,
                    child: const Text('clear').tr(),
                  ),
                  const Spacer(),
                  Button(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('annuler').tr()),
                  smallSpace,
                  smallSpace,
                  FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            ButtonState.all<Color>(appTheme.color.lighter),
                      ),
                      child: const Text('confirmer').tr(),
                      onPressed: () {
                        Navigator.of(context).pop();

                        if (type != null) {
                          filters['type'] = type.toString();
                        }

                        if (dateMin != null) {
                          filters['datemin'] = dateMin!
                              .difference(ClientDatabase.ref)
                              .inMilliseconds
                              .toString();
                        } else {
                          filters.remove('datemin');
                        }
                        if (dateMax != null) {
                          filters['datemax'] = dateMax!
                              .difference(ClientDatabase.ref)
                              .inMilliseconds
                              .toString();
                        } else {
                          filters.remove('datemax');
                        }
                        if (selectedVehicle != null) {
                          filters['vehicle'] = selectedVehicle!.id;
                        } else {
                          filters.remove('vehicle');
                        }

                        filtered = true;
                        setState(() {});
                        vehicleStateDatasource.filter(filters);
                      }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    vehicleStateDatasource.dispose();
    super.dispose();
  }
}
