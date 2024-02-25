import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/pdf_utilities.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../utilities/date_converter.dart';

class List2PDF {
  List<Map<String, dynamic>> list;

  PageOrientation orientation;

  final List<String> keysToInclude;

  final int firstPageLimit;
  final int midPagesLimit;
  String title;
  List2PDF(
      {required this.keysToInclude,
        required this.firstPageLimit,
        required this.midPagesLimit,
      this.orientation = PageOrientation.portrait,
      required this.list,
      required this.title});

  Future<Uint8List> generatePDF() async {
    await PDFTheming().initFontsAndLogos();

    final doc = Document();
    int nbrLines = list.length;

    var limit = (nbrLines - firstPageLimit) / midPagesLimit;

    int pageLeft = 1 + limit.ceil();
    if (nbrLines <= firstPageLimit) {
      var fpage = getFirstPage(0);
      doc.addPage(Page(
          orientation: orientation,
          theme: ThemeData(
            defaultTextStyle: const TextStyle(
              fontSize: 12,
            ),
          ),
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const EdgeInsets.all(20),
          build: (context) {
            return fpage;
          }));
    } else {
      List<Widget> pages = List.empty(growable: true);
      pages.add(getFirstPage(
        pageLeft,
      ));
      int i = 1;
      for (i = 1; i < pageLeft; i++) {
        pages.add(getOtherPage(pageLeft, i));
      }
      for (int j = 0; j < pages.length; j++) {
        doc.addPage(Page(
            orientation: orientation,
            theme: ThemeData(
              defaultTextStyle: const TextStyle(
                fontSize: 12,
              ),
            ),
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const EdgeInsets.all(20),
            build: (context) {
              return pages[j];
            }));
      }
    }
    return doc.save();
  }

  Table getDesiList(
    int page,
    int lastPage,
  ) {
    List<TableRow> l = [
      TableRow(
          decoration: const BoxDecoration(
            color: PdfColors.orange,
          ),
          children: getHeaders()),
    ];

    int nbrLines = list.length;
    List<int> maxis = getMax(nbrLines, page, lastPage);
    int lastElement = maxis[1];
    int max = maxis[0];

    for (int i = lastElement; i < max; i++) {
      l.add(getRow(i, nbrLines));
    }
    return Table(
      children: l,
      border: TableBorder.all(),
    );
  }

  List<int> getMax(int nbrLines, int page, int lastPage) {
    List<int> result = [0, 0];
    if (page == 0) {
      if (nbrLines <= firstPageLimit) {
        result[0] = list.length;
      } else {
        if (nbrLines <= firstPageLimit + midPagesLimit) {
          if (nbrLines <= firstPageLimit) {
            result[0] = list.length - 1;
          } else {
            result[0] = firstPageLimit;
          }
        } else {
          result[0] = firstPageLimit;
        }
      }
      result[1] = 0;
    }
    else if (page < lastPage-1) {

      if(page==1){
        result[1] = firstPageLimit;

      }
      else{
        result[1] = firstPageLimit + (midPagesLimit+1) * (page-1);
      }
      // middle pages

      result[0] = result[1] + midPagesLimit + 1;

      if (result[0] >= list.length) {
        result[0] = list.length - 1;
      }
    } else {
      // last page

        result[1] = firstPageLimit + (midPagesLimit+1) * (page - 1);
      result[0] = list.length;
    }

    return result;
  }

  List<Widget> getHeaders() {
    TextStyle th = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );
    List<Widget> result = List.empty(growable: true);

    result.add(Padding(
        padding: const EdgeInsets.all(2), child: Text('N°', style: th)));

    for (int i = 0; i < keysToInclude.length; i++) {
      result.add(
        Padding(
          padding: const EdgeInsets.all(2),
          child: Text(keysToInclude[i].tr(),
              style: th, textAlign: TextAlign.center),
        ),
      );
    }

    return result;
  }

  TableRow getRow(int index, int nbrLines) {
    const ts = TextStyle(
      fontSize: 10,
    );
    TableRow tr;

    List<Widget> wids = List.empty(growable: true);
    wids.add(
      Padding(
        padding: index == list.length - 1 && nbrLines <= 4
            ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
            : const EdgeInsets.fromLTRB(2, 1, 2, 1),
        child: Text(
          (index + 1).toString(),
          textDirection: TextDirection.rtl,
          style: ts,
        ),
      ),
    );
    for (int i = 0; i < keysToInclude.length; i++) {
      if (keysToInclude[i].toUpperCase().contains('DATE')) {
        wids.add(
          Padding(
            padding: index == list.length - 1 && nbrLines <= 4
                ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
                : const EdgeInsets.fromLTRB(2, 1, 2, 1),
            child: Text(
              DateConverter.formatDate(
                      list[index][keysToInclude[i]] ?? '2024'.toString(), 1) ??
                  '2024',
              textDirection: TextDirection.rtl,
              style: ts,
            ),
          ),
        );
      } else if (keysToInclude[i].toUpperCase().contains('DIRECTION')) {
        wids.add(
          Padding(
            padding: index == list.length - 1 && nbrLines <= 4
                ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
                : const EdgeInsets.fromLTRB(2, 1, 2, 1),
            child: Text(
              VehiclesUtilities.getDirection(list[index][keysToInclude[i]]),
              textDirection: TextDirection.rtl,
              softWrap: true,
              style: ts,
            ),
          ),
        );
      } else if (keysToInclude[i].toUpperCase().contains('APPARTENANCE')) {
        wids.add(
          Padding(
            padding: index == list.length - 1 && nbrLines <= 4
                ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
                : const EdgeInsets.fromLTRB(2, 1, 2, 1),
            child: Text(
              VehiclesUtilities.getAppartenance(list[index][keysToInclude[i]]),
              textDirection: TextDirection.rtl,
              softWrap: true,
              style: ts,
            ),
          ),
        );
      }
      else if (keysToInclude[i].toUpperCase().contains('FILLIALE')) {
        wids.add(
          Padding(
            padding: index == list.length - 1 && nbrLines <= 4
                ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
                : const EdgeInsets.fromLTRB(2, 1, 2, 1),
            child: Text(
              VehiclesUtilities.getAppartenance(list[index][keysToInclude[i]]),
              textDirection: TextDirection.rtl,
              softWrap: true,
              style: ts,
            ),
          ),
        );
      }
      else if (keysToInclude[i].toUpperCase().contains('VEHICULES')) {


        String vehicles='';
        if(list[index][keysToInclude[i]]!=null &&
            list[index][keysToInclude[i]].isNotEmpty){
          for(int v=0;v<list[index][keysToInclude[i]].length && v<3;v++){
            if(v==0){
              vehicles=list[index][keysToInclude[i]][v];
            }
            else{
              vehicles='$vehicles, ${list[index][keysToInclude[i]][v]}';
            }
          }
          if(list[index][keysToInclude[i]].length>3){
            vehicles='$vehicles, ...';
          }
        }

        wids.add(
          Padding(
            padding: index == list.length - 1 && nbrLines <= 4
                ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
                : const EdgeInsets.fromLTRB(2, 1, 2, 1),
            child: Text(
              vehicles,
              textDirection: TextDirection.rtl,
              softWrap: true,
              style: ts,
            ),
          ),
        );
      }


      else {
        wids.add(
          Padding(
            padding: index == list.length - 1 && nbrLines <= 4
                ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
                : const EdgeInsets.fromLTRB(2, 1, 2, 1),
            child: Text(
              list[index][keysToInclude[i]]=='null'?'':list[index][keysToInclude[i]] ?? ''.toString(),
              textDirection: TextDirection.rtl,
              style: ts,
            ),
          ),
        );
      }
    }
    tr = TableRow(children: wids);
    return tr;
  }

  Widget getFirstPage(int lastPage) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          getHeader(),
          bigSpace,
          bigSpace,
          getDesiList(
            0,
            lastPage,
          ),
          Spacer(),
          brandingAndPaging(0, lastPage)
        ]); // Center
  }

  Widget getOtherPage(int lastPage, int page) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getDesiList(
            page,
            lastPage,
          ),
          Spacer(),
          brandingAndPaging(page, lastPage)
        ]);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
              child: Text(title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
            ),
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
          ]),
    );
  }

  Widget brandingAndPaging(int page, int nbrPages) {
    return SizedBox(
      height: PdfPageFormat.cm * 1.25,
      width: PdfPageFormat.cm * 29,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (nbrPages > 1)
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
            if (nbrPages > 1) Spacer(),
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
