import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:parc_oto/serializables/reparation/etat_vehicle_gts.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/on_tap_scale.dart';

class VehicleDamageGts extends StatefulWidget {
  final EtatVehicleGTS etatVehicle;
  final int vehicleType;
  const VehicleDamageGts({
    super.key,
    required this.etatVehicle,
    required this.vehicleType,
  });

  @override
  State<VehicleDamageGts> createState() => _VehicleDamageState();
}

class _VehicleDamageState extends State<VehicleDamageGts> {
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      width: 80.w,
      height: 65.h,
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.h,
            child: Column(
              children: [
                Flexible(
                  flex: 2,
                  child: Row(
                    children: [
                      firstTable(appTheme),
                      smallSpace,
                      Flexible(
                          child: TextBox(
                        controller: widget.etatVehicle.cabineController,
                        placeholder: 'commentaires'.tr(),
                        maxLength: 300,
                        maxLines: 4,
                        onChanged: (s) {
                          widget.etatVehicle.cabineCom = s;
                          setState(() {});
                        },
                      ))
                    ],
                  ),
                ),
                bigSpace,
                Divider(),
                bigSpace,
                Flexible(
                  flex: 3,
                  child: Row(
                    children: [
                      secondTable(appTheme),
                      smallSpace,
                      Flexible(
                          child: TextBox(
                        controller: widget.etatVehicle.extAvController,
                        placeholder: 'commentaires'.tr(),
                        maxLength: 300,
                        maxLines: 6,
                        onChanged: (s) {
                          widget.etatVehicle.exterieurAvCom = s;
                          setState(() {});
                        },
                      ))
                    ],
                  ),
                ),
                bigSpace,
                Divider(),
                bigSpace,
                Flexible(
                  flex: 3,
                  child: Row(
                    children: [
                      thirdTable(appTheme),
                      smallSpace,
                      Flexible(
                          child: TextBox(
                        controller: widget.etatVehicle.extArController,
                        placeholder: 'commentaires'.tr(),
                        maxLength: 300,
                        maxLines: 6,
                        onChanged: (s) {
                          widget.etatVehicle.exterieurArCom = s;
                          setState(() {});
                        },
                      ))
                    ],
                  ),
                ),
              ],
            ),
          ),
          bigSpace,
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                vehicleDamage(appTheme),
                bigSpace,
                Row(children: [
                  Button(
                      onPressed: () => selectAllVehicleDamage(false),
                      child: const Text('clear').tr()),
                  smallSpace,
                  FilledButton(
                      onPressed: () => selectAllVehicleDamage(true),
                      child: const Text('selectall').tr()),
                ]),
              ]),
        ],
      ),
    );
  }

  void selectAllVehicleDamage(bool value) {
    widget.etatVehicle.marchePieds = value;
    widget.etatVehicle.balEss = value;
    widget.etatVehicle.calottes = value;
    widget.etatVehicle.feuxSign = value;
    widget.etatVehicle.intCab = value;
    widget.etatVehicle.optiqueSign = value;
    widget.etatVehicle.parBrise = value;
    widget.etatVehicle.pareChoAr = value;
    widget.etatVehicle.pareChoAv = value;
    widget.etatVehicle.plaqueArriere = value;
    widget.etatVehicle.plaqueAvant = value;
    widget.etatVehicle.reser = value;
    widget.etatVehicle.retroVis = value;
    widget.etatVehicle.rouePnArriere = value;
    widget.etatVehicle.rouePnAvant = value;
    widget.etatVehicle.roueSecours = value;

    setState(() {});
  }

  var textStyle = TextStyle(fontSize: 10);
  var headerStyle = TextStyle(fontWeight: FontWeight.bold);
  Widget firstTable(AppTheme appTheme) {
    return SizedBox(
      width: 40.w,
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(10),
          1: FlexColumnWidth(22),
          2: FixedColumnWidth(20.px)
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            SizedBox(
                height: 24,
                child: Text(
                  'cabine'.tr().toUpperCase(),
                  style: headerStyle,
                )),
            Text('intcabine', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.intCab,
                onChanged: (s) {
                  widget.etatVehicle.intCab = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('balais', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.balEss,
                onChanged: (s) {
                  widget.etatVehicle.balEss = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('parebrise', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.parBrise,
                onChanged: (s) {
                  widget.etatVehicle.parBrise = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('retro', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.retroVis,
                onChanged: (s) {
                  widget.etatVehicle.retroVis = s ?? false;
                  setState(() {});
                })
          ]),
        ],
      ),
    );
  }

  Widget secondTable(AppTheme appTheme) {
    return SizedBox(
      width: 40.w,
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(10),
          1: FlexColumnWidth(22),
          2: FixedColumnWidth(20.px)
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(children: [
            SizedBox(
                height: 24,
                child: Text(
                  'extavant'.tr().toUpperCase(),
                  style: headerStyle,
                )),
            Text('parechoc', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.pareChoAv,
                onChanged: (s) {
                  widget.etatVehicle.pareChoAv = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('optique', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.optiqueSign,
                onChanged: (s) {
                  widget.etatVehicle.optiqueSign = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('plaqueavant', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.plaqueAvant,
                onChanged: (s) {
                  widget.etatVehicle.plaqueAvant = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('marchepieds', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.marchePieds,
                onChanged: (s) {
                  widget.etatVehicle.marchePieds = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('rouesavant', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.rouePnAvant,
                onChanged: (s) {
                  widget.etatVehicle.rouePnAvant = s ?? false;
                  setState(() {});
                })
          ]),
          if (widget.vehicleType == 2)
            TableRow(children: [
              SizedBox(
                height: 24,
              ),
              Text('reservoir', style: textStyle).tr(),
              Checkbox(
                  checked: widget.etatVehicle.reser,
                  onChanged: (s) {
                    widget.etatVehicle.reser = s ?? false;
                    setState(() {});
                  })
            ]),
        ],
      ),
    );
  }

  Widget thirdTable(AppTheme appTheme) {
    return SizedBox(
      width: 40.w,
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(10),
          1: FlexColumnWidth(22),
          2: FixedColumnWidth(20.px)
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          if (widget.vehicleType == 2)
            TableRow(children: [
              SizedBox(
                  height: 24,
                  child: Text(
                    'extarr'.tr().toUpperCase(),
                    style: headerStyle,
                  )),
              Text('calotte', style: textStyle).tr(),
              Checkbox(
                  checked: widget.etatVehicle.calottes,
                  onChanged: (s) {
                    widget.etatVehicle.calottes = s ?? false;
                    setState(() {});
                  })
            ]),
          if (widget.vehicleType != 2)
            TableRow(children: [
              SizedBox(
                  height: 24,
                  child: Text(
                    'extarr'.tr().toUpperCase(),
                    style: headerStyle,
                  )),
              Text('parechocarr', style: textStyle).tr(),
              Checkbox(
                  checked: widget.etatVehicle.pareChoAr,
                  onChanged: (s) {
                    widget.etatVehicle.pareChoAr = s ?? false;
                    setState(() {});
                  })
            ]),
          if (widget.vehicleType == 2)
            TableRow(children: [
              SizedBox(
                height: 24,
              ),
              Text('parechocarr', style: textStyle).tr(),
              Checkbox(
                  checked: widget.etatVehicle.pareChoAr,
                  onChanged: (s) {
                    widget.etatVehicle.pareChoAr = s ?? false;
                    setState(() {});
                  })
            ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('plaquearr', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.plaqueArriere,
                onChanged: (s) {
                  widget.etatVehicle.plaqueArriere = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('feuxarr', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.feuxSign,
                onChanged: (s) {
                  widget.etatVehicle.feuxSign = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('rouesarr', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.rouePnArriere,
                onChanged: (s) {
                  widget.etatVehicle.rouePnArriere = s ?? false;
                  setState(() {});
                })
          ]),
          TableRow(children: [
            SizedBox(
              height: 24,
            ),
            Text('rouesecours', style: textStyle).tr(),
            Checkbox(
                checked: widget.etatVehicle.roueSecours,
                onChanged: (s) {
                  widget.etatVehicle.roueSecours = s ?? false;
                  setState(() {});
                })
          ]),
          if (widget.vehicleType != 2)
            TableRow(children: [
              SizedBox(
                height: 24,
              ),
              Text('reservoir', style: textStyle).tr(),
              Checkbox(
                  checked: widget.etatVehicle.reser,
                  onChanged: (s) {
                    widget.etatVehicle.reser = s ?? false;
                    setState(() {});
                  })
            ]),
        ],
      ),
    );
  }

  double lightHeight = 25.px;
  double lightWidth = 25.px;

  Widget vehicleDamage(AppTheme appTheme) {
    return SizedBox(
      width: 222.px,
      height: 222.px,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ///image
          Positioned.fill(
              top: 5,
              right: 5,
              left: 5,
              child: Transform.rotate(
                angle: math.pi / 2,
                child: Image.asset(getVehicleImage(),
                    fit: BoxFit.contain, color: appTheme.writingStyle.color),
              )),
          ...getCabineSelection(appTheme),
          ...getExtAvSelection(),
          ...getExtArSelection(),
        ],
      ),
    );
  }

  List<Positioned> getCabineSelection(AppTheme appTheme) {
    return [
      //int cabine
      Positioned(
          left: 74.px,
          right: 74.px,
          top: widget.vehicleType == 2 ? 40.px : 114.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.intCab = !widget.etatVehicle.intCab;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.intCab
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //balais essuie glace
      Positioned(
          left: 74.px,
          right: 74.px,
          top: widget.vehicleType == 2 ? 5.px : 55.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.balEss = !widget.etatVehicle.balEss;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.balEss
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //parebrise
      Positioned(
          left: 74.px,
          right: 74.px,
          top: widget.vehicleType == 2 ? 15.px : 65.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.parBrise = !widget.etatVehicle.parBrise;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.parBrise
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          left: 63.px,
          top: widget.vehicleType == 2 ? 40.px : 85.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.parBrise = !widget.etatVehicle.parBrise;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.parBrise
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: 63.px,
          top: widget.vehicleType == 2 ? 40.px : 85.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.parBrise = !widget.etatVehicle.parBrise;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.parBrise
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      if (widget.vehicleType != 2)
        Positioned(
            left: 63.px,
            bottom: widget.vehicleType == 2 ? 20.px : 75.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.parBrise = !widget.etatVehicle.parBrise;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.parBrise
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),

      if (widget.vehicleType != 2)
        Positioned(
            right: 63.px,
            bottom: widget.vehicleType == 2 ? 20.px : 75.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.parBrise = !widget.etatVehicle.parBrise;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.parBrise
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),
      if (widget.vehicleType != 2)
        Positioned(
            left: 74.px,
            right: 74.px,
            bottom: widget.vehicleType == 2 ? 20.px : 40.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.parBrise = !widget.etatVehicle.parBrise;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.parBrise
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),
      //Retroviseurs
      Positioned(
          left: widget.vehicleType == 2 ? 63.px : 50.px,
          top: widget.vehicleType == 2 ? 20.px : 70.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.retroVis = !widget.etatVehicle.retroVis;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.retroVis
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: widget.vehicleType == 2 ? 63.px : 50.px,
          top: widget.vehicleType == 2 ? 20.px : 70.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.retroVis = !widget.etatVehicle.retroVis;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.retroVis
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
    ];
  }

  List<Positioned> getExtAvSelection() {
    return [
      //pare choc avant
      Positioned(
          left: 74.px,
          right: 74.px,
          top: widget.vehicleType == 2 ? 0.px : -5.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.pareChoAv = !widget.etatVehicle.pareChoAv;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.pareChoAv
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //optique avant
      Positioned(
          left: 68.px,
          top: widget.vehicleType == 2 ? 5.px : 5.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.optiqueSign =
                    !widget.etatVehicle.optiqueSign;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.optiqueSign
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: 68.px,
          top: widget.vehicleType == 2 ? 5.px : 5.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.optiqueSign =
                    !widget.etatVehicle.optiqueSign;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.optiqueSign
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //plaque avant
      Positioned(
          left: 68.px,
          right: 68.px,
          top: widget.vehicleType == 2 ? -10.px : -5.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.plaqueAvant =
                    !widget.etatVehicle.plaqueAvant;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.plaqueAvant
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //marche pied
      Positioned(
          left: widget.vehicleType == 2 ? 68.px : 50.px,
          top: widget.vehicleType == 2 ? 40.px : 90.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.marchePieds =
                    !widget.etatVehicle.marchePieds;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.marchePieds
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: widget.vehicleType == 2 ? 68.px : 50.px,
          top: widget.vehicleType == 2 ? 40.px : 90.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.marchePieds =
                    !widget.etatVehicle.marchePieds;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.marchePieds
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //roues avant
      Positioned(
          left: widget.vehicleType == 2 ? 68.px : 50.px,
          top: widget.vehicleType == 2 ? 30.px : 30.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.rouePnAvant =
                    !widget.etatVehicle.rouePnAvant;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.rouePnAvant
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: widget.vehicleType == 2 ? 68.px : 50.px,
          top: widget.vehicleType == 2 ? 30.px : 30.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.rouePnAvant =
                    !widget.etatVehicle.rouePnAvant;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.rouePnAvant
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      if (widget.vehicleType == 2)
        //reservoir
        Positioned(
            left: widget.vehicleType == 2 ? 68.px : 50.px,
            top: widget.vehicleType == 2 ? 50.px : 30.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.reser = !widget.etatVehicle.reser;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.reser
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),
    ];
  }

  List<Positioned> getExtArSelection() {
    return [
      if (widget.vehicleType == 2)
        //callottes
        Positioned(
            right: widget.vehicleType == 2 ? 78.px : 50.px,
            bottom: widget.vehicleType == 2 ? 10.px : 30.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.calottes = !widget.etatVehicle.calottes;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.calottes
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),
      if (widget.vehicleType == 2)
        //callottes
        Positioned(
            left: widget.vehicleType == 2 ? 78.px : 50.px,
            bottom: widget.vehicleType == 2 ? 10.px : 30.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.calottes = !widget.etatVehicle.calottes;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.calottes
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),

      //parechoc
      Positioned(
          left: widget.vehicleType == 2 ? 78.px : 50.px,
          right: widget.vehicleType == 2 ? 78.px : 50.px,
          bottom: widget.vehicleType == 2 ? 10.px : -10.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.pareChoAr = !widget.etatVehicle.pareChoAr;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.pareChoAr
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //plaque
      Positioned(
          left: widget.vehicleType == 2 ? 78.px : 50.px,
          right: widget.vehicleType == 2 ? 78.px : 50.px,
          bottom: widget.vehicleType == 2 ? 0.px : 0.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.plaqueArriere =
                    !widget.etatVehicle.plaqueArriere;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.plaqueArriere
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      //feux arriere
      Positioned(
          left: widget.vehicleType == 2 ? 68.px : 65.px,
          bottom: widget.vehicleType == 2 ? 10.px : 0.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.feuxSign = !widget.etatVehicle.feuxSign;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.feuxSign
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: widget.vehicleType == 2 ? 68.px : 65.px,
          bottom: widget.vehicleType == 2 ? 10.px : 0.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.feuxSign = !widget.etatVehicle.feuxSign;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.feuxSign
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),

      //roue arriere
      Positioned(
          left: widget.vehicleType == 2 ? 70.px : 60.px,
          bottom: widget.vehicleType == 2 ? 50.px : 40.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.rouePnArriere =
                    !widget.etatVehicle.rouePnArriere;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.rouePnArriere
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          right: widget.vehicleType == 2 ? 70.px : 60.px,
          bottom: widget.vehicleType == 2 ? 50.px : 40.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.rouePnArriere =
                    !widget.etatVehicle.rouePnArriere;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.rouePnArriere
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),

      //roue secours
      Positioned(
          right: widget.vehicleType == 2 ? 70.px : 60.px,
          left: widget.vehicleType == 2 ? 70.px : 60.px,
          bottom: widget.vehicleType == 2 ? 20.px : 15.px,
          child: OnTapScaleAndFade(
            onTap: () {
              setState(() {
                widget.etatVehicle.roueSecours =
                    !widget.etatVehicle.roueSecours;
              });
            },
            child: SizedBox(
              width: lightWidth,
              height: lightHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: lightHeight,
                    child: widget.etatVehicle.roueSecours
                        ? Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          )),
      if (widget.vehicleType != 2)
        //reservoir
        Positioned(
            left: 60.px,
            bottom: 50.px,
            child: OnTapScaleAndFade(
              onTap: () {
                setState(() {
                  widget.etatVehicle.reser = !widget.etatVehicle.reser;
                });
              },
              child: SizedBox(
                width: lightWidth,
                height: lightHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: lightHeight,
                      child: widget.etatVehicle.reser
                          ? Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            )),
    ];
  }

  String getVehicleImage() {
    switch (widget.vehicleType) {
      case 1:
        return 'assets/images/car.webp';
      case 2:
        return 'assets/images/truck.webp';
      case 4:
        return 'assets/images/bus.webp';
      case 9:
        return 'assets/images/moto.webp';
      default:
        return 'assets/images/car.webp';
    }
  }
}
