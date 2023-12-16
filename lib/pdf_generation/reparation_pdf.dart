
import 'package:flutter/services.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/pdf_utilities.dart';
import 'package:parc_oto/pdf_generation/reparation/vehicle_damage_pdf.dart';
import 'package:parc_oto/screens/entreprise.dart';
import '../serializables/prestataire.dart';
import '../serializables/reparation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

class ReparationPdf {
  final Reparation reparation;


  Prestataire? p;

  ReparationPdf({required this.reparation});

  PdfUtilities pdfUtilities=PdfUtilities();

  Future<Uint8List> getDocument() async {
    await Future.wait([
      pdfUtilities.initPrestataire(reparation),
      PDFTheming().initFontsAndLogos()
    ]);
    p=pdfUtilities.p;
    var doc = Document(
        theme: ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      icons: Font.ttf(icons!),
    ));


    doc.addPage(Page(
        margin: const EdgeInsets.all(PdfPageFormat.cm),
        build: (context) {
          return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                getHeader(),
                smallSpace,
                smallSpace,
                getPrestataire()??SizedBox(),
                smallSpace,
                smallSpace,
                getVehicleInfo(),
                smallSpace,
                smallSpace,
                VehicleDamagePDF(reparation).vehicleDamage(),
                smallSpace,
                smallSpace,
                getDesignations(),
                smallSpace,
                smallSpace,
                getRemarque(),
                Spacer(),
                branding(),
              ]);
        }));

    return doc.save();
  }
  Widget? getPrestataire() {
    if(reparation.prestataire!=null){
      return Container(
        padding: const EdgeInsets.all(5),
        width: 9 * PdfPageFormat.cm,
        height: PdfPageFormat.cm * 2.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Prestataire', style: smallTextBold.copyWith(color: orangeDeep)),
                    smallSpace,
                    Text(p?.nom ?? '',
                        style: smallText),
                  ]),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adresse', style: smallTextBold),
                    smallSpace,
                    Text(p?.adresse ?? '',
                        style: smallText),
                  ]),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Email', style: smallTextBold),
                dotsSpacer(),
                Text(p?.email ?? '', style: smallText),
                smallSpace,
                Text('Tél', style: smallTextBold),
                dotsSpacer(),
                Text(p?.telephone ?? '',
                    style: smallText),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('NIF', style: smallTextBold),
                dotsSpacer(),
                Text(p?.nif ?? '', style: smallText),
                smallSpace,
                Text('NIS', style: smallTextBold),
                dotsSpacer(),
                Text(p?.nis ?? '', style: smallText),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('ART', style: smallTextBold),
                dotsSpacer(),
                Text(p?.art ?? '', style: smallText),
                smallSpace,
                Text('RC', style: smallTextBold),
                dotsSpacer(),
                Text(p?.rc ?? '', style: smallText),
              ]),
            ]),
      );
    }
    return null;


  }

  Widget getDesignations(){
    return  SizedBox(
      height: PdfPageFormat.cm * 6.40,
      width: PdfPageFormat.cm * 21 - smallSpace.width!.toDouble(),
      child: Container(
          height: PdfPageFormat.cm * 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: const Border(
              top: BorderSide(color: PdfColors.orange),
              right: BorderSide(color: PdfColors.orange),
              left: BorderSide(color: PdfColors.orange),
              bottom: BorderSide(color: PdfColors.orange),
            ),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  height: PdfPageFormat.cm * 0.75,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: orange,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5))),
                  child: Row(children: [
                    SizedBox(
                      width: PdfPageFormat.cm * 10.7,
                      child:
                      Text('Désignation', style: smallTextBold),
                    ),
                    SizedBox(
                      width: PdfPageFormat.cm * 1,
                      child: Text('QTE',
                          style: smallTextBold,
                          textAlign: TextAlign.end),
                    ),
                    SizedBox(
                      width: PdfPageFormat.cm * 2.5,
                      child: Text('PRIX',
                          style: smallTextBold,
                          textAlign: TextAlign.end),
                    ),
                    SizedBox(
                      width: PdfPageFormat.cm * 1.8,
                      child: Text('TVA',
                          style: smallTextBold,
                          textAlign: TextAlign.end ),
                    ),
                    SizedBox(
                      width: PdfPageFormat.cm * 2.5,
                      child: Text('TTC',
                          style: smallTextBold,
                          textAlign: TextAlign.end),
                    ),
                  ]),
                ),
                getOneDesignationLine(0),
                getOneDesignationLine(1),
                getOneDesignationLine(2),
                getOneDesignationLine(3),
                getOneDesignationLine(4),
                getOneDesignationLine(5),
                getOneDesignationLine(6),
                getOneDesignationLine(7),
                getOneDesignationLine(8),
                getOneDesignationLine(9),
              ])),
    );
  }


  Widget getOneDesignationLine(int index){
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        height: PdfPageFormat.cm * 0.5,
        padding: const EdgeInsets.symmetric(horizontal: 3,vertical: 4.5),
        decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                style: BorderStyle.dotted
              ),
            )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: (reparation.designations?.length??0)>index?[
            SizedBox(
              width: PdfPageFormat.cm * 11,
              child:
              Text(reparation.designations![index].designation, style: smallText),
            ),
            SizedBox(
              width: PdfPageFormat.cm * 1,
              child: Text(numberFormat2.format(reparation.designations![index].qte),
                  style: smallText,
                  textAlign: TextAlign.center),
            ),
            SizedBox(
              width: PdfPageFormat.cm * 2.5,
              child: Text(prixFormat.format(reparation.designations![index].prix),
                  style: smallText,
                  textAlign: TextAlign.end),
            ),
            SizedBox(
              width: PdfPageFormat.cm * 1.5,
              child: Text(numberFormat3.format(reparation.designations![index].tva),
                  style: smallText,
                  textAlign: TextAlign.end),
            ),
            SizedBox(
              width: PdfPageFormat.cm * 2.5,
              child: Text(prixFormat.format(reparation.designations![index].getTTC()),
                  style: smallTextBold,
                  textAlign: TextAlign.end),
            ),
          ]:[],
        ),
      ),
    );
  }

  Widget getRemarque(){
   return Container(
        width: 8 * PdfPageFormat.cm,
        height: 2   * PdfPageFormat.cm,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(),
        ),
        child: Column(children: [
          Text('Remarques', style: smallTextBold),
          smallSpace,
          SizedBox(
            height: PdfPageFormat.cm * 1.5,
            child: Stack(
                children: [
                  Positioned.fill(
                      child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            dotsSpacer(),
                            dotsSpacer(),
                            dotsSpacer(),
                            dotsSpacer(),
                          ])),
                  Positioned.fill(
                      top: -1.5,
                      left: 2,
                      right: 2,
                      child: Text(reparation.remarque??'',style: smallText))
                ]),
          ),
        ]));
  }

  Widget getHeader() {
    return SizedBox(
      height: PdfPageFormat.cm * 2.7,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image(entrepriseLogo!,
                width: PdfPageFormat.cm * 3,
                height: PdfPageFormat.cm * 3,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter),
            Container(
              padding: const EdgeInsets.all(5),
              width: 9 * PdfPageFormat.cm,
              height: PdfPageFormat.cm * 2.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(MyEntrepriseState.p?.nom ?? '',
                        style: smallTextBold.copyWith(color: orangeDeep)),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget branding() {
    return SizedBox(
      height: PdfPageFormat.cm * 1.5,
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
                            Image(poLogo!,
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

}
