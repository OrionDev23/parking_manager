import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart' hide Trans;
import 'package:parc_oto/screens/workshop/parts/parts_management/parts_table.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../serializables/pieces/part.dart';
import 'package:provider/provider.dart';

import '../../../../theme.dart';
import '../../../../widgets/empty_table_widget.dart';
import '../../../../widgets/zone_box.dart';
import 'variation_storage.dart';

class StorageForm extends StatefulWidget {
  const StorageForm({super.key});

  @override
  State<StorageForm> createState() => _StorageFormState();
}

class _StorageFormState extends State<StorageForm> {

  VehiclePart? selectedPart;
  double qte=1;
  List<DateTime?>expirationDates=[DateTime.now().add(Duration(days: 30))];
  bool differentDate=false;
  bool expire=true;

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    bool portrait = context.orientation == Orientation.portrait;

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.all(10),

      children: [
        StaggeredGrid.count(
          crossAxisCount: portrait ? 1 : 4,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          children: [
            StaggeredGridTile.fit(
              crossAxisCellCount: 3,
              child: Container(
                width: 200.px,
                height: 170.px,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: kElevationToShadow[2],
                  color: appTheme.backGroundColor,
                ),
                child: Column(
                  children: [
                    Text(
                      'slcprd',
                      style: appTheme.titleStyle,
                    ).tr(),
                    smallSpace,
                    Flexible(
                      flex: 1,
                      child: ZoneBox(
                        label: 'slcprd'.tr(),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: FilledButton(
                              child: Text(selectedPart == null
                                  ? 'nonind'.tr()
                                  : selectedPart!.name),
                              onPressed: () async {
                                selectedPart = await showDialog<VehiclePart>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return ContentDialog(
                                        constraints:
                                        BoxConstraints.tight(Size(700.px, 550.px)),
                                        title: const Text('slcprd').tr(),
                                        style: ContentDialogThemeData(
                                            titleStyle: appTheme.writingStyle
                                                .copyWith(fontWeight: FontWeight.bold)),
                                        content: const PartsTable(
                                          selectD: true,
                                        ),
                                        actions: [
                                          Button(
                                              child: const Text('fermer').tr(),
                                              onPressed: () {
                                                selectedPart = null;
                                                setState(() {});
                                                Navigator.of(context).pop();
                                              })
                                        ],
                                      );
                                    });
                                setState(() {});
                              }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if(selectedPart!=null)
            StaggeredGridTile.fit(
              crossAxisCellCount: 1,
              child: Container(
                width: 200.px,
                height: 170.px,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: kElevationToShadow[2],
                  color: appTheme.backGroundColor,
                ),
                child: Column(
                  children: [
                    Text(
                      'quantity',
                      style: appTheme.titleStyle,
                    ).tr(),
                    smallSpace,
                    Flexible(
                      flex: 1,
                      child: ZoneBox(
                        label: 'quantity'.tr(),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: selectedPart!.unitType==0?NumberBox<int>(
                            value: qte.toInt(),
                            onChanged: (int? value) {
                              setState(() {
                                qte=value?.toDouble()??0;
                              });
                            },
                            min: 0,
                          )
                          :NumberBox<double>(value: qte, onChanged: (s){
                            setState(() {
                              qte=s??0;
                            });
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if(selectedPart!=null )
              StaggeredGridTile.fit(
                crossAxisCellCount: 2,
                child: Container(
                  width: 200.px,
                  height: expire?170.px:70.px,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: kElevationToShadow[2],
                    color: appTheme.backGroundColor,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'dateexp',
                            style: appTheme.titleStyle,
                          ).tr(),
                          Checkbox(
                            checked: expire,
                            onChanged: (s){
                              setState(() {
                                expire=s??false;
                              });
                            },
                            content: Text(
                              'toexpire'
                            ).tr(),
                          ),
                        ],
                      ),
                      if(expire)
                      smallSpace,
                      if(expire)
                        Flexible(
                        flex: 1,
                        child: ZoneBox(
                          label: 'dateexp'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if(differentDate==false)
                                DatePicker(
                                  selected: expirationDates[0],
                                  onChanged: (d){
                                    if(expirationDates.isNotEmpty){
                                      expirationDates[0]=d;
                                    }
                                    else{
                                      expirationDates.add(d);
                                    }
                                    setState(() {

                                    });
                                  },

                                ),
                                if(qte>1)
                                      Checkbox(
                                        checked: differentDate,
                                        onChanged: (bool? value) {
                                          differentDate=value??false;
                                          setState(() {

                                          });
                                        },
                                        content: Text(
                                          'differentDates'
                                        ).tr(),

                                      ),
                              ],
                            )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if(selectedPart!=null && selectedPart!.variations!=null &&
            selectedPart!.variations!.isNotEmpty)
              variationsWidget(appTheme,portrait)

          ],
        ),
      ],
    );
  }

  Widget variationsWidget(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
        crossAxisCellCount: 3,
        child: Container(
          width: 400.px,
          height:
          variations.isEmpty ? 480.px : 50.px * variations.length + 165.px,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: kElevationToShadow[2],
            color: appTheme.backGroundColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'variations',
                style: appTheme.titleStyle,
              ).tr(),
              smallSpace,
              designationTable(appTheme),
            ],
          ),
        ));
  }

  List<VariationStorage> variations = List.empty(growable: true);

  int qteRestant=1;
  void addDesignation() {
    variations.add(VariationStorage(
      key: UniqueKey(),
      part: selectedPart!,
      qte: qteRestant,
      onQteChanged: () {
        setState(() {});
      },
    ));
    setState(() {});
  }

  Widget designationTable(AppTheme appTheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                    onPressed:
                    selectedDesignationsExist() ? deleteAllSelected : null,
                    child: const Text('delete').tr()),
                smallSpace,
                FilledButton(
                    onPressed: addDesignation, child: const Text('add').tr()),
              ],
            ),
          ),
          smallSpace,
          Container(
            decoration: BoxDecoration(
              color: appTheme.color.lightest,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            padding: const EdgeInsets.all(5),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(5),
                3: FlexColumnWidth(3),
              },
              children: [
                TableRow(children: [
                  TableCell(
                      child: const Text(
                        'N°',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'nom',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'options',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'dateexp',
                        textAlign: TextAlign.center,
                      ).tr()),
                ]),
              ],
            ),
          ),
          variations.isEmpty
              ? Container(
              padding: const EdgeInsets.all(10),
              width: 300.px,
              height: 320.px,
              child: const NoDataWidget())
              : Container(
            decoration: BoxDecoration(
              border: Border.all(color: appTheme.fillColor),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(5)),
            ),
            child: Column(children: getDesignationList(appTheme)),
          ),
        ],
      ),
    );
  }

  bool selectedDesignationsExist() {
    for (int i = 0; i < variations.length; i++) {
      if (variations[i].selected) {
        return true;
      }
    }
    return false;
  }

  void deleteAllSelected() {
    List<VariationStorage> temp = List.from(variations);
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].selected) {
        variations.remove(temp[i]);
      }
    }
    setState(() {});
  }

  List<Widget> getDesignationList(AppTheme appTheme) {
    return List.generate(variations.length, (index) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? appTheme.fillColor : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                    checked: variations[index].selected,
                    onChanged: (s) {
                      setState(() {
                        variations[index]=VariationStorage
                          (key:variations[index].key,
                          qte: variations[index].qte,
                          part: variations[index].part,
                          selected: s??false,
                          expirationDate: variations[index].expirationDate,);
                      });
                    }),
                smallSpace,
                Flexible(
                  child: SizedBox(
                    height: 35.px,
                    child: variations[index],
                  ),
                ),
              ],
            ),
            smallSpace,
          ],
        ),
      );
    });
  }
}
