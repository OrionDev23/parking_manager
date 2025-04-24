import 'dart:async';
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:document_file_save_plus/document_file_save_plus.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/reparation_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';

import '../serializables/reparation/fiche_reception.dart';
import '../serializables/reparation/reparation.dart';
import 'fiche_reception_pdf.dart';

class PdfPreviewPO extends StatelessWidget {
  final Reparation? reparation;
  final FicheReception? fiche;
  const PdfPreviewPO({super.key, this.reparation,this.fiche});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      content: PdfPreview(
        maxPageWidth: 550.px,
        shouldRepaint: true,
        pdfFileName: reparation!=null?'ordre${numberFormat.format(reparation!.numero)}':'fiche${numberFormat.format(fiche!.numero)}',
        initialPageFormat: PdfPageFormat.a4,
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: false,
        allowSharing: false,
        dpi: 400,
        dynamicLayout: true,
        loadingWidget: const ProgressBar(
          strokeWidth: 8,
        ),
        build: (PdfPageFormat format) {
          if(reparation!=null){
            return ReparationPdf(reparation: reparation!).getDocument();

          }
          else{
            return FicheReceptionPdf(fiche: fiche!).getDocument();
          }
        },
        actions: [
          const PdfPrintAction(
            icon: Icon(
              FluentIcons.print,
              color: Colors.white,
            ),
          ),
          PdfPreviewAction(
            icon: const Icon(
              FluentIcons.save,
              color: Colors.white,
            ),
            onPressed: saveThisFile,
          ),
          PdfPreviewAction(
              icon: const Icon(
                FluentIcons.share,
                color: Colors.white,
              ),
              onPressed: (context, futureFile, pageFormat) async {
                Share.shareXFiles(
                  [XFile.fromData(await futureFile(pageFormat))],
                  subject: reparation!=null?'ordre${numberFormat.format(reparation!.numero)}':'fiche${numberFormat.format(fiche!.numero)}',
                );
              }),
          PdfPreviewAction(
            icon: const Text(
              'fermer',
              style: TextStyle(color: Colors.white),
            ).tr(),
            onPressed: (cont, s, p) {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      constraints: BoxConstraints.loose(Size(600.px, 700.px)),
    );
  }

  void saveThisFile(
      BuildContext s,
      FutureOr<Uint8List> Function(PdfPageFormat) futureFile,
      PdfPageFormat pageFormat) async {
    if (DeviceType.android == Device.deviceType ||
        Device.deviceType == DeviceType.ios) {
      DocumentFileSavePlus().saveFile(
          await futureFile(pageFormat),
          reparation!=null?'ordre${numberFormat.format(reparation!.numero)}.pdf':'fiche${numberFormat.format(fiche!.numero)}}.pdf',
          "appliation/pdf");
    } else if (kIsWeb) {
      saveFileWeb(
          await futureFile(pageFormat),
          reparation!=null?'ordre${numberFormat.format(reparation!.numero)}.pdf':'fiche${numberFormat.format(fiche!.numero)}}.pdf',);
    } else {
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: "save".tr(),
        fileName: reparation!=null?'ordre${numberFormat.format(reparation!.numero)}.pdf':'fiche${numberFormat.format(fiche!.numero)}}.pdf',

        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (path != null) {
        File f = File(path);
        f.writeAsBytes(await futureFile(pageFormat), mode: FileMode.write);
      }
    }
  }

  void saveFileWeb(Uint8List bytes, String name) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = name;
    html.document.body?.children.add(anchor);

// download
    anchor.click();

// cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
