import 'package:auto_size_text/auto_size_text.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/admin_parameters.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:pdf/widgets.dart' show PageOrientation;
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../datasources/vehicle/vehicules_datasource.dart';
import '../../../excel_generation/generate_list_excel.dart';
import '../../../pdf_generation/pdf_preview_listing.dart';
import '../../../theme.dart';
import '../../../utilities/vehicle_util.dart';
import '../../../widgets/select_dialog/select_dialog.dart';
import '../../../widgets/zone_box.dart';
import '../../data_table_parcoto.dart';

class VehicleTable extends StatefulWidget {
  final bool selectV;

  const VehicleTable({super.key, this.selectV = false});

  @override
  State<VehicleTable> createState() => VehicleTableState();
}

class VehicleTableState extends State<VehicleTable> {
  late VehiculeDataSource vehicleDataSource;
  late final bool startedWithFiltersOn;

  static ValueNotifier<int?> filterMarque = ValueNotifier(null);
  static ValueNotifier<String?> filterVehicule = ValueNotifier(null);

  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    if (filterMarque.value == null && filterVehicule.value == null)
    {
      startedWithFiltersOn = false;
      vehicleDataSource = VehiculeDataSource(
        current: context,
        selectC: widget.selectV,
        collectionID: vehiculeid,
      );
    }
    else {
      startedWithFiltersOn = true;
      if (filterMarque.value != null) {
        marque = filterMarque.value;
        filtered = true;
        filters['marque'] = filterMarque.value.toString();
        vehicleDataSource = VehiculeDataSource(
            current: context,
            selectC: widget.selectV,
            collectionID: vehiculeid,
            filters: filters);
      } else {
        searchController.text = filterVehicule.value!;
        vehicleDataSource = VehiculeDataSource(
            current: context,
            selectC: widget.selectV,
            collectionID: vehiculeid,
            searchKey: filterVehicule.value);
      }
      filterMarque.value = null;
      filterVehicule.value = null;
    }
    initColumns();
    sortColumn=columns.length-1;

    super.initState();
  }

  int sortColumn = conducteurEmploye?11:6;

  double large=250.px;
  double medium=150.px;
  double small=80.px;

  void initColumns() {
    if(conducteurEmploye){
      initColumnsEmploye();}
    else{
      initColumnsNonEmploye();
    }
  }

  void initColumnsNonEmploye(){
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'N',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'nchassi',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'matricule',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'type',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: large,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'etat',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'perimetre',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 5;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: large,
        onSort: (s, c) {
          sortColumn = 6;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      if (widget.selectV != true)
        DataColumn2(
          label: const Text(''),
          size: ColumnSize.M,
          fixedWidth: medium,
          onSort: null,
        ),
    ];
  }
  void initColumnsEmploye(){
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'N',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'matricule',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'type',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: large,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'etat',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'perimetre',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'appartenancevehiculesingle',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 5;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'direction',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: large,
        onSort: (s, c) {
          sortColumn = 6;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'matriculeemploye',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 7;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'nom',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 8;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'prenom',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: small,
        onSort: (s, c) {
          sortColumn = 9;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'poste',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 10;
          assending = !assending;

          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        numeric: true,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: large,
        onSort: (s, c) {
          sortColumn = 11;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      if (widget.selectV != true)
        DataColumn2(
          label: const Text(''),
          size: ColumnSize.M,
          fixedWidth: medium,
          onSort: null,
        ),
    ];
  }

  final rowPerPageC = 12;
  int rowPerPage = 12;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;

  FlyoutController filterFlyout = FlyoutController();
  int? marque;
  int? genre;
  TextEditingController yearMin = TextEditingController();
  TextEditingController yearMax = TextEditingController();
  Map<String, String> filters = {};




  FlyoutController export = FlyoutController();


  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    vehicleDataSource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterMarque,
        builder: (context, v, _) {
          if (!startedWithFiltersOn &&  filterNow && v != null) {
            marque = v;
            filters['marque'] = v.toString();
            filtered = true;
            vehicleDataSource.filter(filters);
            filterNow = false;
          }
          return ValueListenableBuilder(
              valueListenable: filterVehicule,
              builder: (context, v, _) {
                if (!startedWithFiltersOn &&  filterNow && v != null ) {
                  searchController.text = v;
                  vehicleDataSource.search(v);
                  notEmpty = true;
                  filtered = true;
                  filterNow = false;
                }
                return DataTableParc(
                  horizontalScroll: true,
                  header: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 80.px,
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
                                        showFilters(appTheme);
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
                                          borderRadius:
                                              BorderRadius.circular(5),
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
                                    MenuFlyoutSubItem(
                                        text: const Text('listcomplete').tr(),
                                    items: (BuildContext context) {
                                        return [
                                        MenuFlyoutItem(
                                        text: const Text('PDF'), onPressed: showPdf),
                                    MenuFlyoutItem(
                                    text: const Text('EXCEL'), onPressed:
                                    saveExcell),
                                        ];
                                    }),
                                    MenuFlyoutSubItem(
                                        text: const Text('costpervehic').tr(),
                                        items: (BuildContext context) {
                                          return [
                                            MenuFlyoutItem(
                                                text: const Text('PDF'),
                                                onPressed: showCostPdf),
                                            MenuFlyoutItem(
                                                text: const Text('EXCEL'), onPressed:
                                            saveExcelCost),
                                          ];
                                        }),

                                  ],
                                );
                              });
                            }, child: const Text
                              ('export').tr
                              ()),
                          ),
                        ),
                        smallSpace,
                        Flexible(
                          child: SizedBox(
                            width: 350.px,
                            height: 45.px,
                            child: TextBox(
                              controller: searchController,
                              placeholder: 'search'.tr(),
                              style: appTheme.writingStyle,
                              cursorColor: appTheme.color.darker,
                              placeholderStyle: placeStyle,
                              decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                              onSubmitted: (s) {
                                if (s.isNotEmpty) {
                                  vehicleDataSource.search(s);
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
                                    vehicleDataSource.search('');
                                  }
                                }
                              },
                              onChanged: (s){
                                if(s.isEmpty){
                                  notEmpty=false;
                                  vehicleDataSource.search('');
                                }
                                else{
                                    notEmpty=true;
                                }
                                setState(() {
                                });
                              },
                              suffix: notEmpty
                                  ? IconButton(
                                      icon: const Icon(FluentIcons.cancel),
                                      onPressed: () {
                                        searchController.text = "";
                                        notEmpty = false;
                                        setState(() {});
                                        vehicleDataSource.search('');
                                      })
                                  : null,
                            ),
                          ),
                        ),
                        bigSpace,
                        IconButton(
                            icon: const Icon(FluentIcons.refresh),
                            onPressed: () {
                              vehicleDataSource.refreshDatasource();
                            }),
                      ],
                    ),
                  ),
                  sortAscending: assending,
                  sortColumnIndex: sortColumn,
                  columns: columns,
                  source: vehicleDataSource,
                );
              });
        });
  }


  void showPdf() async{

    if(!VehicleProvider.downloadedVehicles){
      VehicleProvider();
      while(!VehicleProvider.downloadedVehicles){
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    Future.delayed(const Duration(milliseconds: 50)).then((value) {

      if(mounted){
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context){
            return PdfPreviewListing(
              firstPageLimit: 30,
              midPagesLimit: 35,
              list: vehicleDataSource.getJsonData(
                  VehicleProvider.vehicles.entries.toList()),
              orientation: PageOrientation.landscape,
              keysToInclude: conducteurEmploye?const ['matricule','type','apparten'
                  'ance','nom','prenom','direction']:const ['numeroSerie','matricule','type','etatactuel'],
              name: 'Liste des véhicules',
            );
          });}
  });

  }

  void saveExcell() async{

    if(!VehicleProvider.downloadedVehicles){
      VehicleProvider();
      while(!VehicleProvider.downloadedVehicles){
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    Future.delayed(const Duration(milliseconds: 50)).then((value) {
      List2Excel(
              list: vehicleDataSource.getJsonData(VehicleProvider.vehicles
                  .entries.toList()),
              keysToInclude: conducteurEmploye?const ['matricule','type','apparten'
                  'ance','matriculeConducteur','nom','prenom','direction','departement',
                'etatactuel','appartenanceconducteur','service','decision','perimetre','emplacement']:const['numeroSerie','matricule','type','etatactuel','perimetre','emplacement'],
              title: 'Liste des véhicules',
            ).getExcel();
          });
  }

  void showCostPdf() async{
    await RepairProvider.downloadFicheReparations();

    Future.delayed(const Duration(milliseconds: 50)).then((value){
      if(mounted){
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context){
            return PdfPreviewListing(
              firstPageLimit: 30,
              midPagesLimit: 35,
              list: RepairProvider.prepareVehicRepList(RepairProvider
                  .repPerVeh),
              orientation: PageOrientation.landscape,
              keysToInclude: conducteurEmploye?const ['vehicule','modele','mat. conducteur','nom conducteur','nbr. rep','cost','dern. '
            'rep']:const['vehicule','modele','nbr. rep','cost','dern. rep'],
              name: 'Couts par vehicule',
            );
          });}
    });

  }

  void saveExcelCost() async{
    await RepairProvider.downloadFicheReparations();
    Future.delayed(const Duration(milliseconds: 50)).then((value) {
      List2Excel(
        list: RepairProvider.prepareVehicRepList(RepairProvider
            .repPerVeh),
        keysToInclude: conducteurEmploye?const ['vehicule','modele','mat. conducteur','nom conducteur','nbr. rep','cost','dern. '
            'rep']:const['vehicule','modele','nbr. rep','cost','dern. rep'],
        title: 'Couts par vehicule',
      ).getExcel();
    });

  }


  void showFilters(AppTheme appTheme){
    filterFlyout.showFlyout(
        builder: (context) {
          return FlyoutContent(
              color: appTheme.backGroundColor,
              child: StatefulBuilder(
                  builder: (context, setS) {
                    return SizedBox(
                      width: 30.w,
                      height: 45.h,
                      child: Column(
                        children: [
                          Flexible(
                            child: ZoneBox(
                              label: 'year'.tr(),
                              child: Padding(
                                padding:
                                const EdgeInsets
                                    .all(10.0),
                                child: Row(
                                  children: [
                                    const Text(
                                        'min')
                                        .tr(),
                                    smallSpace,
                                    Flexible(
                                      child:
                                      TextBox(
                                        controller:
                                        yearMin,
                                        placeholder:
                                        'min'
                                            .tr(),
                                        placeholderStyle:
                                        placeStyle,
                                        style: appTheme
                                            .writingStyle,
                                        decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                                        cursorColor:
                                        appTheme
                                            .color
                                            .darker,
                                      ),
                                    ),
                                    smallSpace,
                                    const Text(
                                        'max')
                                        .tr(),
                                    smallSpace,
                                    Flexible(
                                      child:
                                      TextBox(
                                        controller:
                                        yearMax,
                                        placeholder:
                                        'max'
                                            .tr(),
                                        placeholderStyle:
                                        placeStyle,
                                        style: appTheme
                                            .writingStyle,
                                        decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                                        cursorColor:
                                        appTheme
                                            .color
                                            .darker,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          smallSpace,
                          Flexible(
                            child: ZoneBox(
                              label: 'marque'.tr(),
                              child: Padding(
                                padding:
                                const EdgeInsets
                                    .all(10.0),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child:
                                      ListTile(
                                        leading: Image
                                            .asset(
                                          'assets/images/marques/${marque ?? 'default'}.webp',
                                          width:
                                          4.h,
                                          height:
                                          4.h,
                                        ),
                                        title:
                                        AutoSizeText(
                                          VehiclesUtilities.marques![marque ??
                                              0] ??
                                              'nonind'
                                                  .tr(),
                                          minFontSize:
                                          5,
                                          maxLines:
                                          1,
                                        ),
                                        onPressed:
                                            () {
                                          SelectDialog
                                              .showModal<
                                              int?>(
                                            context,
                                            selectedValue:
                                            marque,
                                            backgroundColor:
                                            appTheme.backGroundColor,
                                            gridView:
                                            true,
                                            numberOfGridCross:
                                            3,
                                            constraints: BoxConstraints.loose(Size(
                                                60.w,
                                                70.h)),
                                            items: VehiclesUtilities
                                                .marques!
                                                .keys
                                                .toList(),
                                            itemBuilder: (c,
                                                v,
                                                e) {
                                              return Card(
                                                  child: Image.asset('assets/images/marques/${v ?? 'default'}.webp'));
                                            },
                                            onChange:
                                                (s) {
                                              marque =
                                                  s;
                                              setState(
                                                      () {});
                                              setS(
                                                      () {});
                                            },
                                            onFind:
                                            VehiclesUtilities.findMarque,
                                            emptyBuilder:
                                                (s) {
                                              return Center(
                                                child:
                                                Text(
                                                  'lvide',
                                                  style: TextStyle(color: Colors.grey[100]),
                                                ).tr(),
                                              );
                                            },
                                            loadingBuilder:
                                                (s) {
                                              return Center(
                                                child:
                                                Text('telechargement', style: TextStyle(color: Colors.grey[100])).tr(),
                                              );
                                            },
                                            searchBoxDecoration: appTheme
                                                .inputDecoration
                                                .copyWith(
                                              labelText:
                                              'search'.tr(),
                                              labelStyle:
                                              placeStyle,
                                            ),
                                            searchTextStyle:
                                            appTheme.writingStyle,
                                            searchCursorColor:
                                            appTheme.color,
                                          );
                                        },
                                      ),
                                    ),
                                    smallSpace,
                                    smallSpace,
                                    if (marque !=
                                        null)
                                      IconButton(
                                          icon:
                                          Icon(
                                            FluentIcons
                                                .cancel,
                                            color: appTheme
                                                .color,
                                          ),
                                          onPressed:
                                              () {
                                            marque =
                                            null;

                                            setState(
                                                    () {});
                                            setS(
                                                    () {});
                                          })
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: ZoneBox(
                              label: 'genre'.tr(),
                              child: Padding(
                                padding:
                                const EdgeInsets
                                    .all(10.0),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child:
                                      ListTile(
                                        title:
                                        AutoSizeText(
                                          (VehiclesUtilities.genres![genre ?? -1] ??
                                              'nonind')
                                              .tr(),
                                          minFontSize:
                                          5,
                                          softWrap:
                                          true,
                                          maxLines:
                                          1,
                                        ),
                                        onPressed:
                                            () {
                                          SelectDialog
                                              .showModal<
                                              int>(
                                            context,
                                            selectedValue:
                                            genre,
                                            items: VehiclesUtilities
                                                .genres!
                                                .keys
                                                .toList(),
                                            backgroundColor:
                                            appTheme.backGroundColor,
                                            itemBuilder: (c,
                                                v,
                                                e) {
                                              return Container(
                                                padding:
                                                const EdgeInsets.all(5.0),
                                                color: v % 2 == 0
                                                    ? Colors.transparent
                                                    : appTheme.color.lightest,
                                                child:
                                                Row(
                                                  children: [
                                                    Text(v.toString()),
                                                    smallSpace,
                                                    smallSpace,
                                                    smallSpace,
                                                    Text(VehiclesUtilities.genres?[v] ?? '').tr(),
                                                  ],
                                                ),
                                              );
                                            },
                                            onChange:
                                                (s) {
                                              genre =
                                                  s;
                                              setState(
                                                      () {});
                                              setS(
                                                      () {});
                                            },
                                            onFind:
                                            VehiclesUtilities.findGenres,
                                            emptyBuilder:
                                                (s) {
                                              return Center(
                                                child:
                                                Text(
                                                  'lvide',
                                                  style: TextStyle(color: Colors.grey[100]),
                                                ).tr(),
                                              );
                                            },
                                            loadingBuilder:
                                                (s) {
                                              return Center(
                                                child:
                                                Text('telechargement', style: TextStyle(color: Colors.grey[100])).tr(),
                                              );
                                            },
                                            searchBoxDecoration: appTheme
                                                .inputDecoration
                                                .copyWith(
                                              labelText:
                                              'search'.tr(),
                                              labelStyle:
                                              placeStyle,
                                            ),
                                            searchTextStyle:
                                            appTheme.writingStyle,
                                            searchCursorColor:
                                            appTheme.color,
                                          );
                                        },
                                      ),
                                    ),
                                    smallSpace,
                                    smallSpace,
                                    if (genre !=
                                        null)
                                      IconButton(
                                          icon:
                                          Icon(
                                            FluentIcons
                                                .cancel,
                                            color: appTheme
                                                .color,
                                          ),
                                          onPressed:
                                              () {
                                            genre =
                                            null;
                                            setState(
                                                    () {});
                                            setS(
                                                    () {});
                                          })
                                  ],
                                ),
                              ),
                            ),
                          ),
                          smallSpace,
                          smallSpace,
                          Padding(
                            padding:
                            const EdgeInsets
                                .all(8.0),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .end,
                              children: [
                                FilledButton(
                                  style:
                                  ButtonStyle(
                                    backgroundColor:
                                    WidgetStateProperty.all<
                                        Color>(
                                        appTheme
                                            .color
                                            .lightest),
                                  ),
                                  onPressed:
                                  filtered
                                      ? () {
                                    Navigator.of(context)
                                        .pop();
                                    setState(
                                            () {
                                          filtered =
                                          false;
                                          filters.clear();
                                        });
                                    vehicleDataSource
                                        .filter(filters);
                                  }
                                      : null,
                                  child: const Text(
                                      'clear')
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
                                    style:
                                    ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all<
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

                                      if (yearMin
                                          .text
                                          .isNotEmpty) {
                                        filters['yearmin'] =
                                            yearMin
                                                .text;
                                      } else {
                                        filters.remove(
                                            'yearmin');
                                      }
                                      if (yearMax
                                          .text
                                          .isNotEmpty) {
                                        filters['yearmax'] =
                                            yearMax
                                                .text;
                                      } else {
                                        filters.remove(
                                            'yearmax');
                                      }
                                      if (genre !=
                                          null) {
                                        filters['genre'] =
                                            genre
                                                .toString();
                                      } else {
                                        filters.remove(
                                            'genre');
                                      }
                                      if (marque !=
                                          null) {
                                        filters['marque'] =
                                            marque
                                                .toString();
                                      } else {
                                        filters.remove(
                                            'marque');
                                      }

                                      filtered =
                                      true;
                                      setState(
                                              () {});
                                      vehicleDataSource
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
  }

  @override
  void dispose() {
    filterMarque.value = null;
    filterVehicule.value = null;
    vehicleDataSource.dispose();
    super.dispose();
  }
}
