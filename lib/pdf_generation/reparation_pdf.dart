import 'package:flutter/services.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/pdf_utilities.dart';
import 'package:parc_oto/pdf_generation/reparation/vehicle_damage_pdf.dart';
import 'package:parc_oto/pdf_generation/reparation/vehicle_entretien_pdf.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/entreprise.dart';
import '../serializables/prestataire.dart';
import '../serializables/reparation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../utilities/num_to_word.dart';

class ReparationPdf {
  final Reparation reparation;

  Prestataire? p;

  ReparationPdf({required this.reparation});

  PdfUtilities pdfUtilities = PdfUtilities();

  Future<Uint8List> getDocument() async {
    await Future.wait([
      pdfUtilities.initPrestataire(reparation),
      PDFTheming().initFontsAndLogos()
    ]);
    p = pdfUtilities.p;
    var doc = Document(
      theme: ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        icons: icons!,
      ),
      title: 'ordre ${reparation.numero}',
      author:
          ClientDatabase.me.value?.name ?? ClientDatabase.me.value?.email ?? '',
      producer: 'ParcOto',
    );

    int nbrPages = getNumberOfPages();

    int lastIndex = 0;
    int nbrTotal = reparation.designations?.length ?? 0;

    List<Widget> pages = List.empty(growable: true);
    for (int i = 0; i < nbrPages; i++) {
      pages.add(getPageContent(i, nbrPages, lastIndex));
      if (i == 0) {
        lastIndex += nbrPageOne + pageAdition;
        while (lastIndex >= nbrTotal) {
          lastIndex--;
        }
      } else {
        lastIndex += nbrMaxMiddlePages;
        while (lastIndex >= nbrTotal) {
          lastIndex--;
        }
      }
    }

    for (int j = 0; j < pages.length; j++) {
      doc.addPage(
          Page(
            margin: const EdgeInsets.all(PdfPageFormat.cm),
            build: (context) {
              return pages[j];
            },
          ),
          index: j);
    }

    return doc.save();
  }

  Widget getPageContent(int page, int nbrPages, int lastIndex) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getHeader(),
          bigSpace,
          if (page == 0) getPrestataire() ?? SizedBox(),
          if (page == 0) bigSpace,
          if (page == 0) getVehicleInfo(),
          if (page == 0) bigSpace,
          if (page == 0) VehicleDamagePDF(reparation).vehicleDamage(),
          if (page == 0) bigSpace,
          if (page == 0) VehicleEntretienPDF(reparation).vehicleEntretien(),
          if (page == 0) bigSpace,
          getDesignations(page, nbrPages, lastIndex),
          if (page == nbrPages - 1) getPrixInLetter(),
          if (page == nbrPages - 1) bigSpace,
          if (page == nbrPages - 1) getRemarqueAndSignature(),
          Spacer(),
          brandingAndPaging(page, nbrPages),
        ]);
  }

  Widget? getPrestataire() {
    if (reparation.prestataire != null) {
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
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Prestataire',
                    style: smallTextBold.copyWith(color: orangeDeep)),
                smallSpace,
                Text(p?.nom ?? '', style: smallText),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Adresse', style: smallTextBold),
                smallSpace,
                Text(p?.adresse ?? '', style: smallText),
              ]),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Email', style: smallTextBold),
                dotsSpacer(),
                Text(p?.email ?? '', style: smallText),
                smallSpace,
                Text('Tél', style: smallTextBold),
                dotsSpacer(),
                Text(p?.telephone ?? '', style: smallText),
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

  int nbrMaxMiddlePages = 43;
  int nbrPageOne = 8;

  int pageAdition = 7;
  int nbrLastPage = 35;

  int getNumberOfPages() {
    int nbr = reparation.designations?.length ?? 0;
    if (nbr <= (nbrPageOne + nbrLastPage + pageAdition)) {
      if (nbr <= nbrPageOne) {
        return 1;
      } else {
        return 2;
      }
    } else {
      return ((nbr - nbrPageOne - nbrLastPage - pageAdition) /
                  nbrMaxMiddlePages)
              .ceil() +
          2;
    }
  }

  Widget getDesignations(int page, int nbrPages, int lastIndex) {
    if (page == 0) {
      return getFirstPageDesignations(nbrPages);
    } else if (page == nbrPages - 1) {
      return getLastPageDesignations(nbrPages, lastIndex);
    } else {
      return getMiddlePage(nbrPages, page, lastIndex);
    }
  }

  Widget designationHeader() {
    return Container(
      height: PdfPageFormat.cm * 0.75,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(children: [
        SizedBox(
          width: PdfPageFormat.cm * 11.22,
          child: Text('Observations', style: smallTextBold),
        ),
        SizedBox(
          width: PdfPageFormat.cm * 1,
          child: Text('QTE', style: smallTextBold, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: PdfPageFormat.cm * 2.5,
          child:
              Text('MONTANT', style: smallTextBold, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: PdfPageFormat.cm * 1.5,
          child: Text('TVA', style: smallTextBold, textAlign: TextAlign.end),
        ),
        SizedBox(
          width: PdfPageFormat.cm * 2.5,
          child: Text('TTC', style: smallTextBold, textAlign: TextAlign.end),
        ),
      ]),
    );
  }

  Widget getLastPageDesignations(int nbrPages, int lastIndex) {
    double height = (nbrLastPage + 3) * 0.5 + 0.75 + 0.5;

    return SizedBox(
      height: PdfPageFormat.cm * height,
      width: PdfPageFormat.cm * 21 - smallSpace.width!.toDouble(),
      child: SizedBox(
          height: PdfPageFormat.cm * 10,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            designationHeader(),
            ...List.generate(nbrLastPage, (index) {
              return getOneDesignationLine(
                  index + lastIndex, nbrPages - 1, nbrPages);
            }),
            getTotal(),
          ])),
    );
  }

  Widget getMiddlePage(int nbrPages, int page, int lastIndex) {
    double height = (nbrMaxMiddlePages) * 0.5 + 0.75 + 0.5;

    return SizedBox(
      height: PdfPageFormat.cm * height,
      width: PdfPageFormat.cm * 21 - smallSpace.width!.toDouble(),
      child: SizedBox(
          height: PdfPageFormat.cm * 10,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            designationHeader(),
            ...List.generate(nbrMaxMiddlePages, (index) {
              return getOneDesignationLine(lastIndex + index, page, nbrPages);
            }),
          ])),
    );
  }

  Widget getFirstPageDesignations(int nbrPages) {
    int nbrLines = nbrPages == 1 ? nbrPageOne : nbrPageOne + pageAdition;
    double height = nbrLines * 0.5 + 0.75 + 0.5 + (nbrPages == 1 ? 3 : 0) * 0.5;

    return SizedBox(
      height: PdfPageFormat.cm * height,
      width: PdfPageFormat.cm * 21 - smallSpace.width!.toDouble(),
      child: SizedBox(
          height: PdfPageFormat.cm * 10,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            designationHeader(),
            ...List.generate(nbrLines, (index) {
              return getOneDesignationLine(index, 0, nbrPages);
            }),
            if (nbrPages == 1) getTotal(),
          ])),
    );
  }

  Widget getOneDesignationLine(int index, int page, int nbrPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        height: PdfPageFormat.cm * 0.5,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4.5),
        decoration: const BoxDecoration(
            border: Border(
          bottom: BorderSide(style: BorderStyle.dotted),
        )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: (reparation.designations == null) ||
                  (reparation.designations!.length) <= index ||
                  (page == nbrPages - 2 &&
                      index == reparation.designations!.length - 1)
              ? []
              : [
                  SizedBox(
                    width: PdfPageFormat.cm * 11,
                    child: Text(reparation.designations![index].designation,
                        style: smallText),
                  ),
                  SizedBox(
                    width: PdfPageFormat.cm * 1,
                    child: Text(
                        numberFormat2
                            .format(reparation.designations![index].qte),
                        style: smallText,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: PdfPageFormat.cm * 2.5,
                    child: Text(
                        prixFormat.format(reparation.designations![index].prix),
                        style: smallText,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: PdfPageFormat.cm * 1.5,
                    child: Text(
                        numberFormat3
                            .format(reparation.designations![index].tva),
                        style: smallText,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: PdfPageFormat.cm * 2.5,
                    child: Text(
                        prixFormat
                            .format(reparation.designations![index].getTTC()),
                        style: smallTextBold,
                        textAlign: TextAlign.end),
                  ),
                ],
        ),
      ),
    );
  }

  Widget getTotal() {
    double width = 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          height: PdfPageFormat.cm * 0.5,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4.5),
          decoration: const BoxDecoration(
              border: Border(
            bottom: BorderSide(style: BorderStyle.dotted),
          )),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(
              width: PdfPageFormat.cm * width,
              child: Text('Montant total', style: smallTextBold),
            ),
            SizedBox(
              width: PdfPageFormat.cm * width,
              child: Text(prixFormat.format(reparation.getPrixTotal()),
                  style: smallText, textAlign: TextAlign.end),
            ),
          ]),
        ),
        Container(
          height: PdfPageFormat.cm * 0.5,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4.5),
          decoration: const BoxDecoration(
              border: Border(
            bottom: BorderSide(style: BorderStyle.dotted),
          )),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(
              width: PdfPageFormat.cm * width,
              child: Text('TVA', style: smallTextBold),
            ),
            SizedBox(
              width: PdfPageFormat.cm * width,
              child: Text(prixFormat.format(reparation.getPrixTva()),
                  style: smallText, textAlign: TextAlign.end),
            ),
          ]),
        ),
        Container(
          height: PdfPageFormat.cm * 0.5,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4.5),
          decoration: const BoxDecoration(
              border: Border(
            bottom: BorderSide(style: BorderStyle.dotted),
          )),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(
              width: PdfPageFormat.cm * width,
              child: Text('Montant TTC', style: smallTextBold),
            ),
            SizedBox(
              width: PdfPageFormat.cm * width,
              child: Text(prixFormat.format(reparation.getPrixTTC()),
                  style: smallTextBold, textAlign: TextAlign.end),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget getPrixInLetter() {
    int getCentimes = (double.parse(prixFormat.format(
                reparation.getPrixTTC() - reparation.getPrixTTC().toInt()).replaceAll('DA', '').replaceAll(',', '.')) *
            100)
        .toInt();
    return Container(
      height: 0.5 * PdfPageFormat.cm,
      width: 20 * PdfPageFormat.cm,
      padding: const EdgeInsets.fromLTRB(2, -7, 2, 2),
      child: Text(
          'Le montant total de cet ordre est arreté à ${numToLetters(reparation.getPrixTTC().floor())} dinar${reparation.getPrixTTC().floor() > 1 ? 's' : ''}  ${getCentimes != 0 ? 'et ${numToLetters(getCentimes)} centime${getCentimes > 1 ? 's' : ''}' : ''}'
              .toUpperCase(),
          style: smallTextBold),
    );
  }

  Widget getRemarqueAndSignature() {
    return Container(
      width: 20 * PdfPageFormat.cm,
      height: 2 * PdfPageFormat.cm,
      child: Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(),
            ),
            width: 9 * PdfPageFormat.cm,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remarques', style: smallTextBold),
                  smallSpace,
                  SizedBox(
                    height: PdfPageFormat.cm * 1.5,
                    child: Stack(children: [
                      Positioned.fill(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          child:
                              Text(reparation.remarque ?? '', style: smallText))
                    ]),
                  ),
                ])),
        Spacer(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            width: 9 * PdfPageFormat.cm,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cachet et signature', style: smallTextBold),
                ])),
      ]),
    );
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

  Widget brandingAndPaging(int page, int nbrPages) {
    return SizedBox(
      height: PdfPageFormat.cm * 1.25,
      width: PdfPageFormat.cm * 21,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (nbrPages != 1)
              Container(
                width: PdfPageFormat.cm * 2,
                height: PdfPageFormat.cm * 0.75,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: orangeDeep,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('Page ${page + 1}/$nbrPages', style: smallTextBold),
              ),
            if (nbrPages != 1) Spacer(),
            Container(
              width: PdfPageFormat.cm * 4.5,
              height: PdfPageFormat.cm * 1.25,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: PdfPageFormat.cm * 4.5,
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
