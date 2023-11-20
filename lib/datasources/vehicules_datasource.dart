import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/vehicle_webservice.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../providers/client_database.dart';
import '../screens/vehicle/manager/vehicle_form.dart';
import '../screens/vehicle/manager/vehicle_tabs.dart';
import '../serializables/vehicle.dart';

class VehiculesDataSource extends AsyncDataTableSource {

  BuildContext current;
  VehiculesDataSource({required this.current});

  VehiculesDataSource.empty({required this.current}) {
    _empty = true;
  }

  VehiculesDataSource.error({required this.current}) {
    _errorCounter = 0;
  }

  bool _empty = false;
  int? _errorCounter;

  final VehiculesWebService _repo = VehiculesWebService();

  int _sortColumn = 0;
  bool _sortAscending = true;

  void sort(int column, bool ascending) {
    _sortColumn = column;
    _sortAscending = ascending;
    refreshDatasource();
  }

  String? searchKey;

  void search(String searchKey){
    this.searchKey=searchKey;
    refreshDatasource();
  }

  void filter(Map<String,String> filters){
    this.filters=filters;
    refreshDatasource();

  }

  Map<String,String>? filters;

  Future<int> getTotalRecords() {
    return Future<int>.delayed(
        const Duration(milliseconds: 0), () => _empty ? 0 : vehicles.length);
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    if (_errorCounter != null) {
      _errorCounter = _errorCounter! + 1;

      if (_errorCounter! % 2 == 1) {
        await Future.delayed(const Duration(milliseconds: 1000));
        throw 'Error #${((_errorCounter! - 1) / 2).round() + 1} has occured';
      }
    }

    final dateFormat=DateFormat('y/M/d HH:mm:ss','fr');
    final tstyle=TextStyle(
      fontSize: 10.sp,
    );

    assert(startIndex >= 0);

    // List returned will be empty is there're fewer items than startingAt
    var x = _empty
        ? await Future.delayed(const Duration(milliseconds: 1000),
            () => VehiculesWebServiceResponse(0, []))
        : await _repo.getData(startIndex, count, _sortColumn, _sortAscending,searchKey: searchKey,filters: filters);

    var r = AsyncRowsResponse(
        x.totalRecords,
        x.data.map((vahicle) {
          return DataRow(
            key: ValueKey<String>(vahicle.value.id!),
            selected: vahicle.value.selected,
            onSelectChanged: (value) {
              if (value != null) {
                setRowSelection(ValueKey<String>(vahicle.value.id!), value);
              }
            },
            cells: [
              DataCell(SelectableText(vahicle.value.matricule,style: tstyle,)),
              DataCell(Row(
                children: [
                  Image.asset('assets/images/marques/${vahicle.value.marque?.id ?? 'default'}.webp',width: 4.h,height: 4.h,),
                  const SizedBox(width: 5,),
                  SelectableText(vahicle.value.type ?? '',style: tstyle),
                ],
              )),
              DataCell(SelectableText(vahicle.value.anneeUtil.toString(),style: tstyle)),
              DataCell(SelectableText(
                  dateFormat.format(ClientDatabase.ref.add(Duration(milliseconds:vahicle.value.dateModification!)))
                  ,style: tstyle)),
              DataCell(f.FlyoutTarget(
                controller: vahicle.value.controller,
                child: IconButton(
                    splashRadius: 15,
                    onPressed: (){
                      vahicle.value.controller.showFlyout(builder: (context){
                        return f.MenuFlyout(
                          items: [
                            f.MenuFlyoutItem(
                              text: const Text('mod').tr(),
                              onPressed: (){
                                Navigator.of(current).pop();
                                late f.Tab tab;
                                tab = f.Tab(
                                  key: UniqueKey(),
                                  text: Text('${"mod".tr()} ${'vehicule'.tr().toLowerCase()} ${vahicle.value.matricule}'),
                                  semanticLabel: '${'mod'.tr()} ${vahicle.value.matricule}',
                                  icon: const Icon(Bootstrap.car_front),
                                  body: VehicleForm(vehicle: vahicle.value,),
                                  onClosed: () {
                                    VehicleTabsState.tabs.remove(tab);

                                    if (VehicleTabsState.currentIndex.value > 0) {
                                      VehicleTabsState.currentIndex.value--;
                                    }
                                  },
                                );
                                final index = VehicleTabsState.tabs.length + 1;
                                VehicleTabsState.tabs.add(tab);
                                VehicleTabsState.currentIndex.value = index - 1;
                              }
                            ),
                            f.MenuFlyoutItem(
                              text: const Text('delete').tr(),
                              onPressed: (){
                                showDeleteConfirmation(vahicle.value);
                              }
                            ),
                            const f.MenuFlyoutSeparator(),
                            f.MenuFlyoutSubItem(
                              text: const Text('chstates').tr(),
                              items: (BuildContext context) {
                                return [
                                  f.MenuFlyoutItem(
                                      text: const Text('gstate').tr(),
                                      onPressed: (){

                                      }
                                  ),
                                  f.MenuFlyoutItem(
                                      text: const Text('bstate').tr(),
                                      onPressed: (){

                                      }
                                  ),
                                  f.MenuFlyoutItem(
                                      text: const Text('rstate').tr(),
                                      onPressed: (){

                                      }
                                  ),
                                ];
                              },
                            ),
                          ],
                        );
                      });
                    },
                    icon: const Icon(Icons.more_vert_sharp)),
              )),
            ],
          );
        }).toList());

    return r;
  }

  void showDeleteConfirmation(Vehicle v){

    f.showDialog(
        context: current,
        builder: (context){
          return f.ContentDialog(
            content: Text('${'supvehic'.tr()} ${v.matricule}'),
            actions: [
              f.FilledButton(onPressed: (){
                Navigator.of(context).pop();
              }, child: const Text('annuler').tr()),
              f.Button(onPressed: (){
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                deleteVehicle(v);

              },child: const Text('confirmer').tr(),)
            ],
          );
        }
        );
  }


  void deleteVehicle(Vehicle v) async{
    await ClientDatabase.database!.deleteDocument(
        databaseId: databaseId,
        collectionId: vehiculeid,
        documentId: v.id!).then((value) {
      vehicles.remove(MapEntry(v.id!, v));
      notifyListeners();
    }).onError((error, stackTrace) {

      f.showSnackbar(current,f.InfoBar(
         title: const Text('erreur').tr(),
          severity: f.InfoBarSeverity.error
      ),
        alignment: Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
      );
    });

  }

}



List<MapEntry<String,Vehicle>> vehicles = List.empty(growable: true);

