
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/admin_parameters.dart';
import 'package:parc_oto/theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../screens/vehicle/documents/document_form.dart';
import '../../screens/vehicle/manager/vehicle_form.dart';
import '../../screens/vehicle/manager/vehicle_tabs.dart';
import '../../screens/vehicle/states/state_form.dart';
import '../../serializables/vehicle/vehicle.dart';
import '../../utilities/vehicle_util.dart';
import '../../widgets/on_tap_scale.dart';
import '../parcoto_datasource.dart';
import 'vehicle_webservice.dart';

class VehiculeDataSource extends ParcOtoDatasource<Vehicle> {
  VehiculeDataSource(
      {required super.current,
      super.appTheme,
      super.filters,
      super.searchKey,
      super.selectC,
      required super.collectionID}) {
    repo = VehiculesWebService(data, collectionID, 1);
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Vehicle> element) {

    if(conducteurEmploye){
      return getCellsToShowEmploye(element);

    }
    else{
      return getCellsToShowNonEmploye(element);
    }
  }


  List<DataCell> getCellsToShowEmploye(MapEntry<String,Vehicle> element){
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    return [
      DataCell(Text(
        element.value.id,
        style: rowTextStyle,
      ),
      ),
      DataCell(SelectableText(
        element.value.matricule,
        style: rowTextStyle,
      ),
        onDoubleTap: ()=>viewVehicule(element),
      ),
      DataCell(Row(
        children: [
          Image.asset(
            element.value.marque == null ||
                element.value.marque!.isEmpty ||
                element.value.marque!.contains('null') || element.value
                .marque=='-1'
                ? 'assets/images/marques/default.webp'
                : 'assets/images/marques/${element.value.marque ?? 'default'}.webp',
            width: 3.5.h,
            height: 3.5.h,
          ),
          const SizedBox(
            width: 2,
          ),
          Expanded(
              child: Text(
                element.value.type ?? '',
                style: rowTextStyle,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ),
      ),
      DataCell(Text(
          VehiclesUtilities.getEtatName(element.value.etatactuel ?? 0),
          style: rowTextStyle)
          .tr()),
      DataCell(Text(
          VehiclesUtilities.getPerimetre(element.value.perimetre),
          style: rowTextStyle)
          .tr()),
      DataCell(Text(
          VehiclesUtilities.getAppartenance(element.value.appartenance),
          style: rowTextStyle)
          .tr()),
      DataCell(Text(
          VehiclesUtilities.getDirection(element.value.direction),
          style: rowTextStyle)
          .tr()),
      DataCell(Text(
          element.value.matriculeConducteur==null || element.value
              .matriculeConducteur=='null'?'':element.value
              .matriculeConducteur!,
          style: rowTextStyle)),
      DataCell(Text(
          element.value.nom==null || element.value
              .nom=='null'?'':element.value
              .nom!,
          style: rowTextStyle)),
      DataCell(Text(
          element.value.prenom==null || element.value
              .prenom=='null'?'':element.value
              .prenom!,
          style: rowTextStyle)),
      DataCell(Text(
          element.value.profession==null || element.value
              .profession=='null'?'':element.value
              .profession!,
          style: rowTextStyle)),
      DataCell(
          Text(dateFormat.format(element.value.updatedAt!), style: rowTextStyle)),
      if (selectC != true)
        DataCell(
          DatabaseGetter().isAdmin() || DatabaseGetter().isManager()
              ? f.FlyoutTarget(
            controller: element.value.controller,
            child: f.Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OnTapScaleAndFade(
                    onTap: (){viewVehicule(element);},
                    child: f.Container(
                        decoration: BoxDecoration(
                          color: appTheme?.color.lightest,
                          boxShadow: kElevationToShadow[2],
                        ),
                        child: Icon(Icons
                            .remove_red_eye_outlined,color: appTheme!
                            .color.darkest,
                        ))),
                smallSpace,
                OnTapScaleAndFade(
                    onTap: ()=>showEditStuff(element),
                    child: f.Container(
                        decoration: BoxDecoration(
                          color: appTheme?.color.lightest,
                          boxShadow: kElevationToShadow[2],
                        ),
                        child: Icon(Icons.edit,color: appTheme!
                            .color.darkest,))
                ),
              ],
            ),
          )
              : OnTapScaleAndFade(
              onTap: (){viewVehicule(element);},
              child: f.Container(
                  decoration: BoxDecoration(
                    color: appTheme?.color.lightest,
                    boxShadow: kElevationToShadow[2],
                  ),
                  child: Icon(Icons.remove_red_eye_outlined,color:
                  appTheme!
                      .color.darkest,))),
        ),
    ];
  }

  List<DataCell> getCellsToShowNonEmploye(MapEntry<String,Vehicle> element){
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    return [
      DataCell(Text(
        element.value.id,
        style: rowTextStyle,
      ), onDoubleTap: ()=>viewVehicule(element),
      ),
      DataCell(SelectableText(
        element.value.numeroSerie??'',
        style: rowTextStyle,

      ),
    onDoubleTap: ()=>viewVehicule(element),
      ),
      DataCell(SelectableText(
        element.value.matricule,
        style: rowTextStyle,
      ),
        onDoubleTap: ()=>viewVehicule(element),
      ),
      DataCell(Row(
        children: [
          Image.asset(
            element.value.marque == null ||
                element.value.marque!.isEmpty ||
                element.value.marque!.contains('null') || element.value
                .marque=='-1'
                ? 'assets/images/marques/default.webp'
                : 'assets/images/marques/${element.value.marque ?? 'default'}.webp',
            width: 3.5.h,
            height: 3.5.h,
          ),
          const SizedBox(
            width: 2,
          ),
          Expanded(
              child: Text(
                element.value.type ?? '',
                style: rowTextStyle,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ),
      ),
      DataCell(Text(
          VehiclesUtilities.getEtatName(element.value.etatactuel ?? 0),
          style: rowTextStyle)
          .tr()),
      DataCell(Text(
          VehiclesUtilities.getPerimetre(element.value.perimetre),
          style: rowTextStyle)
          .tr()),

      DataCell(
          Text(dateFormat.format(element.value.updatedAt!), style: rowTextStyle)),
      if (selectC != true)
        DataCell(
          DatabaseGetter().isAdmin() || DatabaseGetter().isManager()
              ? f.FlyoutTarget(
            controller: element.value.controller,
            child: f.Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OnTapScaleAndFade(
                    onTap: (){viewVehicule(element);},
                    child: f.Container(
                        decoration: BoxDecoration(
                          color: appTheme?.color.lightest,
                          boxShadow: kElevationToShadow[2],
                        ),
                        child: Icon(Icons
                            .remove_red_eye_outlined,color: appTheme!
                            .color.darkest,
                        ))),
                smallSpace,
                OnTapScaleAndFade(
                    onTap: ()=>showEditStuff(element),
                    child: f.Container(
                        decoration: BoxDecoration(
                          color: appTheme?.color.lightest,
                          boxShadow: kElevationToShadow[2],
                        ),
                        child: Icon(Icons.edit,color: appTheme!
                            .color.darkest,))
                ),
              ],
            ),
          )
              : OnTapScaleAndFade(
              onTap: (){viewVehicule(element);},
              child: f.Container(
                  decoration: BoxDecoration(
                    color: appTheme?.color.lightest,
                    boxShadow: kElevationToShadow[2],
                  ),
                  child: Icon(Icons.remove_red_eye_outlined,color:
                  appTheme!
                      .color.darkest,))),
        ),
    ];
  }

  void showEditStuff(MapEntry<String, Vehicle> element){


      element.value.controller.showFlyout(builder: (context) {
        return f.MenuFlyout(
          items: [
            f.MenuFlyoutItem(
                text: const Text('mod').tr(),
                onPressed: () {
                  Navigator.of(current).pop();
                  late f.Tab tab;
                  tab = f.Tab(
                    key: UniqueKey(),
                    text: Text(
                        '${"mod".tr()} ${'vehicule'.tr().toLowerCase()} ${element.value.matricule}'),
                    semanticLabel:
                    '${'mod'.tr()} ${element.value.matricule}',
                    icon: const Icon(f.FluentIcons.edit),
                    body: VehicleForm(
                      vehicle: element.value,
                    ),
                    onClosed: () {
                      VehicleTabsState.tabs.remove(tab);

                      if (VehicleTabsState
                          .currentIndex.value >
                          0) {
                        VehicleTabsState.currentIndex.value--;
                      }
                    },
                  );
                  final index =
                      VehicleTabsState.tabs.length + 1;
                  VehicleTabsState.tabs.add(tab);
                  VehicleTabsState.currentIndex.value =
                      index - 1;
                }),
            if (DatabaseGetter().isAdmin())
              f.MenuFlyoutItem(
                  text: const Text('delete').tr(),
                  onPressed: () {
                    showDeleteConfirmation(element.value);
                  }),
            const f.MenuFlyoutSeparator(),
            f.MenuFlyoutItem(
                text: const Text('nouvdocument').tr(),
                onPressed: () {
                  Future.delayed(
                      const Duration(milliseconds: 50))
                      .then((value) {
                        if(current.mounted){
                        return f.showDialog(
                      context: current,
                      barrierDismissible: true,
                      builder: (context) {
                        return f.ContentDialog(
                          title: Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              const Text('nouvdocument')
                                  .tr(),
                              f.Button(
                                  child: const Icon(f
                                      .FluentIcons
                                      .cancel),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop();
                                  }),
                            ],
                          ),
                          constraints:
                          BoxConstraints.loose(
                              Size(420.px, 450.px)),
                          content: DocumentForm(
                            vehicle: element.value,
                          ),
                        );
                      });}
                      });
                }),
            f.MenuFlyoutSubItem(
              text: const Text('chstates').tr(),
              items: (BuildContext context) {
                return conducteurEmploye?getEtatItemsEmploye(context, element):getEtatItemsNonEmploye(context, element);
              },
            ),
            f.MenuFlyoutSubItem(
              text: const Text('perimetre').tr(),
              items: (BuildContext context){
                return conducteurEmploye?getPerimetreEmploye(context, element):getPerimetreNonEmploye(context, element);
              }
            ),
          ],
        );
      });

  }


  List<f.MenuFlyoutItem> getEtatItemsEmploye(BuildContext context,MapEntry<String,Vehicle> element){
    return [
      f.MenuFlyoutItem(
          text: const Text('gstate').tr(),
          onPressed: () {
            Navigator.of(context).pop();
            showStateForm(element.value, 0);
          }),
      f.MenuFlyoutItem(
          text: const Text('bstate').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 1);
          }),
      f.MenuFlyoutItem(
          text: const Text('rstate').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 2);
          }),
      f.MenuFlyoutItem(
          text: const Text('ostate').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 3);
          }),
      f.MenuFlyoutItem(
          text: const Text('restate').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 4);
          }),
    ];
  }
  List<f.MenuFlyoutItem> getEtatItemsNonEmploye(BuildContext context,MapEntry<String,Vehicle> element){
    return [
      f.MenuFlyoutItem(
          text: const Text('dispo').tr(),
          onPressed: () {
            Navigator.of(context).pop();
            showStateForm(element.value, 5);
          }),
      f.MenuFlyoutItem(
          text: const Text('panne').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 6);
          }),
      f.MenuFlyoutItem(
          text: const Text('enreparation').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 7);
          }),
      f.MenuFlyoutItem(
          text: const Text('enmission').tr(),
          onPressed: () {
            Navigator.of(context).pop();

            showStateForm(element.value, 8);
          }),
    ];
  }

  List<f.MenuFlyoutItem> getPerimetreEmploye(BuildContext context,MapEntry<String,Vehicle> element){
    return [
      f.MenuFlyoutItem(
          text: const Text('buisiness').tr(),
          onPressed: () {
            changePerimeter(element,0);

          }
      ),
      f.MenuFlyoutItem(
          text: const Text('hors perimetre').tr(),
          onPressed: () {
            changePerimeter(element,1);

          }
      ),
      f.MenuFlyoutItem(
          text: const Text('industrie').tr(),
          onPressed: () {
            changePerimeter(element,2);
          }
      ),
    ];
  }
  List<f.MenuFlyoutItem> getPerimetreNonEmploye(BuildContext context,MapEntry<String,Vehicle> element){
    return [
      f.MenuFlyoutItem(
          text: const Text('auparking').tr(),
          onPressed: () {
            changePerimeter(element,3);

          }
      ),
      f.MenuFlyoutItem(
          text: const Text('horsparking').tr(),
          onPressed: () {
            changePerimeter(element,4);

          }
      ),
    ];
  }



  void changePerimeter(MapEntry<String,Vehicle> element,int
  perimeter) async{
      await DatabaseGetter.database?.updateDocument(
          databaseId: databaseId,
          collectionId: vehiculeid,
          documentId: element.key,
          data: {
            'perimetre':perimeter
          }
      ).then((value) {
        element.value.perimetre=perimeter;
        if(current.mounted){
        f.displayInfoBar(current,
            builder: (BuildContext context, void Function() close) {
              return f.InfoBar(
                title: const Text('done').tr(),
                severity: f.InfoBarSeverity.success,
              );
            }, duration: snackbarShortDuration);}
        DatabaseGetter().ajoutActivity(35, element.key,docName:element.value
            .matricule);
        notifyListeners();
      }).onError((error, stackTrace) {
        if(current.mounted){
        f.displayInfoBar(current,
            builder: (BuildContext context, void Function() close) {
              return f.InfoBar(
                title: const Text('erreur').tr(),
                severity: f.InfoBarSeverity.error,
              );
            }, duration: snackbarShortDuration);}
      });
  }

  void viewVehicule(MapEntry<String,Vehicle> element){
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) {
          if(current.mounted){
          return f.showDialog(
        context: current,
        barrierDismissible: true,
        builder: (c) {
          return f.ContentDialog(
            constraints: BoxConstraints.loose(f.Size(900.px, 800.px)),
            content: VehicleForm(readOnly: true,vehicle: element.value,),
            actions: [
              f.Button(child:const Text('fermer').tr(),onPressed:(){
                Navigator.of(current).pop();
              })
            ],
          );
        });}
        });
  }

  @override
  void longPressing(MapEntry<String, Vehicle> element) {
    showEditStuff(element);
  }

  @override
  String deleteConfirmationMessage(c) {
    return '${'supvehic'.tr()} ${c.matricule}';
  }

  @override
  Future<void> addToActivity(c) async {
    await DatabaseGetter().ajoutActivity(2, c.id, docName: c.matricule);
  }

  void showStateForm(Vehicle v, int type) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) {
          if(current.mounted){
          return f.showDialog(
            context: current,
            barrierDismissible: true,
            builder: (c) {
              return f.ContentDialog(
                title: const Text("nouvetat").tr(),
                constraints: BoxConstraints.loose(f.Size(800.px, 500.px)),
                content: StateForm(
                  vehicle: v,
                  type: type,
                  vehicleDatasource: this,
                ),
              );
            });}
        });
  }
}
