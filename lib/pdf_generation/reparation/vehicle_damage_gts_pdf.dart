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


  String getSvg(){
    switch(VehiclesUtilities.getGenreNumber(reparation.vehiculemat)){
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
                        svg: getSvg(),
                        fit: BoxFit.fitWidth,
                      )),


                ],
              ),
            )));
  }

}
