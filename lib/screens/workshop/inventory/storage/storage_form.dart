import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart' hide Trans;
import '../fournisseurs/fournisseur_table.dart';
import '../../parts/parts_management/parts_table.dart';
import '../../../../serializables/client.dart';
import '../../../../serializables/pieces/storage_variations.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../providers/parts_provider.dart';
import '../../../../serializables/pieces/part.dart';
import 'package:provider/provider.dart';

import '../../../../serializables/pieces/storage.dart';
import '../../../../theme.dart';
import '../../../../widgets/empty_table_widget.dart';
import '../../../../widgets/zone_box.dart';
import 'variation_storage.dart';

class StorageForm extends StatefulWidget {

  final Storage? storage;
  const StorageForm({super.key, this.storage});

  @override
  State<StorageForm> createState() => _StorageFormState();
}

class _StorageFormState extends State<StorageForm> {

  VehiclePart? selectedPart;
  Client? selectedF;
  double qte=1;
  DateTime? expirationDate=DateTime.now().add(Duration(days: 30));
  bool differentDate=false;
  bool expire=true;

  String? storageID;

  bool loading=true;

  @override
  void initState() {
    initStorage();
    super.initState();
  }

  Future<void> loadPart() async{
    if(widget.storage!=null){
        selectedPart=await PartsProvider().getPart(widget.storage!.partID);
    }
  }
  Future<void> loadFourn() async{
    if(widget.storage!=null && widget.storage!.fournisseurID!=null){
      selectedF=await PartsProvider().getFournisseur(widget.storage!.fournisseurID);
    }
  }

  void initStorage() async{
    if(widget.storage!=null){
      loading=true;
      if(mounted){
        setState(() {

        });
      }
      storageID=widget.storage!.id;
      qte=widget.storage!.qte;
      expirationDate=widget.storage!.expirationDate;
      expire=widget.storage!.expirationDate!=null;
      if(widget.storage!.variations!=null && widget.storage!.variations!.isNotEmpty){
        variations.addAll(widget.storage!.variations!);
      }
      await Future.wait([
        loadPart(),
        loadFourn()
      ]);


    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    bool portrait = context.orientation == Orientation.portrait;

    return Column(
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.all(10),
            children: [
              StaggeredGrid.count(
                crossAxisCount: portrait ? 1 : 6,
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
                            'fournselect',
                            style: appTheme.titleStyle,
                          ).tr(),
                          smallSpace,
                          Flexible(
                            flex: 1,
                            child: ZoneBox(
                              label: 'fournselect'.tr(),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: FilledButton(
                                    child: Text(selectedF == null
                                        ? 'nonind'.tr()
                                        : selectedF!.nom),
                                    onPressed: () async {
                                      selectedF = await showDialog<Client?>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) {
                                            return ContentDialog(
                                              constraints:
                                              BoxConstraints.tight(Size(700.px, 550.px)),
                                              title: const Text('fournselect').tr(),
                                              style: ContentDialogThemeData(
                                                  titleStyle: appTheme.writingStyle
                                                      .copyWith(fontWeight: FontWeight.bold)),
                                              content: const FournisseurTable(
                                                selectD: true,
                                              ),
                                              actions: [
                                                Button(
                                                    child: const Text('fermer').tr(),
                                                    onPressed: () {
                                                      selectedF = null;
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
                    crossAxisCellCount: 2,
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
                                    updateQteRestant();
              
                                  },
                                  min: 0,
                                )
                                :NumberBox<double>(value: qte, onChanged: (s){
                                  setState(() {
                                    qte=s??0;
                                  });
                                  updateQteRestant();
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
                      crossAxisCellCount: 4,
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
                                        selected: expirationDate,
                                        onChanged: (d){
                                          expirationDate=d;
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
              ),],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: appTheme.backGroundColor,
            boxShadow: kElevationToShadow[2],),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: confirmUpload,
                child: const Text('confirmer').tr(),
              ),
            ],),),
      ],
    );
  }

  Widget variationsWidget(AppTheme appTheme, bool portrait) {
    return StaggeredGridTile.fit(
        crossAxisCellCount: 6,
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

  List<StorageVariation> variations = List.empty(growable: true);

  double qteRestant=1;
  void addDesignation() {
    variations.add(
        StorageVariation(
            id: variations.isEmpty
                ? '1'
                : (int.parse(variations.last.id) + 1).toString(),
            name: '',
            sku: 'XXXX',
            qte: 1));
    updateQteRestant();
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
                    onPressed: qteRestant>0?addDesignation:null, child: const Text('add').tr()),
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
              columnWidths:
              differentDate?
              {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(5),
                2: FlexColumnWidth(3),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(3),
              }
              :const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(5),
                2: FlexColumnWidth(3),
            3: FlexColumnWidth(3),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(3),

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
                  if(differentDate)
                  TableCell(
                      child: const Text(
                        'dateexp',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'prix',
                        textAlign: TextAlign.center,
                      ).tr()),
                  TableCell(
                      child: const Text(
                        'qte',
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
    List<StorageVariation> temp = List.from(variations);
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].selected) {
        variations.remove(temp[i]);
      }
    }
    updateQteRestant();
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
                        variations[index].selected=s??false;
                      });
                    }),
                smallSpace,
                Flexible(
                  child: SizedBox(
                    height: 35.px,
                    child: VariationStorageWidget(
                        differentDate: differentDate,
                        key: Key(variations[index].id),
                        expirationDate: expirationDate,
                        part: selectedPart!,
                        variation: variations[index],
                        onQteChanged: (s){
                          variations[index].qte=s;
                          updateQteRestant();
                        },
                       onDateChanged: (d){
                          variations[index].expirationDate=d;
                       },
                      onOptionsChanged: (s){
                          variations[index].optionValues=s;
                      }, maxQte: qteRestant,

                    ),
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

  void updateQteRestant(){
    qteRestant=qte;
    for(int i=0;i<variations.length;i++){
      qteRestant-=variations[i].qte;
    }
    setState(() {

    });
  }

  void confirmUpload() async{

    if(selectedPart==null){
      return;
    }
    if(qte<=0){
      return;
    }

    for(int i=0;i<variations.length;i++){
      if(variations[i].qte<=0){
        return;
      }
    }
  }


}
