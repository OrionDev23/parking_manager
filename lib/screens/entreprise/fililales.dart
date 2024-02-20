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

class MesFilliales extends StatefulWidget {
  const MesFilliales({super.key});

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
          text: 'fililales'.tr(),
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
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
          ],
        ));
  }

  List<String> directionsSearched() {
    List<String> result = List.empty(growable: true);
    MyEntrepriseState.p?.filiales?.forEach((value) {
      if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
        result.add(value);
      }
    });
    return result;
  }


  TextEditingController textToEdit=TextEditingController();
  void addNewOne(AppTheme appTheme){
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) {
          return ContentDialog(
            title: Text('addnewfiliale',style: TextStyle(fontSize: 16
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
}
