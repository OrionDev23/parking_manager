import 'dart:math' as math;

import 'package:parc_oto/utilities/bus_svg.dart';
import 'package:parc_oto/utilities/car_svg.dart';
import 'package:parc_oto/utilities/moto_svg.dart';
import 'package:parc_oto/utilities/truck_svg.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../serializables/reparation/etat_vehicle_gts.dart';
import '../../serializables/reparation/fiche_reception.dart';
import '../pdf_theming.dart';
import '../pdf_utilities.dart';

class VehicleDamageGtsPdf {
  final FicheReception reparation;
  late final EtatVehicleGTS etatVehicle;

  VehicleDamageGtsPdf(this.reparation) {
    etatVehicle = (reparation.etatActuel as EtatVehicleGTS);
  }

  double lightHeight = 0;
  double lightWidth = 0;



  Widget vehicleDamage() {
    double widthValues = 7;
    double widthHeaders = 3.3;
    double widthSpacing=1;
    double widthComs = 7;
    Map<String, dynamic> etatJson = etatVehicle.toJson();

    List<Widget> etats =
        PdfUtilities.getTextListFromMapGts(etatJson, 0, etatJson.length);

    return Container(
      width: 20 * PdfPageFormat.cm,
      height: 8 * PdfPageFormat.cm,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('État du vehicule', style: kindaBigTextBold),
        SizedBox(
            width: 20 * PdfPageFormat.cm,
            height: 7.1 * PdfPageFormat.cm,
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                left: 0,
                right: 3 * PdfPageFormat.cm,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(children: [
                      Text(
                        "ÉLÉMENTS CONTROLES",
                        style: smallTextBold,
                      ),
                      SizedBox(width: 6.6 * PdfPageFormat.cm),
                      Text(
                        "ÉTAT",
                        style: smallTextBold,
                      ),
                      SizedBox(width: widthSpacing * PdfPageFormat.cm),
                      Text(
                        "COMMENTAIRES",
                        style: smallTextBold,
                      ),
                    ]),
                  ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(),
                              bottom: BorderSide(),
                            ),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthHeaders * PdfPageFormat.cm + 4,
                                  child: Text('CABINE', style: smallTextBold),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthValues * PdfPageFormat.cm + 4,
                                  child: Column(
                                      children: [...etats.getRange(0, 4)]),
                                ),
                                SizedBox(width: widthSpacing*PdfPageFormat.cm),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthComs * PdfPageFormat.cm + 4,
                                  height: PdfPageFormat.cm * 1.6,
                                  child: Text(etatVehicle.cabineCom,
                                    style: smallText.copyWith(
                                      fontSize: 9,
                                    ),),
                                ),
                              ]),
                        ),
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(),
                            ),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthHeaders * PdfPageFormat.cm + 4,
                                  child: Text('EXTÉRIEUR AVANT',
                                      style: smallTextBold),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthValues * PdfPageFormat.cm + 4,
                                  child: Column(
                                      children: [...etats.getRange(5, 11)]),
                                ),
                                SizedBox(width: widthSpacing*PdfPageFormat.cm),

                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthComs * PdfPageFormat.cm + 4,
                                  height: PdfPageFormat.cm * 2.3,
                                  child: Text(etatVehicle.exterieurAvCom,
                                    style: smallText.copyWith(
                                      fontSize: 9,
                                    ),),
                                ),
                              ]),
                        ),
                        Padding(
                          padding: EdgeInsets.all(2),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthHeaders * PdfPageFormat.cm + 4,
                                  child: Text('EXTÉRIEUR ARRIÈRE',
                                      style: smallTextBold),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthValues * PdfPageFormat.cm + 4,
                                  child: Column(children: [
                                    ...etats.getRange(12, 18),
                                  ]),
                                ),
                                SizedBox(width: widthSpacing*PdfPageFormat.cm),

                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: widthComs * PdfPageFormat.cm + 4,
                                  height: PdfPageFormat.cm * 2.3,
                                  child: Text(etatVehicle.exterieurArCom,
                                    style: smallText.copyWith(
                                      fontSize: 9,
                                    ),),
                                ),
                              ]),
                        ),
                      ]),
                ]),
              ),
              Positioned(
                left: 16 * PdfPageFormat.cm,
                child: carDrawing(),
              ),
            ])),
      ]),
    );
  }

  String getSvg(int vehicleType) {
    switch (vehicleType) {
      case 1:
        return CarSvg.svg;
      case 2:
        return trucksvg;
      case 4:
        return busSVG;
      case 9:
        return motoSvg;
      default:
        return CarSvg.svg;
    }
  }

  Widget carDrawing() {
    int vehicleType = VehiclesUtilities.getGenreNumber(reparation.vehiculemat);

    double scale = 0.4;
    lightHeight = 25.px;
    lightWidth = 25.px;
    return Transform.scale(
        scale: scale,
        origin: PdfPoint(-200.px, 0),
        child: SizedBox(
              width: 310.8.px,
              height: 310.8.px,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ///image
                  Positioned.fill(
                      left: 5.px,
                      right: 5.px,
                      top: 5.px,
                      child: Transform.rotate(
                          angle: -math.pi / 2,child: SvgImage(
                        svg: getSvg(vehicleType),
                        fit: BoxFit.fitWidth,
                      ))),
                  ...getCabineSelection(vehicleType),
                  ...getExtAvSelection(vehicleType),
                  ...getExtArSelection(vehicleType),
                ],
              ),
            ));
  }

  int hpos = 56;
  int dy=40;

  List<Positioned> getCabineSelection(int vehicleType) {
    return [
      //int cabine
      Positioned(
        left: 74.px,
        right: 74.px,
        top: vehicleType == 2 ? 60.px : 150.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.intCab
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //balais essuie glace
      Positioned(
        left: 74.px,
        right: 74.px,
        top: vehicleType == 2 ? 10.px : 95.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.balEss
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //parebrise
      Positioned(
        left: 94.px,
        right: 94.px,
        top: vehicleType == 2 ? 20.px : 95.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.parBrise
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 94.px,
        top: vehicleType == 2 ? 50.px : 125.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.parBrise
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 94.px,
        top: vehicleType == 2 ? 50.px : 125.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.parBrise
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      if (vehicleType != 2)
        Positioned(
          left: 94.px,
          bottom: vehicleType == 2 ? 20.px : 115.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.parBrise
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

      if (vehicleType != 2)
        Positioned(
          right: 94.px,
          bottom: vehicleType == 2 ? 20.px : 115.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.parBrise
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      if (vehicleType != 2)
        Positioned(
          left: 74.px,
          right: 74.px,
          bottom: vehicleType == 2 ? 20.px : 55.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.parBrise
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      //Retroviseurs
      Positioned(
        left: vehicleType == 2 ? 98.px : 84.px,
        top: vehicleType == 2 ? 30.px : 105.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.retroVis
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: vehicleType == 2 ? 98.px : 84.px,
        top: vehicleType == 2 ? 30.px : 105.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.retroVis
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Positioned> getExtAvSelection(int vehicleType) {
    return [
      //pare choc avant
      Positioned(
        left: 74.px,
        right: 74.px,
        top: vehicleType == 2 ? 0.px : -5.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.pareChoAv
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //optique avant
      Positioned(
        left: vehicleType == 2 ? 100.px : 95.px,
        top: vehicleType == 2 ? 15.px : 15.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.optiqueSign
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: vehicleType == 2 ? 100.px : 95.px,
        top: vehicleType == 2 ? 15.px : 15.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.optiqueSign
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //plaque avant
      Positioned(
        left: 68.px,
        right: 68.px,
        top: vehicleType == 2 ? -10.px : -5.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.plaqueAvant
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //marche pied
      Positioned(
        left: vehicleType == 2 ? 100.px : 70.px,
        top: vehicleType == 2 ? 60.px : 120.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.marchePieds
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: vehicleType == 2 ? 100.px : 70.px,
        top: vehicleType == 2 ? 60.px : 120.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.marchePieds
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //roues avant
      Positioned(
        left: vehicleType == 2 ? 88.px : 70.px,
        top: vehicleType == 2 ? 40.px : 40.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.rouePnAvant
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: vehicleType == 2 ? 88.px : 70.px,
        top: vehicleType == 2 ? 40.px : 40.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.rouePnAvant
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      if (vehicleType == 2)
        //reservoir
        Positioned(
          left: vehicleType == 2 ? 98.px : 120.px,
          top: vehicleType == 2 ? 70.px : 30.px,

          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.reser
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Positioned> getExtArSelection(int vehicleType) {
    return [
      if (vehicleType == 2)
        //callottes
        Positioned(
          right: vehicleType == 2 ? 110.px : 50.px,
          bottom: vehicleType == 2 ? 20.px : 30.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.calottes
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      if (vehicleType == 2)
        //callottes
        Positioned(
          left: vehicleType == 2 ? 110.px : 50.px,
          bottom: vehicleType == 2 ? 20.px : 30.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.calottes
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

      //parechoc
      Positioned(
        left: vehicleType == 2 ? 78.px : 50.px,
        right: vehicleType == 2 ? 78.px : 50.px,
        bottom: vehicleType == 2 ? 10.px : -10.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.pareChoAr
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //plaque
      Positioned(
        left: vehicleType == 2 ? 78.px : 50.px,
        right: vehicleType == 2 ? 78.px : 50.px,
        bottom: vehicleType == 2 ? 0.px : 0.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.plaqueArriere
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      //feux arriere
      Positioned(
          left: vehicleType == 2 ? 95.px : 85.px,
          bottom: vehicleType == 2 ? 15.px : 0.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.feuxSign
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          )),
      Positioned(
        right: vehicleType == 2 ? 95.px : 85.px,
        bottom: vehicleType == 2 ? 15.px : 0.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.feuxSign
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),

      //roue arriere
      Positioned(
        left: vehicleType == 2 ? 105.px : 85.px,
        bottom: vehicleType == 2 ? 70.px : 55.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.rouePnArriere
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: vehicleType == 2 ? 105.px : 85.px,
        bottom: vehicleType == 2 ? 70.px : 55.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.rouePnArriere
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),

      //roue secours
      Positioned(
        right: vehicleType == 2 ? 70.px : 60.px,
        left: vehicleType == 2 ? 70.px : 60.px,
        bottom: vehicleType == 2 ? 35.px : 25.px,
        child: SizedBox(
          width: lightWidth,
          height: lightHeight,
          child: Column(
            children: [
              SizedBox(
                height: lightHeight,
                child: etatVehicle.roueSecours
                    ? Icon(
                        IconData(checkCodePoint),
                        color: PdfColors.green,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
      if (vehicleType != 2)
        //reservoir
        Positioned(
          left: 90.px,
          bottom: 65.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                SizedBox(
                  height: lightHeight,
                  child: etatVehicle.reser
                      ? Icon(
                          IconData(checkCodePoint),
                          color: PdfColors.green,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
