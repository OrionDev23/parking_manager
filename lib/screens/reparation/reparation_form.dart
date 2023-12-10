import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/entreprise.dart';
import 'package:parc_oto/screens/prestataire/prestataire_table.dart';
import 'package:parc_oto/screens/reparation/reparation_form/entreprise_placement.dart';
import 'package:parc_oto/screens/reparation/reparation_form/vehicle_damage.dart';
import 'package:parc_oto/widgets/big_title_form.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicles_table.dart';
import 'package:parc_oto/serializables/etat_vehicle.dart';
import 'package:parc_oto/serializables/prestataire.dart';
import 'package:parc_oto/serializables/vehicle.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../serializables/entretien_vehicle.dart';
import '../../serializables/reparation.dart';
import '../../utilities/vehicle_util.dart';

class ReparationForm extends StatefulWidget {
  const ReparationForm({required super.key});

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
    assignOrderNumber();
    super.initState();
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
        numOrdre.text = value.documents[0]
            .convertTo((p0) => Reparation.fromJson(p0 as Map<String, dynamic>))
            .numero
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
    await ClientDatabase.database!.listDocuments(
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
        if (testIfReservedContained(int.parse(numOrdre.text))) {
          setState(() {
            errorNumOrder = true;
          });
          return true;
        } else {
          setState(() {
            errorNumOrder = false;
          });
          return false;
        }
      }
    });

    if (testIfReservedContained(int.parse(numOrdre.text))) {
      setState(() {
        errorNumOrder = true;
      });
      return true;
    } else {
      setState(() {
        errorNumOrder = false;
      });
      return false;
    }
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
    return Container(
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
                  if (MyEntrepriseState.p != null) const EntreprisePlacement(),
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
                      title: Text(selectedVehicle?.matricule ?? 'nonind'.tr()),
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
              entretienWidgets(appTheme),
              smallSpace,
              const BigTitleForm(
                bigTitle: 'travaileffect',
                littleTitle: 'ajoutertaches',
              ),
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

  Widget entretienWidgets(AppTheme appTheme) {
    return Container(
      height: 170.px,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          bigSpace,
          bigSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  'Vidange moteur',
                  style: littleStyle,
                ),
                checked: entretienVehicle.vidangeMoteur,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.vidangeMoteur = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Vidange boite',
                  style: littleStyle,
                ),
                checked: entretienVehicle.vidangeBoite,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.vidangeBoite = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Vidange pont AV AR',
                  style: littleStyle,
                ),
                checked: entretienVehicle.vidangePont,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.vidangePont = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à air',
                  style: littleStyle,
                ),
                checked: entretienVehicle.filtreAir,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.filtreAir = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à huile',
                  style: littleStyle,
                ),
                checked: entretienVehicle.filtreHuile,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.filtreHuile = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à carburant',
                  style: littleStyle,
                ),
                checked: entretienVehicle.filtreCarburant,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.filtreCarburant = s;
                  });
                },
              ),
            ],
          ),
          smallSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  "Filtre d'habitacle",
                  style: littleStyle,
                ),
                checked: entretienVehicle.filtreHabitacle,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.filtreHabitacle = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Liquide de frein',
                  style: littleStyle,
                ),
                checked: entretienVehicle.liquideFrein,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.liquideFrein = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Liquide de refroidissement',
                  style: littleStyle,
                ),
                checked: entretienVehicle.liquideRefroidissement,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.liquideRefroidissement = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Equilibrage roues',
                  style: littleStyle,
                ),
                checked: entretienVehicle.equilibrageRoues,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.equilibrageRoues = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Controle niveaux',
                  style: littleStyle,
                ),
                checked: entretienVehicle.controleNiveaux,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.controleNiveaux = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Entretien climatisation',
                  style: littleStyle,
                ),
                checked: entretienVehicle.entretienClimatiseur,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.entretienClimatiseur = s;
                  });
                },
              ),
            ],
          ),
          smallSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  'Balais essuie-glace',
                  style: littleStyle,
                ),
                checked: entretienVehicle.balaisEssuieGlace,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.balaisEssuieGlace = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Eclairage',
                  style: littleStyle,
                ),
                checked: entretienVehicle.eclairage,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.eclairage = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'OBD',
                  style: littleStyle,
                ),
                checked: entretienVehicle.obd,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.obd = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Bougies',
                  style: littleStyle,
                ),
                checked: entretienVehicle.bougies,
                onChanged: (s) {
                  setState(() {
                    entretienVehicle.bougies = s;
                  });
                },
              ),
              bigSpace,
              smallSpace,
              Row(
                children: [
                  Button(
                      onPressed: () => selectAllEntretien(false),
                      child: const Text('clear').tr()),
                  smallSpace,
                  FilledButton(
                      onPressed: () => selectAllEntretien(true),
                      child: const Text('selectall').tr()),
                ],
              ),
            ],
          ),
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
    );
  }

  void selectAllEntretien(bool value) {
    entretienVehicle.vidangeMoteur = value;
    entretienVehicle.vidangeBoite = value;
    entretienVehicle.vidangePont = value;
    entretienVehicle.filtreAir = value;
    entretienVehicle.filtreHuile = value;
    entretienVehicle.filtreCarburant = value;
    entretienVehicle.filtreHabitacle = value;
    entretienVehicle.liquideFrein = value;
    entretienVehicle.liquideRefroidissement = value;
    entretienVehicle.equilibrageRoues = value;
    entretienVehicle.controleNiveaux = value;
    entretienVehicle.entretienClimatiseur = value;
    entretienVehicle.balaisEssuieGlace = value;
    entretienVehicle.eclairage = value;
    entretienVehicle.obd = value;
    entretienVehicle.bougies = value;
    setState(() {});
  }

  @override
  void dispose() {
    reservedOrders.remove(widget.key);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
