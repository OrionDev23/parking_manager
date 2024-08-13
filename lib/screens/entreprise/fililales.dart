import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import '../dashboard/charts/pie_chart.dart';
import '../dashboard/charts/state_bars.dart';
import '../dashboard/table_stats.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';
import 'appartenanceContainer.dart';
import 'entreprise.dart';
import '../../providers/client_database.dart';
import '../../main.dart';

class MesFilliales extends StatefulWidget {

  final int type;
  const MesFilliales({super.key,this.type=0});

  @override
  State<MesFilliales> createState() => MesFillialesState();
}

class MesFillialesState extends State<MesFilliales> {
  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  double height = 400.px;
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
        header: PageTitle(
          text: widget.type==1?'directions'.tr():widget
              .type==2?'departements'.tr():'fililales'
              .tr(),
          trailing: ButtonContainer(
            icon: FluentIcons.add,
            text: 'add'.tr(),
            showBottom: false,
            showCounter: false,
            action: ()=>addNewOne(appTheme),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 300.px,
                    height: 40.px,
                    child: TextBox(
                      controller: searchController,
                      placeholder: 'search'.tr(),
                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: BoxDecoration(color: appTheme.fillColor),
                      onChanged: (s) {
                        if (s.isNotEmpty) {
                          notEmpty = true;
                        } else {
                          if (notEmpty) {
                            notEmpty = false;
                          }
                        }
                        setState(() {});
                      },
                      suffix: notEmpty
                          ? IconButton(
                              icon: const Icon(FluentIcons.cancel),
                              onPressed: () {
                                searchController.text = "";
                                notEmpty = false;
                                setState(() {});
                              })
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            widget.type==0?
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  StaggeredGrid.count(
                    crossAxisCount:
                        Device.orientation == Orientation.portrait ? 2 : 4,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    children: directionsSearched()
                        .map((e) => AppartenanceContainer(
                              state: this,
                              key: ValueKey(e),
                              type: widget.type,
                              name: e,
                              fieldToSearch: 'filliale',
                            ))
                        .toList(),
                  ),
                  smallSpace,
                  StaggeredGrid.count(
                      crossAxisCount:
                          Device.orientation == Orientation.landscape ? 2 : 1,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                      children: [
                        StaggeredGridTile.fit(
                          crossAxisCellCount: 1,
                          child: TableStats(
                            height: height,
                            title: 'appartenancevehicule'.tr(),
                            icon: Icon(
                              Icons.emoji_transportation,
                              color: appTheme.color.darker,
                            ),
                            content: ParcOtoPie(
                              labels: List.generate(
                                  MyEntrepriseState.p!.filiales?.length ?? 0,
                                  (index) => MapEntry(
                                      MyEntrepriseState.p!.filiales![index],
                                      DatabaseCounters()
                                          .countVehiclesWithCondition([
                                        Query.equal(
                                            'appartenance',
                                            MyEntrepriseState
                                                .p!.filiales![index]
                                                .replaceAll(' ', '')
                                                .trim())
                                      ]))),
                            ),
                            onTap: () {
                              PanesListState.index.value = PaneItemsAndFooters
                                      .originalItems
                                      .indexOf(PaneItemsAndFooters.vehicles) +
                                  1;
                            },
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: 1,
                          child: TableStats(
                            height: height,
                            title: 'appartenanceconducteur'.tr(),
                            icon: Icon(
                              Icons.home_work_outlined,
                              color: appTheme.color.darker,
                            ),
                            content: ParcOtoPie(
                              labels: List.generate(
                                  MyEntrepriseState.p!.filiales?.length ?? 0,
                                  (index) => MapEntry(
                                      MyEntrepriseState.p!.filiales![index],
                                      DatabaseCounters()
                                          .countChauffeurWithCondition([
                                        Query.equal(
                                            'filliale',
                                            MyEntrepriseState
                                                .p!.filiales![index]
                                                .replaceAll(' ', '')
                                                .trim())
                                      ]))),
                            ),
                            onTap: () {
                              PanesListState.index.value = PaneItemsAndFooters
                                      .originalItems
                                      .indexOf(PaneItemsAndFooters.vehicles) +
                                  1;
                            },
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: 2,
                          child: TableStats(
                            height: height * 2,
                            title: 'exploitationvehicule'.tr(),
                            icon: Icon(
                              Icons.hub,
                              color: appTheme.color.darker,
                            ),
                            content: StateBars(
                              hideEmpty: true,
                              vertical: true,
                              labels: List.generate(
                                  MyEntrepriseState.p!.filiales?.length ?? 0,
                                  (index) => MapEntry(
                                      MyEntrepriseState.p!.filiales![index],
                                      DatabaseCounters()
                                          .countVehiclesWithCondition([
                                        Query.equal(
                                            'filliale',
                                            MyEntrepriseState
                                                .p!.filiales![index]
                                                .replaceAll(' ', '')
                                                .trim())
                                      ]))),
                            ),
                            onTap: () {
                              PanesListState.index.value = PaneItemsAndFooters
                                      .originalItems
                                      .indexOf(PaneItemsAndFooters.vehicles) +
                                  1;
                            },
                          ),
                        ),
                      ]),
                ],
              ),
            ):
            widget.type==1?
            Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    StaggeredGrid.count(
                      crossAxisCount:
                      Device.orientation == Orientation.portrait ? 2 : 4,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                      children: directionsSearched()
                          .map((e) => AppartenanceContainer(
                        state: this,
                        key: ValueKey(e),
                        type: widget.type,
                        name: e,
                        fieldToSearch: 'direction',
                      ))
                          .toList(),
                    ),
                    smallSpace,
                    StaggeredGrid.count(
                        crossAxisCount:
                        Device.orientation == Orientation.landscape ? 2 : 1,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                        children: [
                          StaggeredGridTile.fit(
                            crossAxisCellCount: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: appTheme.backGroundColor,
                                boxShadow: kElevationToShadow[2],
                              ),
                              padding: const EdgeInsets.all(10),
                              height: height * 2,
                              child: StateBars(
                                hideEmpty: true,
                                vertical: true,
                                labels: List.generate(
                                    MyEntrepriseState.p!.directions?.length ?? 0,
                                        (index) => MapEntry(
                                        MyEntrepriseState.p!.directions![index],
                                        DatabaseCounters()
                                            .countVehiclesWithCondition([
                                          Query.equal(
                                              'direction',
                                              MyEntrepriseState
                                                  .p!.directions![index]
                                                  .replaceAll(' ', '')
                                                  .trim())
                                        ]))),
                              ),
                            ),
                          ),
                        ]),
                  ],
                ),
              ):
            Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      StaggeredGrid.count(
                        crossAxisCount:
                        Device.orientation == Orientation.portrait ? 2 : 4,
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                        children: directionsSearched()
                            .map((e) => AppartenanceContainer(
                          state: this,
                          key: ValueKey(e),
                          type: widget.type,
                          name: e,
                          fieldToSearch: 'departement',
                        ))
                            .toList(),
                      ),
                      smallSpace,
                      StaggeredGrid.count(
                          crossAxisCount:
                          Device.orientation == Orientation.landscape ? 2 : 1,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                          children: [
                            StaggeredGridTile.fit(
                              crossAxisCellCount: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: appTheme.backGroundColor,
                                  boxShadow: kElevationToShadow[2],
                                ),
                                padding: const EdgeInsets.all(10),
                                height: height * 2,
                                child: StateBars(
                                  hideEmpty: true,
                                  vertical: true,
                                  labels: List.generate(
                                      MyEntrepriseState.p!.departments?.length ?? 0,
                                          (index) => MapEntry(
                                          MyEntrepriseState.p!.departments![index],
                                          DatabaseCounters()
                                              .countVehiclesWithCondition([
                                            Query.equal(
                                                'departement',
                                                MyEntrepriseState
                                                    .p!.departments![index]
                                                    .replaceAll(' ', '')
                                                    .trim())
                                          ]))),
                                ),
                              ),
                            ),
                          ]),
                    ],
                  ),
                )
          ],
        ));
  }

  List<String> directionsSearched() {
    List<String> result = List.empty(growable: true);
    if(widget.type==1){
      MyEntrepriseState.p?.directions?.forEach((value) {
        if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
          result.add(value);
        }
      });

    }
    else if (widget.type==0){

      MyEntrepriseState.p?.filiales?.forEach((value) {
        if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
          result.add(value);
        }
      });
    }
    else {
      MyEntrepriseState.p?.departments?.forEach((value) {
        if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
          result.add(value);
        }
      });
    }

    return result;
  }


  TextEditingController textToEdit=TextEditingController();
  void addNewOne(AppTheme appTheme){
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) {
          return ContentDialog(
            title: Text(widget.type==1?
            'addnewdirection'
                :widget.type==2?'addnewdepartment':'addnewfiliale',style:
            TextStyle
              (fontSize: 16
                .px),).tr(),
            constraints: BoxConstraints.loose(Size(300.px, 190.px)),
            content: TextBox(
              controller: textToEdit,
              placeholderStyle: placeStyle,
              style: appTheme.writingStyle,
              cursorColor: appTheme.color.dark,
              placeholder: 'nom'.tr(),
              decoration: BoxDecoration(
                color: appTheme.fillColor,
              ),
            ),
            actions: [
              Button(child:const Text('fermer').tr(),onPressed:(){
                Navigator.of(context).pop();
              }),
              FilledButton(onPressed: confirmChanges, child: const Text('confirmer').tr())
            ],
          );
        });
  }


  void confirmChanges() async{
    if(textToEdit.text.trim().isEmpty){
      Future.delayed(const Duration(milliseconds:50)).then((s)=>
          displayMessage(context,'nomrequired',InfoBarSeverity.error)
      );
      return;
    }
    if(widget.type==1){
      if(MyEntrepriseState.p!.directions==null){
        MyEntrepriseState.p!.directions=[];
      }
      MyEntrepriseState.p!.directions!.add(textToEdit.text);
    }
    else if(widget.type==0){
      if(MyEntrepriseState.p!.filiales==null){
        MyEntrepriseState.p!.filiales=[];
      }
      MyEntrepriseState.p!.filiales!.add(textToEdit.text);
    }
    else{
      if(MyEntrepriseState.p!.departments==null){
        MyEntrepriseState.p!.departments=[];
      }
      MyEntrepriseState.p!.departments!.add(textToEdit.text);
    }
    Navigator.of(context).pop();
    await DatabaseGetter.database!
        .updateDocument(
        databaseId: databaseId,
        collectionId: entrepriseid,
        documentId: MyEntrepriseState.p!.id,
        data: {
          if(widget.type==1)
          'directions':MyEntrepriseState.p!.directions,
          if(widget.type==0)
            'filiales':MyEntrepriseState.p!.filiales,
          if(widget.type==2)
            'departement':MyEntrepriseState.p!.departments,
        })
        .then((value) {
      displayMessage(context,'done',InfoBarSeverity.success);
          setState((){});
         }).onError((AppwriteException error, stackTrace) {
      displayMessage(context,'error',InfoBarSeverity.error);
    });
  }
}
