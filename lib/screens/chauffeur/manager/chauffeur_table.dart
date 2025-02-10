import 'package:appwrite/appwrite.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/datasources/conducteurs/conducteur_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:pdf/widgets.dart' show PageOrientation;
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../excel_generation/generate_list_excel.dart';
import '../../../pdf_generation/pdf_preview_listing.dart';
import '../../../theme.dart';
import '../../../widgets/zone_box.dart';
import '../../data_table_parcoto.dart';

class ChauffeurTable extends StatefulWidget {
  final bool selectD;
  final bool archive;

  const ChauffeurTable({super.key, this.selectD = false, this.archive = false});

  @override
  State<ChauffeurTable> createState() => ChauffeurTableState();
}

class ChauffeurTableState extends State<ChauffeurTable> {
  late ConducteurDataSource conducteurDataSource;

  late final bool startedWithFiltersOn;

  static ValueNotifier<String?> filterDocument = ValueNotifier(null);

  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    if (filterDocument.value != null) {
      startedWithFiltersOn = true;
      searchController.text = filterDocument.value!;
      conducteurDataSource = ConducteurDataSource(
          current: context,
          selectC: widget.selectD,
          collectionID: chauffeurid,
          searchKey: filterDocument.value);
      filterDocument.value = null;
    } else {
      startedWithFiltersOn = false;

      conducteurDataSource = ConducteurDataSource(
          current: context,
          collectionID: chauffeurid,
          selectC: widget.selectD,
          archive: widget.archive);
    }
    initColumns();
    super.initState();
  }

  int sortColumn = 4;

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

          conducteurDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'email',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          conducteurDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'telephone',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          conducteurDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'disponibilite',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          conducteurDataSource.sort(6, assending);
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
          sortColumn = 4;
          assending = !assending;
          conducteurDataSource.sort(5, assending);
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
  FlyoutController filterFlyout = FlyoutController();
  FlyoutController export = FlyoutController();
  TextEditingController ageMin = TextEditingController();
  TextEditingController ageMax = TextEditingController();
  Map<String, String> filters = {};

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    conducteurDataSource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
          if (!startedWithFiltersOn && v != null && filterNow) {
            searchController.text = v;
            conducteurDataSource.search(v);
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
                                        child: StatefulBuilder(
                                            builder: (context, setS) {
                                          return SizedBox(
                                            width: 30.w,
                                            height: 42.h,
                                            child: Column(
                                              children: [
                                                Flexible(
                                                  child: ZoneBox(
                                                    label: 'age'.tr(),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10.0),
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
                                                                child: TextBox(
                                                                  controller:
                                                                      ageMin,
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly
                                                                  ],
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
                                                                child: TextBox(
                                                                  controller:
                                                                      ageMax,
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly
                                                                  ],
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
                                                smallSpace,
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      FilledButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                          WidgetStatePropertyAll<
                                                                      Color>(
                                                                  appTheme.color
                                                                      .lightest),
                                                        ),
                                                        onPressed: filtered
                                                            ? () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                setState(() {
                                                                  ageMax
                                                                      .clear();
                                                                  ageMin
                                                                      .clear();
                                                                  filtered =
                                                                      false;
                                                                  filters
                                                                      .clear();
                                                                });
                                                                conducteurDataSource
                                                                    .filter(
                                                                        filters);
                                                              }
                                                            : null,
                                                        child:
                                                            const Text('clear')
                                                                .tr(),
                                                      ),
                                                      const Spacer(),
                                                      Button(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                                  'annuler')
                                                              .tr()),
                                                      smallSpace,
                                                      smallSpace,
                                                      FilledButton(
                                                          style: ButtonStyle(
                                                            backgroundColor:
                                                            WidgetStatePropertyAll<
                                                                        Color>(
                                                                    appTheme
                                                                        .color
                                                                        .lighter),
                                                          ),
                                                          child: const Text(
                                                                  'confirmer')
                                                              .tr(),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();

                                                            if (ageMin.text
                                                                .isNotEmpty) {
                                                              filters['agemin'] =
                                                                  ageMin.text;
                                                            } else {
                                                              filters.remove(
                                                                  'agemin');
                                                            }
                                                            if (ageMax.text
                                                                .isNotEmpty) {
                                                              filters['ageMax'] =
                                                                  ageMax.text;
                                                            } else {
                                                              filters.remove(
                                                                  'ageMax');
                                                            }

                                                            filtered = true;
                                                            setState(() {});
                                                            conducteurDataSource
                                                                .filter(
                                                                    filters);
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
                  smallSpace,
                  FlyoutTarget(
                    controller: export,
                    child: SizedBox(
                      height: 45.px,
                      width: 80.px,
                      child: Button(onPressed: (){
                        export.showFlyout(
                            builder: (context){
                              return MenuFlyout(
                                items: [
                                  MenuFlyoutItem(
                                      text: const Text('PDF'), onPressed: showPdf),
                                  MenuFlyoutItem(
                                      text: const Text('EXCEL'), onPressed:
                                  saveExcell),
                                ],
                              );
                            });
                      }, child: const Text
                        ('export').tr
                        ()),
                    ),
                  ),
                  smallSpace,
                  SizedBox(
                    width: 350.px,
                    height: 45.px,
                    child: TextBox(
                      onChanged: (s){
                        if(s.isEmpty){
                          notEmpty=false;
                          conducteurDataSource.search('');
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
                      decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          conducteurDataSource.search(s);
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
                                conducteurDataSource.search('');
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
            source: conducteurDataSource,
          );
        });
  }


  void showPdf() {
    DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: chauffeurid,queries: [
      Query.limit(DatabaseGetter.limits['vehicles']??500)
    ]).then((value){
        Future.delayed(const Duration(milliseconds: 50))
            .then((s) {
              if(mounted){
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return PdfPreviewListing(
                  firstPageLimit: 30,
                  midPagesLimit: 35,
                  list: conducteurDataSource.getJsonData(
                      value.documents),
                  orientation: PageOrientation.landscape,
                  keysToInclude: const [
                    'matricule',
                    'name',
                    'prenom',
                    'filliale',
                    'd'
                        'irection',
                    'vehicules'
                  ],
                  name: 'Liste des conducteurs',
                );
              });
              }}
        );
    });

  }


  void saveExcell(){
    DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: chauffeurid,queries: [
      Query.limit(DatabaseGetter.limits['vehicles']??500),
      Query.notEqual('etat', 3),
    ]).then((value){

      List2Excel(
        list: conducteurDataSource.getJsonData(value.documents),
        keysToInclude: const ['matricule','nom','prenom','filliale','direction','etat','vehicules'],
        title: 'Liste des conducteurs',
      )
          .getExcel();
    });
  }
  @override
  void dispose() {
    conducteurDataSource.dispose();
    super.dispose();
  }
}
