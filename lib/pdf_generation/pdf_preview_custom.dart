import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/pdf_generation/reparation_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';

import '../serializables/reparation/reparation.dart';

class PdfPreviewPO extends StatelessWidget {
  final Reparation reparation;
  const PdfPreviewPO({super.key, required this.reparation});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      
      content: PdfPreview(
        maxPageWidth: 430.px,
        shouldRepaint: true,
        pdfFileName: 'ordre${numberFormat.format(reparation.numero)}',
        initialPageFormat: PdfPageFormat.a4,
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: false,
        allowSharing: false,
        dynamicLayout: false,
        loadingWidget: const ProgressBar(
          strokeWidth: 8,
        ),
        build: (PdfPageFormat format) {
          return ReparationPdf(reparation: reparation).getDocument();
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
            onPressed: saveFile,
          ),
          PdfPreviewAction(
              icon: const Icon(
                FluentIcons.share,
                color: Colors.white,
              ),
              onPressed: (context, futureFile, pageFormat) async {
                Share.shareXFiles(
                  [XFile.fromData(await futureFile(pageFormat))],
                  subject: 'ordre${numberFormat.format(reparation.numero)}',
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
      constraints: BoxConstraints.loose(Size(500.px,700.px)),
    );
  }

  void saveFile(
      BuildContext s,
      FutureOr<Uint8List> Function(PdfPageFormat) futureFile,
      PdfPageFormat pageFormat) async {
    if (DeviceType.android == Device.deviceType ||
        Device.deviceType == DeviceType.ios || kIsWeb) {
      FileSaver.instance.saveFile(
          'ordre${numberFormat.format(reparation.numero)}',
          await futureFile(pageFormat),
          'pdf',
          mimeType:MimeType.PDF);
    } else {
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: "save".tr(),
        fileName: 'ordre${numberFormat.format(reparation.numero)}',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (path != null) {
        File f = File(path);
        f.writeAsBytes(await futureFile(pageFormat), mode: FileMode.write);
      }
    }
  }
}
