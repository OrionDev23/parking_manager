import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/entreprise.dart';
import 'package:parc_oto/screens/prestataire/prestataire_table.dart';
import 'package:parc_oto/screens/reparation/reparation_form/designation_reparation.dart';
import 'package:parc_oto/screens/reparation/reparation_form/entreprise_placement.dart';
import 'package:parc_oto/screens/reparation/reparation_form/entretien_widget.dart';
import 'package:parc_oto/screens/reparation/reparation_form/vehicle_damage.dart';
import 'package:parc_oto/widgets/big_title_form.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicles_table.dart';
import 'package:parc_oto/serializables/etat_vehicle.dart';
import 'package:parc_oto/serializables/prestataire.dart';
import 'package:parc_oto/serializables/vehicle.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../pdf_generation/reparation_pdf.dart';
import '../../serializables/designation.dart';
import '../../serializables/entretien_vehicle.dart';
import '../../serializables/reparation.dart';
import '../../utilities/vehicle_util.dart';
import '../../widgets/empty_table_widget.dart';

class ReparationForm extends StatefulWidget {

  final Reparation? reparation;
  const ReparationForm({required super.key, this.reparation});

  @override
  State<ReparationForm> createState() => ReparationFormState();
}

class ReparationFormState extends State<ReparationForm>
    with AutomaticKeepAliveClientMixin<ReparationForm> {
  static Map<Key, int> reservedOrders = {};

  EntretienVehicle entretienVehicle = EntretienVehicle();
  EtatVehicle etatVehicle = EtatVehicle();

  TextEditingController numOrdre = TextEditingController();
  DateTime selectedDate = DateTime.now();

  Prestataire? selectedPrest;
  Vehicle? selectedVehicle;
  TextEditingController marque = TextEditingController();
  TextEditingController type = TextEditingController();
  TextEditingController matricule = TextEditingController();
  TextEditingController km = TextEditingController();
  TextEditingController couleur = TextEditingController();

  TextEditingController nchassi = TextEditingController();
  TextEditingController nmoteur = TextEditingController();
  DateTime anneeUtil = DateTime.now();

  double carburant = 4;

  TextEditingController remarqueEntretien = TextEditingController();

  @override
  void initState() {
    if(widget.reparation!=null){
      initValues();
    }
    else{
      assignOrderNumber();

    }
    super.initState();
  }

  void initValues() async{
    if(widget.reparation!=null){
        assigningOrederNumber=true;
      etatVehicle=widget.reparation!.etatActuel??EtatVehicle();
      entretienVehicle=widget.reparation!.entretien??EntretienVehicle();
      remarqueEntretien.text=widget.reparation!.remarque??'';
      numOrdre.text=widget.reparation!.numero.toString();
      reservedOrders[widget.key!]=widget.reparation!.numero;
      await Future.wait([getPrestatataire(),getVehicle()]);
      matricule.text=widget.reparation!.vehiculemat??'';
      couleur.text=widget.reparation!.couleur??'';
      type.text=widget.reparation!.modele??'';
      nchassi.text=widget.reparation!.nchassi??'';
      nmoteur.text=widget.reparation!.nmoteur??'';
      km.text=widget.reparation!.kilometrage?.toString()??'0';
      carburant=widget.reparation!.gaz?.toDouble()??4;
      selectedDate=widget.reparation!.date;
      anneeUtil=DateTime(widget.reparation!.anneeUtil??selectedVehicle?.anneeUtil??DateTime.now().year);
      designations=List.generate(widget.reparation!.designations?.length??0, (index) {
        return DesignationReparation(key:UniqueKey(),designation: widget.reparation!.designations![index]);
      });
      setState(() {
        assigningOrederNumber=false;
      });

    }
  }

  Future<void> getPrestatataire() async{
    if(widget.reparation!=null && widget.reparation!.prestataire!=null){
      selectedPrest=await ClientDatabase().getPrestataire(widget.reparation!.prestataire!);
    }
  }
  Future<void> getVehicle() async{
    if(widget.reparation!=null && widget.reparation!.vehicule!=null){
      selectedVehicle=await ClientDatabase().getVehicle(widget.reparation!.vehicule!);
    }
  }

  bool assigningOrederNumber = false;

  bool errorNumOrder = false;
  void assignOrderNumber() async {
    assigningOrederNumber = true;
    if (mounted) {
      setState(() {});
    }
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: reparationId,
        queries: [
          Query.orderDesc('numero'),
          Query.limit(1),
        ]).then((value) {
      if (value.documents.length == 1) {
        numOrdre.text = (value.documents[0]
            .convertTo((p0) => Reparation.fromJson(p0 as Map<String, dynamic>))
            .numero+1)
            .toString();
      } else {
        numOrdre.text = (reservedOrders.length + 1).toString();
      }

      while (testIfReservedContained(int.parse(numOrdre.text))) {
        numOrdre.text = (int.parse(numOrdre.text) + 1).toString();
      }
      reservedOrders[widget.key!] = (int.parse(numOrdre.text));
    });

    assigningOrederNumber = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> testIfOrderNumberExists() async {

    bool result=false;

    if (testIfReservedContained(int.parse(numOrdre.text))) {
      setState(() {
        errorNumOrder = true;
      });
      result=true;
    }
    else{
      result= await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: reparationId,
          queries: [
            Query.orderDesc('numero'),
            Query.equal('numero', int.parse(numOrdre.text)),
            Query.limit(1),
          ]).then((value) {
        if (value.documents.length == 1) {
          setState(() {
            errorNumOrder = true;
          });
          return true;
        } else {
          setState(() {
            errorNumOrder=false;

          });
         return false;
        }
      }).onError((error, stackTrace) {return Future.value(false);});

    }


    return result;
  }

  bool testIfReservedContained(int value) {
    bool result = false;
    reservedOrders.forEach((key, v) {
      if (value == v && key != widget.key) {
        result = true;
        return;
      }
    });

    return result;
  }

  void setVehicleValues() {
    if (selectedVehicle == null) {
      marque.clear();
      type.clear();
      nchassi.clear();
      matricule.clear();
    } else {
      marque.text = VehiclesUtilities.getMarqueName(selectedVehicle!.marque);
      type.text = selectedVehicle!.type ?? '';
      nchassi.text = selectedVehicle!.numeroSerie ?? '';
      matricule.text = selectedVehicle!.matricule;
      anneeUtil = DateTime(selectedVehicle!.anneeUtil ?? 2023);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      content: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  children: [
                    if (MyEntrepriseState.p != null)
                      const EntreprisePlacement(),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (errorNumOrder)
                          Text(
                            'numprorder',
                            style: TextStyle(color: Colors.red),
                          ).tr(),
                        if (errorNumOrder) smallSpace,
                        Row(
                          children: [
                            Text(
                              'ORDRE DE REPARATION',
                              style: headerStyle,
                            ),
                            smallSpace,
                            Container(
                              width: 200.px,
                              height: 40.px,
                              decoration: BoxDecoration(
                                border: Border.all(),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'num',
                                      style: boldStyle,
                                    ).tr(),
                                    smallSpace,
                                    Flexible(
                                      child: TextBox(
                                        controller: numOrdre,
                                        enabled: widget.reparation==null,
                                        placeholder: 'num'.tr(),
                                        placeholderStyle: placeStyle,
                                        style: appTheme.writingStyle,
                                        cursorColor: appTheme.color.darker,
                                        decoration: BoxDecoration(
                                          color: appTheme.fillColor,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onChanged: (s) async {
                                          if (s.isNotEmpty) {
                                            if (!await testIfOrderNumberExists()) {
                                              reservedOrders[widget.key!] =
                                                  int.parse(s);
                                              setState(() {

                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'date',
                      style: boldStyle,
                    ).tr(),
                    smallSpace,
                    SizedBox(
                      width: 200.px,
                      height: 30.px,
                      child: DatePicker(
                        selected: selectedDate,
                        onChanged: (s) {
                          setState(() {
                            selectedDate = s;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 250.px,
                      height: 50.px,
                      child: ListTile(
                        leading: Text(
                          'vehicule',
                          style: boldStyle,
                        ).tr(),
                        title:
                            Text(selectedVehicle?.matricule ?? 'nonind'.tr()),
                        onPressed: () async {
                          selectedVehicle = await showDialog<Vehicle?>(
                              context: context,
                              builder: (
                                c,
                              ) =>
                                  Container(
                                    decoration: BoxDecoration(
                                      color: appTheme.backGroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: const VehicleTable(
                                      selectV: true,
                                    ),
                                  ));
                          setVehicleValues();
                        },
                      ),
                    ),
                    smallSpace,
                    if (selectedVehicle != null)
                      IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () {
                            selectedVehicle = null;
                            setVehicleValues();
                          }),
                    const Spacer(),
                    SizedBox(
                      width: 250.px,
                      height: 50.px,
                      child: ListTile(
                        leading: Text(
                          'prestataire',
                          style: boldStyle,
                        ).tr(),
                        title: Text(selectedPrest?.nom ?? 'nonind'.tr()),
                        onPressed: () async {
                          selectedPrest = await showDialog<Prestataire?>(
                              context: context,
                              builder: (
                                c,
                              ) =>
                                  Container(
                                    decoration: BoxDecoration(
                                      color: appTheme.backGroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: const PrestataireTable(
                                      selectD: true,
                                    ),
                                  ));
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                buildTable(appTheme),
                smallSpace,
                const BigTitleForm(
                  bigTitle: 'etatvehicule',
                  littleTitle: 'selectetat',
                ),
                VehicleDamage(etatVehicle: etatVehicle),
                smallSpace,
                const BigTitleForm(
                  bigTitle: 'entretienvehicule',
                  littleTitle: 'selectentretien',
                ),
                Container(
                  height: 170.px,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: Row(
                    children: [
                      EntretienWidget(entretienVehicle: entretienVehicle),
                      bigSpace,
                      Flexible(
                        child: ZoneBox(
                          label: 'remarqueplus'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextBox(
                              controller: remarqueEntretien,
                              placeholder: 'remarqueplus'.tr(),
                              maxLines: 4,
                              placeholderStyle: placeStyle,
                              style: appTheme.writingStyle,
                              cursorColor: appTheme.color.darker,
                              decoration: BoxDecoration(
                                color: appTheme.fillColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                smallSpace,
                const BigTitleForm(
                  bigTitle: 'travaileffect',
                  littleTitle: 'ajoutertaches',
                ),
                designationTable(appTheme),
              ],
            ),
          ),
          if (assigningOrederNumber)
            Positioned(
              top: 40.h,
              left: 40.w,
              child: const ProgressBar(),
            )
        ]),
      ),
      bottomBar: Container(
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(appTheme.color.lightest),
                ),
                onPressed: uploading ? null : showPdf,
                child: const Text('voir')),
            smallSpace,
            FilledButton(
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(appTheme.color.darkest),
                ),
                onPressed: uploading ? null : uploadForm,
                child: const Text('save').tr())
          ],
        ),
      ),
    );
  }

  Table buildTable(AppTheme appTheme) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      border: TableBorder.all(),
      columnWidths: {
        0: FixedColumnWidth(80.px),
        1: FixedColumnWidth(80.px),
        2: FixedColumnWidth(80.px),
        3: FixedColumnWidth(80.px),
      },
      children: [
        TableRow(children: [
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'marque',
                  style: littleStyle,
                ).tr(),
                const Spacer(),
                SizedBox(
                  width: 160.px,
                  child: TextBox(
                    controller: marque,
                    placeholder: 'marque'.tr(),
                    style: appTheme.writingStyle,
                    decoration: BoxDecoration(
                      color: appTheme.fillColor,
                    ),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'type',
                  style: littleStyle,
                ).tr(),
                const Spacer(),
                SizedBox(
                  width: 160.px,
                  child: TextBox(
                    controller: type,
                    placeholder: 'type'.tr(),
                    style: appTheme.writingStyle,
                    decoration: BoxDecoration(
                      color: appTheme.fillColor,
                    ),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'nchassi',
                  style: littleStyle,
                ).tr(),
                smallSpace,
                Flexible(
                  child: TextBox(
                    controller: nchassi,
                    placeholder: 'nchassi'.tr(),
                    style: appTheme.writingStyle,
                    decoration: BoxDecoration(
                      color: appTheme.fillColor,
                    ),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'matricule',
                  style: littleStyle,
                ).tr(),
                smallSpace,
                Flexible(
                  child: TextBox(
                    controller: matricule,
                    enabled: selectedVehicle == null,
                    //readOnly: selectedVehicle!=null,
                    placeholder: 'matricule'.tr(),
                    style: appTheme.writingStyle,
                    decoration: BoxDecoration(
                      color: appTheme.fillColor,
                    ),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
        ]),
        TableRow(children: [
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'nmoteur',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: nmoteur,
                            placeholder: 'nmoteur'.tr(),
                            style: appTheme.writingStyle,
                            decoration: BoxDecoration(
                              color: appTheme.fillColor,
                            ),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.px,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'KM',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: km,
                            placeholder: 'KM'.tr(),
                            style: appTheme.writingStyle,
                            decoration: BoxDecoration(
                              color: appTheme.fillColor,
                            ),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
                height: 120.px,
                width: 180.px,
                child: SfRadialGauge(
                  animationDuration: 500,
                  title: GaugeTitle(
                    text: 'carburant'.tr(),
                    textStyle: littleStyle,
                    alignment: GaugeAlignment.near,
                  ),
                  axes: [
                    RadialAxis(
                      canScaleToFit: true,
                      minimum: 0,
                      maximum: 8,
                      radiusFactor: 1,
                      onAxisTapped: (s) {
                        setState(() {
                          carburant = s;
                        });
                      },
                      ranges: [
                        GaugeRange(
                          startValue: 0,
                          endValue: 0.5,
                          label: 'E',
                          color: appTheme.color.darkest,
                        ),
                        GaugeRange(
                          startValue: 7.5,
                          endValue: 8,
                          label: 'F',
                          color: appTheme.color.lightest,
                        ),
                      ],
                      annotations: [
                        GaugeAnnotation(
                          widget: Text(
                            '4/8',
                            style: littleStyle,
                          ),
                          axisValue: 4,
                          positionFactor: 0.7,
                        ),
                      ],
                      pointers: [
                        NeedlePointer(
                          animationDuration: 500,
                          needleLength: 0.4,
                          needleColor: appTheme.color,
                          needleStartWidth: 1.px,
                          needleEndWidth: 5.px,
                          knobStyle: KnobStyle(color: appTheme.color.darkest),
                          value: carburant,
                          enableAnimation: true,
                          enableDragging: true,
                        ),
                      ],
                      interval: 2,
                      startAngle: 180,
                      showFirstLabel: false,
                      showLastLabel: false,
                      showLabels: false,
                      endAngle: 360,
                    )
                  ],
                )),
          )),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'color',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: couleur,
                            placeholder: 'color'.tr(),
                            style: appTheme.writingStyle,
                            decoration: BoxDecoration(
                              color: appTheme.fillColor,
                            ),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.px,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'anneeutil',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                            width: 80.px,
                            child: DatePicker(
                              selected: anneeUtil,
                              showDay: false,
                              showMonth: false,
                            ))
                      ],
                    ),
                  ),
                ],
              )),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.top,
              child: Column(
                children: [
                  SizedBox(
                    height: 16.px,
                  ),
                ],
              )),
        ]),
      ],
    );
  }

  @override
  void dispose() {
    reservedOrders.remove(widget.key);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<DesignationReparation> designations = List.empty(growable: true);

  void addDesignation() {
    designations.add(DesignationReparation(
        key: UniqueKey(), designation: Designation(designation: '')));
    setState(() {});
  }

  Widget designationTable(AppTheme appTheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
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
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              children: [
                TableRow(children: [
                  TableCell(
                      child: const Text(
                    'desi',
                    textAlign: TextAlign.center,
                  ).tr()),
                  TableCell(
                      child: const Text(
                    'qte',
                    textAlign: TextAlign.center,
                  ).tr()),
                  TableCell(
                      child: const Text(
                    'TVA',
                    textAlign: TextAlign.center,
                  ).tr()),
                  TableCell(
                      child: const Text(
                    'prix',
                    textAlign: TextAlign.center,
                  ).tr()),
                ]),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: appTheme.fillColor),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(5)),
            ),
            child: designations.isEmpty
                ? const NoDataWidget()
                : Column(children: getDesignationList(appTheme)),
          ),
        ],
      ),
    );
  }

  bool selectedDesignationsExist() {
    for (int i = 0; i < designations.length; i++) {
      if (designations[i].designation.selected) {
        return true;
      }
    }
    return false;
  }

  void deleteAllSelected() {
    List<DesignationReparation> temp = List.from(designations);
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].designation.selected) {
        designations.remove(temp[i]);
      }
    }
    setState(() {});
  }

  List<Widget> getDesignationList(AppTheme appTheme) {
    return List.generate(designations.length, (index) {
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
                    checked: designations[index].designation.selected,
                    onChanged: (s) {
                      setState(() {
                        designations[index].designation.selected = s ?? false;
                      });
                    }),
                smallSpace,
                Flexible(
                  child: SizedBox(
                    height: 35.px,
                    child: designations[index],
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


  String? documentID;

  bool uploading = false;

  void showPdf(){
    Reparation reparation = Reparation(
      id: '',
      numero: int.parse(numOrdre.text),
      date: selectedDate,
      anneeUtil: anneeUtil.year,
      couleur: couleur.text,
      designations: designations.map((e) => e.designation).toList(),
      entretien: entretienVehicle,
      etatActuel: etatVehicle,
      gaz: carburant.ceil(),
      kilometrage: int.tryParse(km.text),
      modele: type.text,
      nchassi: nchassi.text,
      nmoteur: nmoteur.text,
      prestataire: selectedPrest?.id,
      prestatairenom: selectedPrest?.nom,
      vehicule: selectedVehicle?.id,
      vehiculemat: selectedVehicle?.matricule,
      remarque: remarqueEntretien.text,
    );

    showDialog(context: context, builder: (context){

      return PdfPreview(
        build: (PdfPageFormat format) {
          return ReparationPdf(reparation: reparation).getDocument();
        },
      );
    });
  }
  void uploadForm() async {
    setState(() {
      uploading = true;
    });
    bool modif=documentID!=null;
    documentID ??= DateTime.now()
        .difference(ClientDatabase.ref)
        .inMilliseconds
        .abs()
        .toString();
    Reparation reparation = Reparation(
      id: documentID!,
      numero: int.parse(numOrdre.text),
      date: selectedDate,
      anneeUtil: anneeUtil.year,
      couleur: couleur.text,
      designations: designations.map((e) => e.designation).toList(),
      entretien: entretienVehicle,
      etatActuel: etatVehicle,
      gaz: carburant.ceil(),
      kilometrage: int.tryParse(km.text),
      modele: type.text,
      nchassi: nchassi.text,
      nmoteur: nmoteur.text,
      prestataire: selectedPrest?.id,
      prestatairenom: selectedPrest?.nom,
      vehicule: selectedVehicle?.id,
      vehiculemat: selectedVehicle?.matricule,
      remarque: remarqueEntretien.text,
    );

    if (!modif)
    {


      await ClientDatabase.database!.createDocument(
          databaseId: databaseId,
          collectionId: reparationId,
          documentId: documentID!,
          data: reparation.toJson());
    }
    else {
      await ClientDatabase.database!.updateDocument(
          databaseId: databaseId,
          collectionId: reparationId,
          documentId: documentID!,
          data: reparation.toJson());
    }

    uploading = false;

    if (mounted) {
      setState(() {});
    }
  }
}
