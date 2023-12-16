import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';


final numberFormat = NumberFormat('00000000', 'fr');
final numberFormat2 = NumberFormat('00', 'fr');
final numberFormat3 = NumberFormat.currency(locale:'fr',symbol: '%',decimalDigits: 2);
final prixFormat = NumberFormat.currency(locale: 'fr',symbol: 'DA',decimalDigits: 2);
final dateFormat = DateFormat('dd MMMM yyyy', 'fr');
final smallSpace =
SizedBox(width: PdfPageFormat.cm * 0.1, height: PdfPageFormat.cm * 0.1);

late TextStyle bigTitle;
late TextStyle kindaBigText;
late TextStyle kindaBigTextBold;
late TextStyle smallTextBold;
late TextStyle smallText;

PdfColor orange = PdfColors.orange600;
PdfColor orangeLight = PdfColors.orange300;
PdfColor orangeDeep = PdfColors.orange900;

int iconCodePoint = 0xe5cd;

MemoryImage? entrepriseLogo;
MemoryImage? poLogo;
Font? baseFont;
Font? boldFont;
ByteData? icons;
class PDFTheming{

  PDFTheming(){
    initFonts();
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
      fontSize: 9,
      letterSpacing: -0.12,
    );
    smallTextBold = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.12,
    );
  }

  Future<void> getEntrepriseLogo() async{
    entrepriseLogo ??= MemoryImage(
      await File('mylogo.png').readAsBytes(),
    );
  }

  Future<void> getPoLogo() async{
    poLogo ??= MemoryImage((await rootBundle.load('assets/images/logo.webp'))
        .buffer
        .asUint8List());
  }

  Future<void> getBaseFont() async{
    baseFont??=await PdfGoogleFonts.rubikRegular();
  }

  Future<void> getBoldFont() async{
    boldFont??=await PdfGoogleFonts.rubikSemiBold();
  }
  Future<void> initIcons() async{
    icons=await rootBundle.load('assets/images/materialicon.ttf');
  }
  Future<void> initFontsAndLogos() async{
    await Future.wait(
        [
          getBaseFont(),
          getBoldFont(),
          getPoLogo(),
          initIcons(),
          getEntrepriseLogo(),
        ]
    );
  }
}