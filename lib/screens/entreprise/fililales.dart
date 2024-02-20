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

  final bool direction;
  const MesFilliales({super.key,this.direction=false});

  @override
  State<MesFilliales> createState() => _MesFillialesState();
}

class _MesFillialesState extends State<MesFilliales> {
  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  double height = 400.px;
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
        header: PageTitle(
          text: widget.direction?'directions'.tr():'fililales'.tr(),
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
            if(!widget.direction)
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
                              key: ValueKey(e),
                              filliale: true,
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
            ),
            if(widget.direction)
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
                        key: ValueKey(e),
                        filliale: false,
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
              ),
          ],
        ));
  }

  List<String> directionsSearched() {
    List<String> result = List.empty(growable: true);
    if(widget.direction){
      MyEntrepriseState.p?.directions?.forEach((value) {
        if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
          result.add(value);
        }
      });

    }
    else{

      MyEntrepriseState.p?.filiales?.forEach((value) {
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
            title: Text(widget.direction?'addnewdirection':'addnewfiliale',style: TextStyle(fontSize: 16
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
              FilledButton(child: const Text('confirmer').tr(), onPressed: (){})
            ],
          );
        });
  }


  void confirmChanges() async{
    if(textToEdit.text.trim().isEmpty){
      Future.delayed(Duration(milliseconds:50)).then((s)=>
          displayMessage(context,'nomrequired',InfoBarSeverity.error)
      );
      return;
    }
    Navigator.of(context).pop();
    await ClientDatabase.database!
        .updateDocument(
        databaseId: databaseId,
        collectionId: entrepriseid,
        documentId: MyEntrepriseState.p!.id,
        data: {
          if(widget.direction)
          'directions':MyEntrepriseState.p!.directions,
          if(!widget.direction)
            'filiales':MyEntrepriseState.p!.filiales,
        })
        .then((value) {
      displayMessage(context,'done',InfoBarSeverity.success);
          setState((){});
         }).onError((AppwriteException error, stackTrace) {
      print(error.message);
    });
  }
}
