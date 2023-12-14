import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/utilities/car_svg.dart';
import 'package:printing/printing.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'dart:math' as math;

import '../serializables/etat_vehicle.dart';
import '../serializables/reparation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class ReparationPdf {
  final Reparation reparation;

  late final EtatVehicle etatVehicle;

  ReparationPdf({required this.reparation}){
    etatVehicle=reparation.etatActuel??EtatVehicle();
  }

  Future<void> initFonts() async{
    Font font=await PdfGoogleFonts.rubikRegular();
    Font fontBold=await PdfGoogleFonts.rubikSemiBold();
    bigTitle=  TextStyle (
    font: fontBold,
    color: PdfColors.orange200,
    fontSize: 15,
    letterSpacing: -0.15,
    );
    kindaBigText = TextStyle(
      font: font,
      fontSize: 12,
      letterSpacing: -0.12,
    );
    kindaBigTextBold = TextStyle(
      font: fontBold,

      fontSize: 12,
      letterSpacing: -0.12,
    );
  }

  Future<Uint8List> getDocument() async {
    var entrepriseLogo = MemoryImage(
      await File('mylogo.png').readAsBytes(),
    );
    var poLogo=MemoryImage((await rootBundle.load('assets/images/logo.webp')).buffer.asUint8List());
    var doc = Document();

  await initFonts();

    doc.addPage(Page(

        margin: const EdgeInsets.all(PdfPageFormat.cm),
        build: (context) {
      return Column(children: [
        getHeader(entrepriseLogo),
        vehicleDamage(),
        Spacer(),
        branding(poLogo),
      ]);
    }));

    return doc.save();
  }

  late final TextStyle bigTitle;
  late final TextStyle kindaBigText;
  late final TextStyle kindaBigTextBold;
  final numberFormat = NumberFormat('00000000', 'fr');
  final dateFormat = DateFormat('dd MMMM yyyy', 'fr');
  Widget getHeader(MemoryImage entrepriseLogo) {
    return SizedBox(
      height: PdfPageFormat.cm * 7,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
        Image(entrepriseLogo,
            width: PdfPageFormat.cm * 3,
            height: PdfPageFormat.cm * 3,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter),
        Spacer(),
        SizedBox(
          height: PdfPageFormat.cm * 2.7,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('ORDRE DE RÉPARATION', style: bigTitle),
            SizedBox(
              height: PdfPageFormat.cm * 0.3,
            ),
            Expanded(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      width: PdfPageFormat.cm * 6.3,
                      decoration: BoxDecoration(
                        color: PdfColors.orange700,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Ordre #', style: kindaBigTextBold),
                                    dotsSpacer(),
                                    Text(numberFormat.format(reparation.numero),
                                        style: kindaBigText),
                                  ]),
                            ),
                            SizedBox(height: PdfPageFormat.cm * 0.5),
                            Flexible(
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Date', style: kindaBigTextBold),
                                    dotsSpacer(),
                                    Text(dateFormat.format(reparation.date),
                                        style: kindaBigText),
                                  ]),
                            )
                          ]),
                    ),
                  ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget branding(MemoryImage poLogo){
    return
      SizedBox(
        height: PdfPageFormat.cm*4,
        width: PdfPageFormat.cm*19,
        child:
        Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: PdfPageFormat.cm*4.5,
                height: PdfPageFormat.cm*1.5,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: PdfPageFormat.cm*3.9,
                      child:      Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Via ',style: const TextStyle(color: PdfColors.grey)),
                            Spacer(),
                            Image(poLogo,
                                width: PdfPageFormat.cm * 2,
                                height: PdfPageFormat.cm * 2,
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter),
                          ]
                      ),
                    ),
                    Text('https://www.parcoto.com',style:const TextStyle(color: PdfColors.blue,fontSize: 10)),

                  ]
                ),
              ),

            ]
        ),
      );

  }

  Widget dotsSpacer() {
    return Flexible(
        child: Row(children: [
      SizedBox(width: PdfPageFormat.cm * 0.08),
      Flexible(
        child: Container(
            height: 2,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(style: BorderStyle.dotted)),
            )),
      ),
      SizedBox(width: PdfPageFormat.cm * 0.08),
    ]));
  }


  double lightHeight = 25.px;
  double lightWidth = 25.px;
  Widget vehicleDamage() {
    return
    Transform.scale(scale: 0.4,child:  Transform.rotate(
        angle: math.pi/2,
        child:
        SizedBox(
          width: 317.px,
          height: 148.px,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              ///image
              Positioned.fill(
                  left: 10.px,
                  right: 5.px,
                  child: SvgImage(svg:CarSvg.svg,
                    fit: BoxFit.fitWidth, )),
              ...getFeux(),
              ...getAutres(),
              ...getSiegeEtPortes(),
              ...getPneumatiques(),
              ...getPareBrises(),
              ...getAiles(),
              ...getPareChocs(),
            ],
          ),
        )
    ));

  }

  List<Positioned> getAutres() {
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
                Container(
                    height: lightHeight,
                    decoration: BoxDecoration(
                      gradient: reparation.etatActuel?.calandre==true ?  getRadiantDark() : null,
                    ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.capot ? getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.toit ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.coffre ?  getRadiantDark() : null,
                  ),
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
          left: 3.px,
          top: 0.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.aileAVD == true ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 92.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.aileAVG == true ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.aileARD == true ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 95.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.aileARG == true ?  getRadiantDark() : null,
                  ),
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
          left: -2.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: lightHeight,
            child: Column(
              children: [
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.pareChocAV ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.pareChocAR == true ?  getRadiantDark() : null,
                  ),
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
          left: 130.px,
          top: 3.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.porteAVD ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 90.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.porteAVG ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.siegeAVD ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 30.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.siegeAVG ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.siegeARD ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 30.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.siegeARG ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.porteARD ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 90.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.porteARG ?  getRadiantDark() : null,
                  ),
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
          left: 10.px,
          top: 23.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.feuAVD == true ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 52.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.feuAVG == true ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.phareD == true ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 85.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.phareG == true ?  getRadiantDark() : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.feuARD == true ?  getRadiantDark() : null,
                  ),
                ),
                SizedBox(
                  height: 65.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:
                     etatVehicle.feuARG == true ?  getRadiantDark() : null,
                  ),
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
          left: 92.px,
          top: 60.px,
          child: SizedBox(
            width: lightWidth,
            height: 4.75.w,
            child: Column(
              children: [
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.parBriseAve
                        ?  getRadiantDark()
                        :  etatVehicle.parBriseAvc
                        ?  getRadiantStandard()
                        :  etatVehicle.parBriseAvf
                        ?  getRadiantLight()
                        : null,
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient:  etatVehicle.parBriseAre
                        ?  getRadiantDark()
                        :  etatVehicle.parBriseArc
                        ?  getRadiantStandard()
                        :  etatVehicle.parBriseArf
                        ?  getRadiantLight()
                        : null,
                  ),
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
          left: 54.px,
          top: -2.px,
          child: SizedBox(
            width: lightWidth,
            height: 30.h,
            child: Column(
              children: [
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient: getLightIntensityFromPourc(reparation.etatActuel?.avdp??100, ),
                  ),
                ),
                SizedBox(
                  height: 100.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient: getLightIntensityFromPourc(reparation.etatActuel?.avgp??100, ),
                  ),
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
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient: getLightIntensityFromPourc(reparation.etatActuel?.ardp??100, ),
                  ),
                ),
                SizedBox(
                  height: 100.px,
                ),
                Container(
                  height: lightHeight,
                  decoration: BoxDecoration(
                    gradient: getLightIntensityFromPourc(etatVehicle.argp, ),
                  ),
                ),
              ],
            ),
          )),
    ];
  }

  RadialGradient? getLightIntensityFromPourc(double pourc,) {
     if (pourc <= 30) {
      return getRadiantDark();
    } else if (pourc <= 60) {
      return getRadiantStandard();
    } else if (pourc < 100) {
      return getRadiantLight();
    } else {
      return null;
    }
  }


  PdfColor orange=PdfColors.orange;
  PdfColor orangeLight=PdfColors.orange100;
  PdfColor orangeDeep=PdfColors.orange700;

  RadialGradient getRadiantStandard() {
    return RadialGradient(radius: 0.4, colors: [
      orange,
      PdfColor(orange.red, orange.green, orange.blue,0.7),
      PdfColor(orange.red, orange.green, orange.blue,0.4),
      PdfColor(orange.red, orange.green, orange.blue,0.2),
      PdfColor(orange.red, orange.green, orange.blue,0.03),
      PdfColor.fromRYB(0, 0, 0,0.03),
      PdfColor.fromRYB(0, 0, 0,0),
    ]);
  }
  RadialGradient getRadiantLight() {
    return RadialGradient(radius: 0.4, colors: [
      orangeLight,
      PdfColor(orangeLight.red, orangeLight.green, orangeLight.blue,0.7),
      PdfColor(orangeLight.red, orangeLight.green, orangeLight.blue,0.4),
      PdfColor(orangeLight.red, orangeLight.green, orangeLight.blue,0.2),
      PdfColor(orangeLight.red, orangeLight.green, orangeLight.blue,0.03),
      PdfColor.fromRYB(0, 0, 0,0.03),
      PdfColor.fromRYB(0, 0, 0,0),
    ]);
  }
  RadialGradient getRadiantDark() {
    return RadialGradient(
        colors: [
      orangeDeep,
      PdfColor(orangeDeep.red, orangeDeep.green, orangeDeep.blue,0.5),
      PdfColor(orangeDeep.red, orangeDeep.green, orangeDeep.blue,0.05),
      PdfColor(orangeDeep.red, orangeDeep.green, orangeDeep.blue,0),
      PdfColor.fromHex('#FFFFFF00'),
        ]);
  }

}
