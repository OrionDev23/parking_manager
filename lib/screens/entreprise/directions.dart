import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/screens/entreprise/appartenanceContainer.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/page_header.dart';
import '../dashboard/charts/state_bars.dart';

class MesDirections extends StatefulWidget {
  const MesDirections({super.key});

  @override
  State<MesDirections> createState() => _MesDirectionsState();
}

class _MesDirectionsState extends State<MesDirections> {
  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  double height = 400.px;
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
        header: PageTitle(
          text: 'directions'.tr(),
          trailing: ButtonContainer(
            icon: FluentIcons.add,
            text: 'add'.tr(),
            showBottom: false,
            showCounter: false,
            action: () {},
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
    MyEntrepriseState.p?.directions?.forEach((value) {
      if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
        result.add(value);
      }
    });
    return result;
  }
}
