import 'dart:async';


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
import '../utilities/file_manipulation.dart' as file_utils;
import '../serializables/reparation/reparation.dart';
import 'fiche_reception_pdf.dart';

class PdfPreviewPO extends StatelessWidget {
  final Reparation? reparation;
  final FicheReception? fiche;
  final List<Uint8List?>? images;
  const PdfPreviewPO({super.key, this.reparation, this.fiche, this.images});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      content: PdfPreview(
        maxPageWidth: 550.px,
        shouldRepaint: true,
        pdfFileName: reparation != null
            ? 'ordre${numberFormat.format(reparation!.numero)}'
            : 'fiche${numberFormat.format(fiche!.numero)}',
        initialPageFormat: PdfPageFormat.a4,
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: false,
        allowSharing: false,
        dpi: 400,
        dynamicLayout: true,
        loadingWidget: const ProgressBar(strokeWidth: 8),
        build: (PdfPageFormat format) {
          if (reparation != null) {
            return ReparationPdf(reparation: reparation!).getDocument();
          } else {
            return FicheReceptionPdf(
              fiche: fiche!,
              images: images,
            ).getDocument();
          }
        },
        actions: [
          const PdfPrintAction(
            icon: Icon(FluentIcons.print, color: Colors.white),
          ),
          PdfPreviewAction(
            icon: const Icon(FluentIcons.save, color: Colors.white),
            onPressed: saveThisFile,
          ),
          PdfPreviewAction(
            icon: const Icon(FluentIcons.share, color: Colors.white),
            onPressed: (context, futureFile, pageFormat) async {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile.fromData(await futureFile(pageFormat))],
                  subject: reparation != null
                      ? 'ordre${numberFormat.format(reparation!.numero)}'
                      : 'fiche${numberFormat.format(fiche!.numero)}',
                ),
              );
            },
          ),
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
    PdfPageFormat pageFormat,
  ) async {
    final fileName = reparation != null
        ? 'ordre${numberFormat.format(reparation!.numero)}'
        : 'fiche${numberFormat.format(fiche!.numero)}';
    await file_utils.saveThisFile(
      await futureFile(pageFormat),
      fileName,
      'pdf',
      'application/pdf',
    );
  }
}
