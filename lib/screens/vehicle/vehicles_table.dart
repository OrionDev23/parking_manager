import 'package:auto_size_text/auto_size_text.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../datasources/vehicle/vehicules_datasource.dart';
import '../../theme.dart';
import '../../utilities/vehicle_util.dart';
import '../../widgets/select_dialog/select_dialog.dart';
import '../../widgets/zone_box.dart';

class VehicleTable extends StatefulWidget {
  final bool selectV;
  const VehicleTable({super.key,this.selectV=false});

  @override
  State<VehicleTable> createState() => VehicleTableState();
}

class VehicleTableState extends State<VehicleTable> {
  late VehiculesDataSource vehicleDataSource;
  late final  bool startedWithFiltersOn;

  bool assending = false;

  late List<DataColumn2> columns;

  static ValueNotifier<int?> filterMarque=ValueNotifier(null);
  static ValueNotifier<String?> filterVehicule=ValueNotifier(null);

  @override
  void initState() {
    if(filterMarque.value!=null || filterVehicule.value!=null){
      startedWithFiltersOn=true;
      if(filterMarque.value!=null){
        marque=filterMarque.value;
        filtered=true;
        filters['marque']=filterMarque.value.toString();
        vehicleDataSource = VehiculesDataSource(current: context,selectV:widget.selectV,filters: filters);

      }
      else {
        searchController.text=filterVehicule.value!;
        vehicleDataSource = VehiculesDataSource(current: context,selectV:widget.selectV,searchKey: filterVehicule.value);
      }
      filterMarque.value=null;
      filterVehicule.value=null;

    }
    else{
      startedWithFiltersOn=false;
      vehicleDataSource = VehiculesDataSource(current: context,selectV:widget.selectV,);
    }
    initColumns();
    super.initState();
  }

  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  int sortColumn = 3;

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'nummat',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
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
            'type',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
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
            'year',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
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
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;
          vehicleDataSource.sort(sortColumn, assending);
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
  int? marque;
  int? genre;
  TextEditingController yearMin=TextEditingController();
  TextEditingController yearMax=TextEditingController();
  Map<String,String> filters={};

  static bool filterNow=false;

  bool filteredAlready=false;
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    vehicleDataSource.appTheme=appTheme;
    return ValueListenableBuilder(
      valueListenable: filterMarque,
      builder: (context,v,_) {
        if(!startedWithFiltersOn && v!=null && filterNow){
          marque=v;
          filters['marque']=v.toString();
          filtered=true;
          vehicleDataSource.filter(filters);
          filterNow=false;
        }
        return ValueListenableBuilder(
            valueListenable: filterVehicule,
            builder: (context,v,_) {
              if(!startedWithFiltersOn && v!=null && filterNow){
                searchController.text=v;
                vehicleDataSource.search(v);
                filtered=true;
                filterNow=false;

              }
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
                                  Text('filter',style: TextStyle(fontSize: 12.sp),).tr(),
                                  const SizedBox(width: 5,),
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
                                          height: 45.h,
                                          child: Column(
                                            children: [
                                              Flexible(
                                                child: ZoneBox(
                                                  label: 'year'.tr(),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Row(
                                                      children: [
                                                        const Text('min').tr(),
                                                        smallSpace,
                                                        Flexible(
                                                          child: TextBox(
                                                            controller: yearMin,
                                                            placeholder: 'min'.tr(),
                                                            placeholderStyle:
                                                                placeStyle,
                                                            style:
                                                                appTheme.writingStyle,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  appTheme.fillColor,
                                                            ),
                                                            cursorColor:
                                                                appTheme.color.darker,
                                                          ),
                                                        ),
                                                        smallSpace,
                                                        const Text('max').tr(),
                                                        smallSpace,
                                                        Flexible(
                                                          child: TextBox(
                                                            controller: yearMax,
                                                            placeholder: 'max'.tr(),
                                                            placeholderStyle:
                                                                placeStyle,
                                                            style:
                                                                appTheme.writingStyle,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  appTheme.fillColor,
                                                            ),
                                                            cursorColor:
                                                                appTheme.color.darker,
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
                                                  label:'marque'.tr(),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          child: ListTile(
                                                            leading: Image.asset(
                                                              'assets/images/marques/${marque ?? 'default'}.webp',
                                                              width: 4.h,
                                                              height: 4.h,
                                                            ),
                                                            title: AutoSizeText(
                                                              VehiclesUtilities
                                                                          .marques![
                                                                      marque ?? 0] ??
                                                                  'nonind'.tr(),
                                                              minFontSize: 5,
                                                              maxLines: 1,
                                                            ),
                                                            onPressed: () {
                                                              SelectDialog.showModal<
                                                                  int?>(
                                                                context,
                                                                selectedValue: marque,
                                                                backgroundColor: appTheme
                                                                    .backGroundColor,
                                                                gridView: true,
                                                                numberOfGridCross: 3,
                                                                constraints:
                                                                    BoxConstraints
                                                                        .loose(Size(
                                                                            60.w,
                                                                            70.h)),
                                                                items: VehiclesUtilities
                                                                    .marques!.keys
                                                                    .toList(),
                                                                itemBuilder: (c, v, e) {
                                                                  return Card(
                                                                      child: Image.asset(
                                                                          'assets/images/marques/${v ?? 'default'}.webp'));
                                                                },
                                                                onChange: (s) {
                                                                  marque = s;
                                                                  setState(() {});
                                                                  setS(() {});
                                                                },
                                                                onFind:
                                                                    VehiclesUtilities
                                                                        .findMarque,
                                                                emptyBuilder: (s) {
                                                                  return Center(
                                                                    child: Text(
                                                                      'lvide',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                                  .grey[
                                                                              100]),
                                                                    ).tr(),
                                                                  );
                                                                },
                                                                loadingBuilder: (s) {
                                                                  return Center(
                                                                    child: Text(
                                                                            'telechargement',
                                                                            style: TextStyle(
                                                                                color: Colors
                                                                                    .grey[100]))
                                                                        .tr(),
                                                                  );
                                                                },
                                                                searchBoxDecoration:
                                                                    appTheme
                                                                        .inputDecoration
                                                                        .copyWith(
                                                                  labelText:
                                                                      'search'.tr(),
                                                                  labelStyle:
                                                                      placeStyle,
                                                                ),
                                                                searchTextStyle:
                                                                    appTheme
                                                                        .writingStyle,
                                                                searchCursorColor:
                                                                    appTheme.color,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        smallSpace,
                                                        smallSpace,
                                                        if (marque != null)
                                                          IconButton(
                                                              icon: Icon(
                                                                FluentIcons.cancel,
                                                                color: appTheme.color,
                                                              ),
                                                              onPressed: () {
                                                                marque = null;

                                                                setState(() {});
                                                                setS(() {});
                                                              })
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: ZoneBox(
                                                  label:'genre'.tr(),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          child: ListTile(
                                                            title: AutoSizeText(
                                                              (VehiclesUtilities
                                                                              .genres![
                                                                          genre ??
                                                                              -1] ??
                                                                      'nonind')
                                                                  .tr(),
                                                              minFontSize: 5,
                                                              softWrap: true,
                                                              maxLines: 1,
                                                            ),
                                                            onPressed: () {
                                                              SelectDialog.showModal<
                                                                  int>(
                                                                context,
                                                                selectedValue: genre,
                                                                items: VehiclesUtilities
                                                                    .genres!.keys
                                                                    .toList(),
                                                                backgroundColor: appTheme.backGroundColor,
                                                                itemBuilder: (c, v, e) {
                                                                  return Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(5.0),
                                                                    color: v % 2 == 0
                                                                        ? Colors
                                                                            .transparent
                                                                        : appTheme.color
                                                                            .lightest,
                                                                    child: Row(
                                                                      children: [
                                                                        Text(v
                                                                            .toString()),
                                                                        smallSpace,
                                                                        smallSpace,
                                                                        smallSpace,
                                                                        Text(VehiclesUtilities
                                                                                    .genres?[v] ??
                                                                                '')
                                                                            .tr(),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                                onChange: (s) {
                                                                  genre = s;
                                                                  setState(() {});
                                                                  setS(() {});
                                                                },
                                                                onFind:
                                                                    VehiclesUtilities
                                                                        .findGenres,
                                                                emptyBuilder: (s) {
                                                                  return Center(
                                                                    child: Text(
                                                                      'lvide',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                                  .grey[
                                                                              100]),
                                                                    ).tr(),
                                                                  );
                                                                },
                                                                loadingBuilder: (s) {
                                                                  return Center(
                                                                    child: Text(
                                                                            'telechargement',
                                                                            style: TextStyle(
                                                                                color: Colors
                                                                                    .grey[100]))
                                                                        .tr(),
                                                                  );
                                                                },
                                                                searchBoxDecoration:
                                                                    appTheme
                                                                        .inputDecoration
                                                                        .copyWith(
                                                                  labelText:
                                                                      'search'.tr(),
                                                                  labelStyle:
                                                                      placeStyle,
                                                                ),
                                                                searchTextStyle:
                                                                    appTheme
                                                                        .writingStyle,
                                                                searchCursorColor:
                                                                    appTheme.color,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        smallSpace,
                                                        smallSpace,
                                                        if (genre != null)
                                                          IconButton(
                                                              icon: Icon(
                                                                FluentIcons.cancel,
                                                                color: appTheme.color,
                                                              ),
                                                              onPressed: () {
                                                                genre = null;
                                                                setState(() {});
                                                                setS(() {});
                                                              })
                                                      ],
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
                                                      style:ButtonStyle(
                                                        backgroundColor: ButtonState.all<Color>(
                                                            appTheme.color.lightest
                                                        ),
                                                      ),
                                                      onPressed: filtered?(){

                                                        Navigator.of(context).pop();
                                                        setState(() {
                                                          filtered=false;
                                                          filters.clear();
                                                        });
                                                        vehicleDataSource.filter(filters);

                                                      }
                                                          :null,child: const Text('clear').tr(),
                                                    ),
                                                    const Spacer(),
                                                    Button(
                                                        onPressed:(){
                                                      Navigator.of(context).pop();
                                                    },
                                                        child: const Text('annuler').tr()),
                                                    smallSpace,


                                                    smallSpace,

                                                    FilledButton(
                                                        style:ButtonStyle(
                                                          backgroundColor: ButtonState.all<Color>(
                                                              appTheme.color.lighter
                                                          ),
                                                        ),
                                                        child: const Text('confirmer').tr(),
                                                        onPressed: (){
                                                          Navigator.of(context).pop();

                                                          if(yearMin.text.isNotEmpty){
                                                              filters['yearmin']=yearMin.text;
                                                            }
                                                            else{
                                                              filters.remove('yearmin');
                                                            }
                                                            if(yearMax.text.isNotEmpty){
                                                              filters['yearmax']=yearMax.text;
                                                            }
                                                            else{
                                                              filters.remove('yearmax');
                                                            }
                                                            if(genre!=null){
                                                              filters['genre']=genre.toString();
                                                            }
                                                            else{
                                                              filters.remove('genre');
                                                            }
                                                            if(marque!=null){
                                                              filters['marque']=marque.toString();
                                                            }
                                                            else{
                                                              filters.remove('marque');
                                                            }

                                                            filtered=true;
                                                            setState((){});
                                                            vehicleDataSource.filter(filters);

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
                  width: 30.w,
                  height: 7.h,
                  child: TextBox(
                    controller: searchController,
                    placeholder: 'search'.tr(),
                    style: appTheme.writingStyle,
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                    decoration: BoxDecoration(
                        color: appTheme.fillColor
                    ),
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
                              vehicleDataSource.search('');
                            })
                        : null,
                  ),
                ),
              ],
            ),
          ),
          sortAscending: assending,
          horizontalMargin: 8,
          columnSpacing: 0,
          dataRowHeight: 3.5.h,
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
          source: vehicleDataSource,
          sortArrowAlwaysVisible: true,
          hidePaginator: false,
        );
      });}
    );
  }

  @override
  void dispose() {
    filterMarque.value=null;
    filterVehicule.value=null;
    vehicleDataSource.dispose();
    super.dispose();
  }
}
