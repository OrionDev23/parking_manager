import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../datasources/vehic_doc/document_datasource.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';
import '../../../widgets/zone_box.dart';
import '../../data_table_parcoto.dart';
import '../manager/vehicles_table.dart';

class DocumentTable extends StatefulWidget {
  final bool selectD;

  const DocumentTable({super.key, this.selectD = false});

  @override
  State<DocumentTable> createState() => DocumentTableState();
}

class DocumentTableState extends State<DocumentTable> {
  late DocumentsDataSource documentsDataSource;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    documentsDataSource = DocumentsDataSource(
        current: context, collectionID: vehicDoc, selectC: widget.selectD);
    initColumns();
    super.initState();
  }

  int sortColumn = 3;

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'nom',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          documentsDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'vehicule',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          documentsDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateexp',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          documentsDataSource.sort(sortColumn, assending);
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
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;
          documentsDataSource.sort(sortColumn, assending);
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
  Map<String, String> filters = {};

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    documentsDataSource.appTheme = appTheme;
    return DataTableParc(
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
                                  child:
                                      StatefulBuilder(builder: (context, setS) {
                                    return SizedBox(
                                      width: 30.w,
                                      height: 42.h,
                                      child: Column(
                                        children: [
                                          Flexible(
                                            child: ZoneBox(
                                              label: 'dateexp'.tr(),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                            width: 5.w,
                                                            child: const Text(
                                                                    'min')
                                                                .tr()),
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
                                                        SizedBox(
                                                            width: 5.w,
                                                            child: const Text(
                                                                    'max')
                                                                .tr()),
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
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: ListTile(
                                                  title: Text(selectedVehicle
                                                          ?.matricule ??
                                                      '/'),
                                                  onPressed: () async {
                                                    selectedVehicle =
                                                    await showDialog<Vehicle>(
                                                        context: context,
                                                        barrierDismissible: true,
                                                        builder: (context) {
                                                          return ContentDialog(
                                                            constraints: BoxConstraints.tight(
                                                                Size(700.px, 550.px)),
                                                            title: const Text('selectvehicle').tr(),
                                                            style: ContentDialogThemeData(
                                                                titleStyle: appTheme.writingStyle
                                                                    .copyWith(
                                                                    fontWeight:
                                                                    FontWeight.bold)),
                                                            content: const VehicleTable(
                                                              selectV: true,
                                                            ),
                                                            actions: [Button(child: const Text('fermer').tr(),
                                                                onPressed: (){
                                                                  Navigator.of(context).pop();
                                                                })],
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                FilledButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        ButtonState.all<Color>(
                                                            appTheme.color
                                                                .lightest),
                                                  ),
                                                  onPressed: filtered
                                                      ? () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            dateMax = null;
                                                            dateMin = null;
                                                            selectedVehicle =
                                                                null;
                                                            filtered = false;
                                                            filters.clear();
                                                          });
                                                          documentsDataSource
                                                              .filter(filters);
                                                        }
                                                      : null,
                                                  child:
                                                      const Text('clear').tr(),
                                                ),
                                                const Spacer(),
                                                Button(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('annuler')
                                                        .tr()),
                                                smallSpace,
                                                smallSpace,
                                                FilledButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          ButtonState.all<
                                                                  Color>(
                                                              appTheme.color
                                                                  .lighter),
                                                    ),
                                                    child:
                                                        const Text('confirmer')
                                                            .tr(),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();

                                                      if (dateMin != null) {
                                                        filters['datemin'] =
                                                            dateMin!
                                                                .difference(
                                                                    ClientDatabase
                                                                        .ref)
                                                                .inMilliseconds
                                                                .toString();
                                                      } else {
                                                        filters
                                                            .remove('datemin');
                                                      }
                                                      if (dateMax != null) {
                                                        filters['datemax'] =
                                                            dateMax!
                                                                .difference(
                                                                    ClientDatabase
                                                                        .ref)
                                                                .inMilliseconds
                                                                .toString();
                                                      } else {
                                                        filters
                                                            .remove('datemax');
                                                      }
                                                      if (selectedVehicle !=
                                                          null) {
                                                        filters['vehicle'] =
                                                            selectedVehicle!.id;
                                                      } else {
                                                        filters
                                                            .remove('vehicle');
                                                      }

                                                      filtered = true;
                                                      setState(() {});
                                                      documentsDataSource
                                                          .filter(filters);
                                                    }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }));
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
              width: 350.px,
              height: 45.px,
              child: TextBox(
                onChanged: (s){
                  if(s.isEmpty){
                    notEmpty=false;
                    documentsDataSource.search('');
                  }
                  else{
                    notEmpty=true;
                  }
                  setState(() {
                  });
                },
                controller: searchController,
                placeholder: 'search'.tr(),
                style: appTheme.writingStyle,
                cursorColor: appTheme.color.darker,
                placeholderStyle: placeStyle,
                decoration: BoxDecoration(color: appTheme.fillColor),
                onSubmitted: (s) {
                  if (s.isNotEmpty) {
                    documentsDataSource.search(s);
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
                          documentsDataSource.search('');
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
      source: documentsDataSource,
      hidePaginator: false,
    );
  }

  @override
  void dispose() {
    documentsDataSource.dispose();
    super.dispose();
  }
}
