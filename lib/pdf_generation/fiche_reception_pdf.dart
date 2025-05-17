import 'package:flutter/services.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/pdf_utilities.dart';
import 'package:parc_oto/pdf_generation/reparation/vehicle_damage_pdf.dart';
import 'package:parc_oto/pdf_generation/reparation/vehicle_entretien_pdf.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../serializables/reparation/fiche_reception.dart';

class FicheReceptionPdf {
  final FicheReception fiche;
  final List<Uint8List?>? images;

  FicheReceptionPdf({required this.fiche,this.images});

  PdfUtilities pdfUtilities = PdfUtilities();

  Future<Uint8List> getDocument() async {
    await Future.wait([
      PDFTheming().initFontsAndLogos()
    ]);
    if(images!=null){
      pdfUtilities.images=images;
    }
    else{
      await pdfUtilities.initImages(fiche);

    }
    var doc = Document(
      theme: ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        icons: icons!,
      ),
      title: 'Fiche ${fiche.numero}',
      author:
      DatabaseGetter.me.value?.name ?? DatabaseGetter.me.value?.email ?? '',
      producer: 'ParcOto',
    );


      doc.addPage(
          Page(
            margin: const EdgeInsets.all(PdfPageFormat.cm),
            build: (context) {
              return getPageContent();
            },
          ),);
    return doc.save();
  }


  bool etatEmpty() {
    if(fiche.showEtat){
      return false;
    }
    if (fiche.etatActuel == null|| !fiche.showEtat) {
      return true;
    } else {
      bool result = true;
      fiche.etatActuel!.toJson().forEach((key, value) {
        if (key == 'avdp' || key == 'avgp' || key == 'ardp' || key == 'argp') {
          if (value != 100) {
            result = false;
            return;
          }
        } else {
          if (value == true) {
            result = false;
            return;
          }
        }
      });
      return result;
    }
  }

  bool imagesEmpty(){
    if(fiche.showImages){
      return false;
    }
    if (pdfUtilities.images==null || pdfUtilities.images!.isEmpty|| !fiche.showImages) {
      return true;
    } else {
      bool result = true;
      for(int i=0;i<pdfUtilities.images!.length;i++){
       if(pdfUtilities.images![i] != null){
         result = false;
         break;
       }
      }
      return result;
    }
  }

  Widget getPageContent() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          getHeader(),
          bigSpace,
          getVehicleInfo(),
          bigSpace,
          if (!etatEmpty())
            VehicleDamagePDF(fiche).vehicleDamage(),
          if (!etatEmpty()) bigSpace,
          if (!entretienEmpty())
            VehicleEntretienPDF(fiche:fiche).vehicleEntretien(),
          if (!entretienEmpty()) bigSpace,
          if(!imagesEmpty())
            imageContainer(),
          Spacer(),
          getRemarqueAndSignature(),
          smallSpace,
          brandingAndPaging(),
        ]);
  }
  Widget imageContainer(){
    double imageHeight=3*PdfPageFormat.cm;
    if(etatEmpty()){
      imageHeight+=3*PdfPageFormat.cm;
    }
    if(entretienEmpty()){
      imageHeight+=2.5*PdfPageFormat.cm;
    }
    if(imagesEmpty()){
      return SizedBox();
    }
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            0: const FlexColumnWidth(5),
            1: const FlexColumnWidth(5),
            2: const FlexColumnWidth(5),
          },
          children:[
            TableRow(
              children: [
                Text('Photos des dégats', style: kindaBigTextBold),
              ],
            ),
            TableRow(
                children: [
                  SizedBox(
                    height: imageHeight,
                    child:Center(child:pdfUtilities.images!.isNotEmpty && pdfUtilities.images![0]!=null && pdfUtilities.images![0]!.isNotEmpty?
                    Image(MemoryImage(
                        pdfUtilities.images![0]!),):Text('1')),
                  ),
                  SizedBox(
                      height: imageHeight,
                      child: Center(child:pdfUtilities.images!.isNotEmpty && pdfUtilities.images![1]!=null&& pdfUtilities.images![1]!.isNotEmpty?
                      Image(MemoryImage(pdfUtilities.images![1]!)):Text('2'),))
                ]),
            TableRow(

                children: [
                  SizedBox(
                    height: imageHeight,
                    child:
                    Center(child:
                    pdfUtilities.images!.isNotEmpty &&pdfUtilities.images![2]!=null&& pdfUtilities.images![2]!.isNotEmpty?
                    Image(MemoryImage(
                        pdfUtilities.images![2]!),):Text('3'),),),
                  SizedBox(
                      height: imageHeight,
                      child:Center(child:
                      pdfUtilities.images!.isNotEmpty &&pdfUtilities.images![3]!=null&& pdfUtilities.images![3]!.isNotEmpty?
                      Image(MemoryImage(pdfUtilities.images![3]!)):Text('4'),))
                ]),
          ]
      )
    );

  }


  bool entretienEmpty() {
    if(fiche.showEntretien){
      return false;
    }
    else{
      if (fiche.entretien == null || !fiche.showEntretien) {
        return true;
      } else {
        List values = fiche.entretien!.toJson().values.toList();
        for (int i = 0; i < values.length; i++) {
          if (values[i] == true) {
            return false;
          }
        }
        return true;
      }
    }

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
                          Text(fiche.remarque ?? '', style: smallText))
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
                width: PdfPageFormat.cm * 2.8,
                height: PdfPageFormat.cm * 2.8,
                fit: BoxFit.contain,
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
                Text('FICHE DE RECEPTION', style: bigTitle),
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
                                        Text('Fiche #',
                                            style: kindaBigTextBold),
                                        dotsSpacer(),
                                        Text(
                                            numberFormat
                                                .format(fiche.numero),
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
                                        Text(dateFormat.format(fiche.dateEntre),
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
    return
      Column(
          children: [
            Table(
                columnWidths: {
                  0: const FlexColumnWidth(3),
                  1: const FlexColumnWidth(3),
                  2: const FlexColumnWidth(5),
                  3: const FlexColumnWidth(5),
                },
                border: const TableBorder(
                  verticalInside: BorderSide(),
                ),
                children: [
                  TableRow(
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                      children: [
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
                                    child: Text(fiche.marque ?? '', style: smallText),
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
                                    child: Text(fiche.modele ?? '', style: smallText),
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
                                    child: Text(fiche.vehiculemat ?? '',
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
                                    child: Text(fiche.nchassi ?? '', style: smallText),
                                  ),
                                ]),
                              ),
                            ])),
                      ]),
                  TableRow(
                      decoration: BoxDecoration(
                        border: Border.all(),
                      ),
                      children: [
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
                                    child: Text(fiche.couleur ?? '', style: smallText),
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
                                    child: Text(fiche.kilometrage?.toString() ?? '',
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
                                      child: Text(fiche.anneeUtil?.toString() ?? '',
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
                                      child: Text('${fiche.gaz?.toString() ?? '4'}/8',
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
                                    child: Text(fiche.nmoteur ?? '', style: smallText),
                                  ),
                                ]),
                              ),
                            ])),
                      ]),
                ]),
            Table(
                columnWidths: {
                  0: const FlexColumnWidth(6),
                  1: const FlexColumnWidth(5),
                  2: const FlexColumnWidth(5),
                },
                border: const TableBorder(
                  verticalInside: BorderSide(),
                ),
                children: [
                  TableRow(
                      decoration: BoxDecoration(
                        borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(5)),
                        border: Border.all(),
                      ),
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(children: [
                              Text('Mat. conducteur', style: smallTextBold),
                              SizedBox(
                                width: width*1.5,
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
                                    child: Text(fiche.matriculeConducteur ?? '',
                                        style: smallText),
                                  ),
                                ]),
                              ),
                            ])),
                        Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(children: [
                              Text('Nom', style: smallTextBold),
                              SizedBox(
                                width: width*1.5,
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
                                    child: Text(fiche.nomConducteur ?? '',
                                        style: smallText),
                                  ),
                                ]),
                              ),
                            ])),
                        Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(children: [
                              Text('Prénom', style: smallTextBold),
                              SizedBox(
                                width: width*1.5,
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
                                    child: Text(fiche.prenomConducteur ?? '',
                                        style: smallText),
                                  ),
                                ]),
                              ),
                            ])),
                      ]),
                ]),
          ]
      );
  }

  Widget brandingAndPaging() {
    return SizedBox(
      height: PdfPageFormat.cm * 1.25,
      width: PdfPageFormat.cm * 21,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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
