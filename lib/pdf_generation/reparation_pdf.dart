import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:parc_oto/screens/entreprise.dart';
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

  ReparationPdf({required this.reparation}) {
    etatVehicle = reparation.etatActuel ?? EtatVehicle();
  }

  void initFonts() {
    bigTitle = TextStyle(
      color: orangeLight,
      fontWeight: FontWeight.bold,
      fontSize: 15,
      letterSpacing: -0.15,
    );
    kindaBigText = const TextStyle(
      fontSize: 12,
      letterSpacing: -0.12,
    );
    kindaBigTextBold = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: -0.12,
    );
    smallText = const TextStyle(
      fontSize: 8,
      letterSpacing: -0.12,
    );
    smallTextBold = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.12,
    );
  }

  Future<Uint8List> getDocument() async {
    var entrepriseLogo = MemoryImage(
      await File('mylogo.png').readAsBytes(),
    );
    var poLogo = MemoryImage((await rootBundle.load('assets/images/logo.webp'))
        .buffer
        .asUint8List());
    var doc = Document(
        theme: ThemeData.withFont(
      base: await PdfGoogleFonts.rubikRegular(),
      bold: await PdfGoogleFonts.rubikSemiBold(),
      icons: Font.ttf(await rootBundle.load('assets/images/materialicon.ttf')),
    ));

    initFonts();

    doc.addPage(Page(
        margin: const EdgeInsets.all(PdfPageFormat.cm),
        build: (context) {
          return Column(children: [
            getHeader(entrepriseLogo),
            getVehicleInfo(),
            smallSpace,
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
  late final TextStyle smallTextBold;
  late final TextStyle smallText;
  final numberFormat = NumberFormat('00000000', 'fr');
  final dateFormat = DateFormat('dd MMMM yyyy', 'fr');
  final smallSpace = SizedBox(width: PdfPageFormat.cm * 0.1,height: PdfPageFormat.cm*0.1);

  Widget getHeader(MemoryImage entrepriseLogo) {
    return SizedBox(
      height: PdfPageFormat.cm * 7,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image(entrepriseLogo,
                width: PdfPageFormat.cm * 3,
                height: PdfPageFormat.cm * 3,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter),
            Container(
              padding: const EdgeInsets.all(5),
              width: 9 * PdfPageFormat.cm,
              height: PdfPageFormat.cm *2.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(MyEntrepriseState.p?.nom ?? '', style: smallTextBold.copyWith(color: orangeDeep)),
                    Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Adresse', style: smallTextBold),
                      smallSpace,
                      Text(MyEntrepriseState.p?.adresse ?? '',
                          style: smallText),
                    ]),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Email', style: smallTextBold),
                      dotsSpacer(),
                      Text(MyEntrepriseState.p?.email ?? '', style: smallText),
                      smallSpace,



                      Text('Tél', style: smallTextBold),
                      dotsSpacer(),
                      Text(MyEntrepriseState.p?.telephone ?? '',
                          style: smallText),
                    ]),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('NIF', style: smallTextBold),
                      dotsSpacer(),
                      Text(MyEntrepriseState.p?.nif ?? '', style: smallText),
                      smallSpace,
                      Text('NIS', style: smallTextBold),
                      dotsSpacer(),
                      Text(MyEntrepriseState.p?.nis ?? '', style: smallText),
                    ]),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('ART', style: smallTextBold),
                      dotsSpacer(),
                      Text(MyEntrepriseState.p?.art ?? '', style: smallText),
                      smallSpace,
                      Text('RC', style: smallTextBold),
                      dotsSpacer(),
                      Text(MyEntrepriseState.p?.rc ?? '', style: smallText),
                    ]),
                  ]),
            ),
            SizedBox(
              height: PdfPageFormat.cm * 2.7,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
                            color: orangeDeep,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('Ordre #',
                                            style: kindaBigTextBold),
                                        dotsSpacer(),
                                        Text(
                                            numberFormat
                                                .format(reparation.numero),
                                            style: kindaBigText),
                                      ]),
                                ),
                                SizedBox(height: PdfPageFormat.cm * 0.5),
                                Flexible(
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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

  Widget getVehicleInfo() {
    double width = PdfPageFormat.cm * 5;
    double height = PdfPageFormat.cm * 0.6;
    double bottom = 4;
    double bottomFill = 3;
    return Table(
        columnWidths: {
          0: const FlexColumnWidth(2),
          1: const FixedColumnWidth(4 * PdfPageFormat.cm),
          2: const FlexColumnWidth(3),
          3: const FlexColumnWidth(3),
        },
        border: TableBorder.all(),
        children: [
          TableRow(children: [
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('Marque', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: 5,
                        left: 5,
                        right: 5,
                        child: Text(reparation.marque ?? '', style: smallText),
                      ),
                    ]),
                  ),
                ])),
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('Modele', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: bottom,
                        left: 5,
                        right: 5,
                        child: Text(reparation.modele ?? '', style: smallText),
                      ),
                    ]),
                  ),
                ])),
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('Immatriculation', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: bottom,
                        left: 5,
                        right: 5,
                        child: Text(reparation.vehiculemat ?? '',
                            style: smallText),
                      ),
                    ]),
                  ),
                ])),
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('N° Chassis', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: bottom,
                        left: 5,
                        right: 5,
                        child: Text(reparation.nchassi ?? '', style: smallText),
                      ),
                    ]),
                  ),
                ])),
          ]),
          TableRow(children: [
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('Couleur', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: bottom,
                        left: 5,
                        right: 5,
                        child: Text(reparation.couleur ?? '', style: smallText),
                      ),
                    ]),
                  ),
                ])),
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('Killometrage', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: bottom,
                        left: 5,
                        right: 5,
                        child: Text(reparation.kilometrage?.toString() ?? '',
                            style: smallText),
                      ),
                    ]),
                  ),
                ])),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 2.5, 5),
                  child: Row(children: [
                    Text('Année', style: smallTextBold),
                    SizedBox(
                      width: width / 3,
                      height: height,
                      child: Stack(children: [
                        Positioned.fill(
                            bottom: bottomFill,
                            left: 0,
                            right: 2.5,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  dotsSpacer(),
                                ])),
                        Positioned(
                          bottom: bottom,
                          left: 5,
                          right: 5,
                          child: Text(reparation.anneeUtil?.toString() ?? '',
                              style: smallText),
                        ),
                      ]),
                    ),
                  ])),
              SizedBox(
                height: height + 10,
                child: VerticalDivider(
                    width: 1,
                    indent: 0,
                    endIndent: 0,
                    borderStyle: BorderStyle.solid),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 2.5, 5),
                  child: Row(children: [
                    Text('Carburant', style: smallTextBold),
                    SizedBox(
                      width: width,
                      height: height,
                      child: Stack(children: [
                        Positioned.fill(
                            bottom: bottomFill,
                            left: 0,
                            right: 2.5,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  dotsSpacer(),
                                ])),
                        Positioned(
                          bottom: bottom,
                          left: 5,
                          right: 5,
                          child: Text('${reparation.gaz?.toString() ?? '4'}/8',
                              style: smallText),
                        ),
                      ]),
                    ),
                  ])),
            ]),
            Padding(
                padding: const EdgeInsets.all(5),
                child: Row(children: [
                  Text('N° Moteur', style: smallTextBold),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          bottom: bottomFill,
                          left: 0,
                          right: 5,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dotsSpacer(),
                              ])),
                      Positioned(
                        bottom: 5,
                        left: 5,
                        right: 5,
                        child: Text(reparation.nmoteur ?? '', style: smallText),
                      ),
                    ]),
                  ),
                ])),
          ]),
        ]);
  }

  Widget branding(MemoryImage poLogo) {
    return SizedBox(
      height: PdfPageFormat.cm * 4,
      width: PdfPageFormat.cm * 19,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: PdfPageFormat.cm * 4.5,
              height: PdfPageFormat.cm * 1.5,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: PdfPageFormat.cm * 4.3,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Via ', style: TextStyle(color: orange)),
                            Spacer(),
                            Image(poLogo,
                                width: PdfPageFormat.cm * 2,
                                height: PdfPageFormat.cm * 2,
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter),
                          ]),
                    ),
                    Text('https://www.parcoto.com',
                        style: const TextStyle(
                            color: PdfColors.blue, fontSize: 10)),
                  ]),
            ),
          ]),
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

  double lightHeight = 0;
  double lightWidth = 0;

  final dx = 7;
  final dy = 7;

  int iconCodePoint = 0xe5cd;

  PdfColor orange = PdfColors.orange600;
  PdfColor orangeLight = PdfColors.orange300;
  PdfColor orangeDeep = PdfColors.orange900;
  Widget vehicleDamage() {

    return Container(
      width: 19*PdfPageFormat.cm,
      height: 5*PdfPageFormat.cm,
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(5),
        border: Border.all(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child:    carDrawing(),),
          Positioned(
            left: (180*0.4).px,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:
                  [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,

              crossAxisAlignment: CrossAxisAlignment.start,
              children: getTextListFromMap(reparation.etatActuel?.toJson()??EtatVehicle().toJson(),0),
            ),
            smallSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children:getTextListFromMap(reparation.etatActuel?.toJson()??EtatVehicle().toJson(),8),
            ),
            smallSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children:getTextListFromMap(reparation.etatActuel?.toJson()??EtatVehicle().toJson(),16),
            ),
                    smallSpace,
                    Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children:getTextListFromMap(reparation.etatActuel?.toJson()??EtatVehicle().toJson(),24),
            ),
                    smallSpace,

                    Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:getTextListFromMap(reparation.etatActuel?.toJson()??EtatVehicle().toJson(),32),
            ),
          ]))
        ]
      ),
    );
  }


  List<Widget> getTextListFromMap(Map<String,dynamic> map,int tranche){
    List<Widget> result=List.empty(growable: true);
    map.forEach((key, value) {
      if(key!='showOnList'){
        result.add(
          SizedBox(
            width: 2*PdfPageFormat.cm,
            child:
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(key.tr().capitalizeFirstLetter(),style: smallTextBold,),
                  dotsSpacer(),
                  if(value is num)
                    Text('${value.ceil()} %',style: smallText),
                  if(value is bool)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: orange
                        ),
                      ),
                      child: value?Icon(IconData(iconCodePoint,matchTextDirection: true),color: orangeDeep,size: 6,):null,
                    ),
                ]
            ))
            );
      }

    });
    return result.getRange(tranche, tranche+7<result.length?tranche+8:result.length).toList();
  }

  Widget carDrawing(){

    double scale=0.4;
    lightHeight = (25 - dx).px;
    lightWidth = (25 - dy).px;
    return Transform.scale(
        scale: scale,
        origin: PdfPoint(-200.px,0),
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
