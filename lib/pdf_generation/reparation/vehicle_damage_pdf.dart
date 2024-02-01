import 'dart:math' as math;

import 'package:parc_oto/utilities/car_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../serializables/reparation/etat_vehicle.dart';
import '../../serializables/reparation/reparation.dart';
import '../pdf_theming.dart';
import '../pdf_utilities.dart';

class VehicleDamagePDF {
  final Reparation reparation;
  late final EtatVehicle etatVehicle;

  VehicleDamagePDF(this.reparation) {
    etatVehicle = reparation.etatActuel ?? EtatVehicle();
  }

  double lightHeight = 0;
  double lightWidth = 0;

  final dx = 7;
  final dy = 7;

  Widget vehicleDamage() {
    double width = 3.7;
    Map<String, dynamic> etatJson = etatVehicle.toJson();

    List<Widget> etats =
        PdfUtilities.getTextListFromMap(etatJson, 0, etatJson.length);

    return Container(
      width: 20 * PdfPageFormat.cm,
      height: 5.90 * PdfPageFormat.cm,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('État du vehicule', style: kindaBigTextBold),
        SizedBox(
            width: 20 * PdfPageFormat.cm,
            height: 5 * PdfPageFormat.cm,
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                left: 0,
                child: carDrawing(),
              ),
              Positioned(
                left: (200 * 0.4).px,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Pneus', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(0, 4)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Pare-Brise AV',
                                      style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(4, 7)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Phare', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(10, 12)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                      ]),
                      Column(children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Feux', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(12, 16)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Pare-Brise AR',
                                      style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(7, 10)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child:
                                      Text('Pare-choc', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(20, 22)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                      ]),
                      Column(children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Ailes', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(16, 20)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Portes', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(22, 26)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                      ]),
                      Column(children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Sièges', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(30, 34)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: width * PdfPageFormat.cm + 4,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                  ),
                                  child: Text('Autre', style: smallTextBold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    children: etats
                                        .getRange(26, 30)
                                        .toList(growable: false),
                                  ),
                                )
                              ]),
                        ),
                      ]),
                    ]),
              ),
            ])),
      ]),
    );
  }

  Widget carDrawing() {
    double scale = 0.4;
    lightHeight = (25 - dx).px;
    lightWidth = (25 - dy).px;
    return Transform.scale(
        scale: scale,
        origin: PdfPoint(-200.px, 0),
        child: Transform.rotate(
            angle: -math.pi / 2,
            child: SizedBox(
              width: 317.px,
              height: 148.px,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ///image
                  Positioned.fill(
                      left: 10.px,
                      right: 5.px,
                      child: SvgImage(
                        svg: CarSvg.svg,
                        fit: BoxFit.fitWidth,
                      )),

                  ...getFeux(),
                  ...getAutres(),
                  ...getSiegeEtPortes(),
                  ...getPneumatiques(),
                  ...getPareBrises(),
                  ...getAiles(),
                  ...getPareChocs(),
                ],
              ),
            )));
  }

  List<Positioned> getAutres() {
    int hpos = 56;
    return [
      ///CALANDRE
      Positioned(
          left: (6 + dx).px,
          top: (hpos + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.calandre == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Capot
      Positioned(
          left: (50 + dx).px,
          top: (hpos + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.capot == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Toit
      Positioned(
          left: (160 + dx).px,
          top: (hpos + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.toit == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Coffre
      Positioned(
          left: (263 + dx).px,
          top: (hpos + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.coffre == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getAiles() {
    return [
      ///Ailes AV
      Positioned(
          left: (3 + dx).px,
          top: (0 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.aileAVD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (88 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.aileAVG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Aile AR
      Positioned(
          left: (290 + dx).px,
          top: (0 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.aileARD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (86 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.aileARG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getPareChocs() {
    return [
      ///Pare-choc AV
      Positioned(
          left: (-7 + dx).px,
          top: (56 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.pareChocAV == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Pare-choc AR
      Positioned(
          left: (292 + dx).px,
          top: (56 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.pareChocAR == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getSiegeEtPortes() {
    return [
      ///Portes avant
      Positioned(
          left: (130 + dx).px,
          top: (0 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.porteAVD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (86 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.porteAVG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Sieges avant
      Positioned(
          left: (130 + dx).px,
          top: (28 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.siegeAVD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (30 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.siegeAVG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Sieges arriere
      Positioned(
          left: (190 + dx).px,
          top: (28 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.siegeARD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (30 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.siegeARG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Portes arriere
      Positioned(
          left: (180 + dx).px,
          top: (0 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.porteARD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (86 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: reparation.etatActuel?.porteARG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getFeux() {
    return [
      ///Feux AV
      Positioned(
          left: (10 + dx).px,
          top: (23 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.feuAVD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: 52.px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.feuAVG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Phare
      Positioned(
          left: (19 + dx).px,
          top: (5 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.phareD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (85 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.phareG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),

      ///Feux AR
      Positioned(
          left: (286 + dx).px,
          top: (15 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.feuARD == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
                SizedBox(
                  height: (60 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.feuARG == true
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : null,
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getPareBrises() {
    return [
      ///Pare-brise AV
      Positioned(
          left: (90 + dx).px,
          top: (56 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 4.75.w,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.parBriseAve
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : etatVehicle.parBriseAvc
                          ? Icon(IconData(iconCodePoint), color: orange)
                          : etatVehicle.parBriseAvf
                              ? Icon(IconData(iconCodePoint),
                                  color: orangeLight)
                              : null,
                ),
              ],
            ),
          )),

      ///Pare-brise AR
      Positioned(
          left: (225 + dx).px,
          top: (56 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.parBriseAre
                      ? Icon(IconData(iconCodePoint), color: orangeDeep)
                      : etatVehicle.parBriseArc
                          ? Icon(IconData(iconCodePoint), color: orange)
                          : etatVehicle.parBriseArf
                              ? Icon(IconData(iconCodePoint),
                                  color: orangeLight)
                              : null,
                ),
              ],
            ),
          )),
    ];
  }

  List<Positioned> getPneumatiques() {
    return [
      ///Roues avant
      Positioned(
          left: (54 + dx).px,
          top: (-5 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: getLightIntensityFromPourc(
                    reparation.etatActuel?.avdp ?? 100,
                  ),
                ),
                SizedBox(
                  height: (96 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: getLightIntensityFromPourc(
                    reparation.etatActuel?.avgp ?? 100,
                  ),
                ),
              ],
            ),
          )),

      ///Roues arriere
      Positioned(
          left: (237 + dx).px,
          top: (-5 + dy).px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: getLightIntensityFromPourc(
                    reparation.etatActuel?.ardp ?? 100,
                  ),
                ),
                SizedBox(
                  height: (96 + dy).px,
                ),
                SizedBox(
                  height: lightHeight,
                  child: getLightIntensityFromPourc(
                    etatVehicle.argp,
                  ),
                ),
              ],
            ),
          )),
    ];
  }

  Widget? getLightIntensityFromPourc(
    double pourc,
  ) {
    if (pourc <= 30) {
      return Icon(IconData(iconCodePoint), color: orangeDeep);
    } else if (pourc <= 60) {
      return Icon(IconData(iconCodePoint), color: orange);
    } else if (pourc < 100) {
      return Icon(IconData(iconCodePoint), color: orangeLight);
    } else {
      return null;
    }
  }
}
