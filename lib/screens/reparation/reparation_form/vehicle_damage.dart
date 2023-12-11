import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/etat_vehicle.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../../widgets/on_tap_scale.dart';

class VehicleDamage extends StatefulWidget {
  final EtatVehicle etatVehicle;
  const VehicleDamage({super.key, required this.etatVehicle});

  @override
  State<VehicleDamage> createState() => _VehicleDamageState();
}

class _VehicleDamageState extends State<VehicleDamage> {
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      width: 80.w,
      height: 45.h,
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          topTable(appTheme),
          bigSpace,
          bigSpace,
          bigSpace,
          bigSpace,
          bigSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 90.px,
              height: 40.px,
              child: Row(
                children: [
                  const Text(
                    "repare",
                  ).tr(),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.showOnList,
                      onChanged: (s) {
                        widget.etatVehicle.showOnList=s??false;
                        setState(() {});
                      })
                ],
              ),
            ),
            vehicleDamage(appTheme),
            bigSpace,
            Row(children: [
              Button(
                  onPressed:()=> selectAllVehicleDamage(false), child: const Text('clear').tr()),
              smallSpace,
              FilledButton(
                  onPressed:()=> selectAllVehicleDamage(true),
                  child: const Text('selectall').tr()),
            ]),
          ]),
        ],
      ),
    );
  }


  void selectAllVehicleDamage(bool value) {
    widget.etatVehicle.avdp = value?0:100;
    widget.etatVehicle.avgp = value?0:100;
    widget.etatVehicle.ardp = value?0:100;
    widget.etatVehicle.argp = value?0:100;
    if(!value){
      widget.etatVehicle.parBriseAvf = value;
      widget.etatVehicle.parBriseAvc = value;
      widget.etatVehicle.parBriseArf = value;
      widget.etatVehicle.parBriseArc = value;
    }

    widget.etatVehicle.parBriseAve = value;

    widget.etatVehicle.parBriseAre = value;
    widget.etatVehicle.phareG = value;
    widget.etatVehicle.phareD = value;
    widget.etatVehicle.feuAVD = value;
    widget.etatVehicle.feuAVG = value;
    widget.etatVehicle.feuARD = value;
    widget.etatVehicle.feuARG = value;
    widget.etatVehicle.aileAVD = value;
    widget.etatVehicle.aileAVG = value;
    widget.etatVehicle.aileARD = value;
    widget.etatVehicle.aileARG = value;
    widget.etatVehicle.pareChocAV = value;
    widget.etatVehicle.pareChocAR = value;
    widget.etatVehicle.porteAVD = value;
    widget.etatVehicle.porteAVG = value;
    widget.etatVehicle.porteARD = value;
    widget.etatVehicle.porteARG = value;
    widget.etatVehicle.toit = value;
    widget.etatVehicle.capot = value;
    widget.etatVehicle.coffre = value;
    widget.etatVehicle.siegeAVD = value;
    widget.etatVehicle.siegeAVG = value;
    widget.etatVehicle.siegeARD = value;
    widget.etatVehicle.siegeARG = value;
    widget.etatVehicle.calandre = value;
    setState(() {});
  }

  Widget topTable(AppTheme appTheme) {
    return SizedBox(
      width: 40.w,
      height: 45.h,
      child: Table(
        border: TableBorder.all(
          borderRadius: BorderRadius.circular(5)
        ),
        columnWidths: {
          0: FixedColumnWidth(6.w),
          1: FixedColumnWidth(6.w),
          2: FixedColumnWidth(4.w),
          3: FixedColumnWidth(4.w),
          4: FixedColumnWidth(11.w),
        },
        children: [
          ...getTopRow(appTheme),
          ...getBottomRows(appTheme),
        ],
      ),
    );
  }

  List<TableRow> getTopRow(AppTheme appTheme) {
    return [
      TableRow(children: [
        TableCell(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(5)),
                color: appTheme.color.lightest,
              ),
              padding: const EdgeInsets.all(5.0),
              child: Text('PARE-BRISE AV', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PARE-BRISE AR', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PHARE', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('FEUX', style: littleStyle),
            )),
        TableCell(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(5)),
                color: appTheme.color.lightest,
              ),
              padding: const EdgeInsets.all(5.0),
              child: Text('PNEUMATIQUE', style: littleStyle),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'FELURE',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.parBriseAvf,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.parBriseAvf = s!;
                          widget.etatVehicle.parBriseAvc = false;
                          widget.etatVehicle.parBriseAve = false;
                        } else if (s == false) {
                          widget.etatVehicle.parBriseAvf = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'FELURE',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.parBriseArf,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.parBriseArf = s!;
                          widget.etatVehicle.parBriseArc = false;
                          widget.etatVehicle.parBriseAre = false;
                        } else if (s == false) {
                          widget.etatVehicle.parBriseArf = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'D',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.phareD,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.phareD = s!;
                        } else if (s == false) {
                          widget.etatVehicle.phareD = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.feuAVD,
                      onChanged: (s) {
                        widget.etatVehicle.feuAVD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'AVD',
                    style: littleStyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: widget.etatVehicle.avdp,
                      onChanged: (s) {
                        widget.etatVehicle.avdp = s;
                        setState(() {});
                      },
                      divisions: 100,
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${widget.etatVehicle.avdp.ceil()} %',
                    style: littleStyle,
                  ),
                ],
              ),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'CASSURE',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.parBriseAvc,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.parBriseAvf = false;
                          widget.etatVehicle.parBriseAvc = s!;
                          widget.etatVehicle.parBriseAve = false;
                        } else if (s == false) {
                          widget.etatVehicle.parBriseAvc = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'CASSURE',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.parBriseArc,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.parBriseArc = s!;
                          widget.etatVehicle.parBriseArf = false;
                          widget.etatVehicle.parBriseAre = false;
                        } else if (s == false) {
                          widget.etatVehicle.parBriseArc = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'G',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.phareG,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.phareG = s!;
                        } else if (s == false) {
                          widget.etatVehicle.phareG = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.feuAVG,
                      onChanged: (s) {
                        widget.etatVehicle.feuAVG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: littleStyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: widget.etatVehicle.avgp,
                      onChanged: (s) {
                        widget.etatVehicle.avgp = s;
                        setState(() {});
                      },
                      divisions: 100,
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${widget.etatVehicle.avgp.ceil()} %',
                    style: littleStyle,
                  ),
                ],
              ),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ECLAT',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.parBriseAve,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.parBriseAve = s!;
                          widget.etatVehicle.parBriseAvc = false;
                          widget.etatVehicle.parBriseAvf = false;
                        } else if (s == false) {
                          widget.etatVehicle.parBriseAve = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ECLAT',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.parBriseAre,
                      onChanged: (s) {
                        if (s == true) {
                          widget.etatVehicle.parBriseAre = s!;
                          widget.etatVehicle.parBriseArf = false;
                          widget.etatVehicle.parBriseArc = false;
                        } else if (s == false) {
                          widget.etatVehicle.parBriseAre = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        const TableCell(
          child: SizedBox(),
        ),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.feuARD,
                      onChanged: (s) {
                        widget.etatVehicle.feuARD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: littleStyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: widget.etatVehicle.ardp,
                      onChanged: (s) {
                        widget.etatVehicle.ardp = s;
                        setState(() {});
                      },
                      divisions: 100,
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${widget.etatVehicle.ardp.ceil()} %',
                    style: littleStyle,
                  ),
                ],
              ),
            )),
      ]),
      TableRow(children: [
        const TableCell(child: SizedBox()),
        const TableCell(child: SizedBox()),
        const TableCell(
          child: SizedBox(),
        ),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.feuARG,
                      onChanged: (s) {
                        widget.etatVehicle.feuARG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: littleStyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: widget.etatVehicle.argp,
                      onChanged: (s) {
                        widget.etatVehicle.argp = s;
                        setState(() {});
                      },
                      divisions: 100,
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${widget.etatVehicle.ardp.ceil()} %',
                    style: littleStyle,
                  ),
                ],
              ),
            )),
      ]),
    ];
  }

  List<TableRow> getBottomRows(AppTheme appTheme) {
    return [
      TableRow(children: [
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('AILE', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PARE-CHOC', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PORTE', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('SIEGE', style: littleStyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('AUTRE', style: littleStyle),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.aileAVD,
                      onChanged: (s) {
                        widget.etatVehicle.aileAVD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text('AV', style: littleStyle),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.pareChocAV,
                      onChanged: (s) {
                        setState(() {
                          widget.etatVehicle.pareChocAV = s ?? false;
                        });
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.porteAVD,
                      onChanged: (s) {
                        widget.etatVehicle.porteAVD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.siegeAVD,
                      onChanged: (s) {
                        widget.etatVehicle.siegeAVD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'CALANDRE',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.calandre,
                      onChanged: (s) {
                        widget.etatVehicle.calandre = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.aileAVG,
                      onChanged: (s) {
                        widget.etatVehicle.aileAVG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text('AR', style: littleStyle),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.pareChocAR,
                      onChanged: (s) {
                        setState(() {
                          widget.etatVehicle.pareChocAR = s ?? false;
                        });
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.porteAVG,
                      onChanged: (s) {
                        widget.etatVehicle.porteAVG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.siegeAVG,
                      onChanged: (s) {
                        widget.etatVehicle.siegeAVG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'CAPOT',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.capot,
                      onChanged: (s) {
                        widget.etatVehicle.capot = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.aileARD,
                      onChanged: (s) {
                        setState(() {
                          widget.etatVehicle.aileARD = s ?? false;
                        });
                      })
                ],
              ),
            )),
        const TableCell(child: SizedBox()),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.porteARD,
                      onChanged: (s) {
                        widget.etatVehicle.porteARD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.siegeARD,
                      onChanged: (s) {
                        widget.etatVehicle.siegeARD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'TOIT',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.toit,
                      onChanged: (s) {
                        widget.etatVehicle.toit = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
      ]),
      TableRow(children: [
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.aileARG,
                      onChanged: (s) {
                        setState(() {
                          widget.etatVehicle.aileARG = s ?? false;
                        });
                      })
                ],
              ),
            )),
        const TableCell(child: SizedBox()),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.porteARG,
                      onChanged: (s) {
                        widget.etatVehicle.porteARG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.siegeARG,
                      onChanged: (s) {
                        widget.etatVehicle.siegeARG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'COFFRE',
                    style: littleStyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: widget.etatVehicle.coffre,
                      onChanged: (s) {
                        widget.etatVehicle.coffre = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
      ]),
    ];
  }

  double lightHeight = 25.px;
  double lightWidth = 25.px;
  Widget vehicleDamage(AppTheme appTheme) {
    return SizedBox(
      width: 317.px,
      height: 148.px,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ///image
          Positioned.fill(
              left: 10.px,
              right: 5.px,
              child: Image.asset('assets/images/car.webp',
                  fit: BoxFit.fitWidth, color: appTheme.writingStyle.color)),
          ...getFeux(appTheme),
          ...getAutres(appTheme),
          ...getSiegeEtPortes(appTheme),
          ...getPneumatiques(appTheme),
          ...getPareBrises(appTheme),
          ...getAiles(appTheme),
          ...getPareChocs(appTheme),
        ],
      ),
    );
  }

  List<Positioned> getAutres(AppTheme appTheme) {
    return [
      ///CALANDRE
      Positioned(
          left: 9.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.calandre ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.calandre = !widget.etatVehicle.calandre;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Capot
      Positioned(
          left: 50.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.capot ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.capot = !widget.etatVehicle.capot;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Toit
      Positioned(
          left: 160.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.toit ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.toit = !widget.etatVehicle.toit;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Coffre
      Positioned(
          left: 263.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.coffre ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.coffre = !widget.etatVehicle.coffre;
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getAiles(AppTheme appTheme) {
    return [
      ///Ailes AV
      Positioned(
          left: 3.px,
          top: 0.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.aileAVD == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.aileAVD = !widget.etatVehicle.aileAVD;
                    });
                  },
                ),
                SizedBox(
                  height: 92.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.aileAVG == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.aileAVG = !widget.etatVehicle.aileAVG;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Aile AR
      Positioned(
          left: 290.px,
          top: 0.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.aileARD == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.aileARD = !widget.etatVehicle.aileARD;
                    });
                  },
                ),
                SizedBox(
                  height: 95.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.aileARG == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.aileARG = !widget.etatVehicle.aileARG;
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getPareChocs(AppTheme appTheme) {
    return [
      ///Pare-choc AV
      Positioned(
          left: -2.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.pareChocAV ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.pareChocAV = !widget.etatVehicle.pareChocAV;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Pare-choc AR
      Positioned(
          left: 292.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.pareChocAR == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.pareChocAR = !widget.etatVehicle.pareChocAR;
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getSiegeEtPortes(AppTheme appTheme) {
    return [
      ///Portes avant
      Positioned(
          left: 130.px,
          top: 3.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.porteAVD ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.porteAVD = !widget.etatVehicle.porteAVD;
                    });
                  },
                ),
                SizedBox(
                  height: 90.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.porteAVG ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.porteAVG = !widget.etatVehicle.porteAVG;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Sieges avant
      Positioned(
          left: 130.px,
          top: 35.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.siegeAVD ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.siegeAVD = !widget.etatVehicle.siegeAVD;
                    });
                  },
                ),
                SizedBox(
                  height: 30.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.siegeAVG ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.siegeAVG = !widget.etatVehicle.siegeAVG;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Sieges arriere
      Positioned(
          left: 190.px,
          top: 35.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.siegeARD ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.siegeARD = !widget.etatVehicle.siegeARD;
                    });
                  },
                ),
                SizedBox(
                  height: 30.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.siegeARG ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.siegeARG = !widget.etatVehicle.siegeARG;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Portes arriere
      Positioned(
          left: 180.px,
          top: 3.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.porteARD ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.porteARD = !widget.etatVehicle.porteARD;
                    });
                  },
                ),
                SizedBox(
                  height: 90.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.porteARG ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.porteARG = !widget.etatVehicle.porteARG;
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getFeux(AppTheme appTheme) {
    return [
      ///Feux AV
      Positioned(
          left: 10.px,
          top: 23.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.feuAVD == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.feuAVD = !widget.etatVehicle.feuAVD;
                    });
                  },
                ),
                SizedBox(
                  height: 52.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.feuAVG == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.feuAVG = !widget.etatVehicle.feuAVG;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Phare
      Positioned(
          left: 19.px,
          top: 5.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.phareD == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.phareD = !widget.etatVehicle.phareD;
                    });
                  },
                ),
                SizedBox(
                  height: 85.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.phareG == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.phareG = !widget.etatVehicle.phareG;
                    });
                  },
                ),
              ],
            ),
          )),

      ///Feux AR
      Positioned(
          left: 286.px,
          top: 15.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.feuARD == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.feuARD = !widget.etatVehicle.feuARD;
                    });
                  },
                ),
                SizedBox(
                  height: 65.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient:
                      widget.etatVehicle.feuARG == true ? appTheme.getRadiantDarkest() : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.etatVehicle.feuARG = !widget.etatVehicle.feuARG;
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getPareBrises(AppTheme appTheme) {
    return [
      ///Pare-brise AV
      Positioned(
          left: 92.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: 4.75.w,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.parBriseAve
                          ? appTheme.getRadiantDarkest()
                          : widget.etatVehicle.parBriseAvc
                          ? appTheme.getRadiantStandard()
                          : widget.etatVehicle.parBriseAvf
                          ? appTheme.getRadiantLight()
                          : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (widget.etatVehicle.parBriseAvf) {
                        widget.etatVehicle.parBriseAvf = false;
                        widget.etatVehicle.parBriseAvc = true;
                        widget.etatVehicle.parBriseAve = false;
                      } else if (widget.etatVehicle.parBriseAvc) {
                        widget.etatVehicle.parBriseAvc = false;
                        widget.etatVehicle.parBriseAve = true;
                        widget.etatVehicle.parBriseAvf = false;
                      } else if (widget.etatVehicle.parBriseAve) {
                        widget.etatVehicle.parBriseAve = false;
                        widget.etatVehicle.parBriseAvf = false;
                        widget.etatVehicle.parBriseAvc = false;
                      } else {
                        widget.etatVehicle.parBriseAve = false;
                        widget.etatVehicle.parBriseAvf = true;
                        widget.etatVehicle.parBriseAvc = false;
                      }
                    });
                  },
                ),
              ],
            ),
          )),

      ///Pare-brise AR
      Positioned(
          left: 227.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: widget.etatVehicle.parBriseAre
                          ? appTheme.getRadiantDarkest()
                          : widget.etatVehicle.parBriseArc
                          ? appTheme.getRadiantStandard()
                          : widget.etatVehicle.parBriseArf
                          ? appTheme.getRadiantLight()
                          : null,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (widget.etatVehicle.parBriseArf) {
                        widget.etatVehicle.parBriseArf = false;
                        widget.etatVehicle.parBriseArc = true;
                        widget.etatVehicle.parBriseAre = false;
                      } else if (widget.etatVehicle.parBriseArc) {
                        widget.etatVehicle.parBriseArc = false;
                        widget.etatVehicle.parBriseAre = true;
                        widget.etatVehicle.parBriseArf = false;
                      } else if (widget.etatVehicle.parBriseAre) {
                        widget.etatVehicle.parBriseAre = false;
                        widget.etatVehicle.parBriseArf = false;
                        widget.etatVehicle.parBriseArc = false;
                      } else {
                        widget.etatVehicle.parBriseAre = false;
                        widget.etatVehicle.parBriseArf = true;
                        widget.etatVehicle.parBriseArc = false;
                      }
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getPneumatiques(AppTheme appTheme) {
    return [
      ///Roues avant
      Positioned(
          left: 54.px,
          top: -2.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: getLightIntensityFromPourc(widget.etatVehicle.avdp, appTheme),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (widget.etatVehicle.avdp <= 20) {
                        widget.etatVehicle.avdp = 30;
                      } else if (widget.etatVehicle.avdp <= 30) {
                        widget.etatVehicle.avdp = 50;
                      } else if (widget.etatVehicle.avdp <= 50) {
                        widget.etatVehicle.avdp = 60;
                      } else if (widget.etatVehicle.avdp <= 60) {
                        widget.etatVehicle.avdp = 80;
                      } else if (widget.etatVehicle.avdp <= 80) {
                        widget.etatVehicle.avdp = 90;
                      } else if (widget.etatVehicle.avdp <= 90) {
                        widget.etatVehicle.avdp = 100;
                      } else {
                        widget.etatVehicle.avdp = 20;
                      }
                    });
                  },
                ),
                SizedBox(
                  height: 100.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: getLightIntensityFromPourc(widget.etatVehicle.avgp, appTheme),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (widget.etatVehicle.avgp <= 20) {
                        widget.etatVehicle.avgp = 30;
                      } else if (widget.etatVehicle.avgp <= 30) {
                        widget.etatVehicle.avgp = 50;
                      } else if (widget.etatVehicle.avgp <= 50) {
                        widget.etatVehicle.avgp = 60;
                      } else if (widget.etatVehicle.avgp <= 60) {
                        widget.etatVehicle.avgp = 80;
                      } else if (widget.etatVehicle.avgp <= 80) {
                        widget.etatVehicle.avgp = 90;
                      } else if (widget.etatVehicle.avgp <= 90) {
                        widget.etatVehicle.avgp = 100;
                      } else {
                        widget.etatVehicle.avgp = 20;
                      }
                    });
                  },
                ),
              ],
            ),
          )),

      ///Roues arriere
      Positioned(
          left: 237.px,
          top: -2.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: getLightIntensityFromPourc(widget.etatVehicle.ardp, appTheme),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (widget.etatVehicle.ardp <= 20) {
                        widget.etatVehicle.ardp = 30;
                      } else if (widget.etatVehicle.ardp <= 30) {
                        widget.etatVehicle.ardp = 50;
                      } else if (widget.etatVehicle.ardp <= 50) {
                        widget.etatVehicle.ardp = 60;
                      } else if (widget.etatVehicle.ardp <= 60) {
                        widget.etatVehicle. ardp = 80;
                      } else if (widget.etatVehicle.ardp <= 80) {
                        widget.etatVehicle.ardp = 90;
                      } else if (widget.etatVehicle.ardp <= 90) {
                        widget.etatVehicle.ardp = 100;
                      } else {
                        widget.etatVehicle.ardp = 20;
                      }
                    });
                  },
                ),
                SizedBox(
                  height: 100.px,
                ),
                OnTapScaleAndFade(
                  child: Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: getLightIntensityFromPourc(widget.etatVehicle.argp, appTheme),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (widget.etatVehicle.argp <= 20) {
                        widget.etatVehicle.argp = 30;
                      } else if (widget.etatVehicle.argp <= 30) {
                        widget.etatVehicle.argp = 50;
                      } else if (widget.etatVehicle.argp <= 50) {
                        widget.etatVehicle.argp = 60;
                      } else if (widget.etatVehicle.argp <= 60) {
                        widget.etatVehicle.argp = 80;
                      } else if (widget.etatVehicle.ardp <= 80) {
                        widget.etatVehicle.ardp = 90;
                      } else if (widget.etatVehicle.argp <= 90) {
                        widget.etatVehicle.argp = 100;
                      } else {
                        widget.etatVehicle.argp = 20;
                      }
                    });
                  },
                ),
              ],
            ),
          )),
    ];
  }

  RadialGradient? getLightIntensityFromPourc(double pourc, AppTheme appTheme) {
    if (pourc <= 20) {
      return appTheme.getRadiantDarkest();
    } else if (pourc <= 30) {
      return appTheme.getRadiantDarker();
    } else if (pourc <= 50) {
      return appTheme.getRadiantDark();
    } else if (pourc <= 60) {
      return appTheme.getRadiantStandard();
    } else if (pourc <= 80) {
      return appTheme.getRadiantLight();
    } else if (pourc <= 90) {
      return appTheme.getRadiantLighter();
    } else if (pourc < 100) {
      return appTheme.getRadiantLightest();
    } else {
      return null;
    }
  }

}
