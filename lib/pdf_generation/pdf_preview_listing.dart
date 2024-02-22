import 'dart:async';
import 'package:pdf/widgets.dart' show PageOrientation;
import 'package:universal_html/html.dart' as html;
import 'dart:io';
import 'package:document_file_save_plus/document_file_save_plus.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';

import 'generate_list.dart';

class PdfPreviewListing extends StatelessWidget {
  final List<Map<String,dynamic>> list;
  final List<String>keysToInclude;
  final PageOrientation orientation;
  final String name;
  const PdfPreviewListing({super.key,this.orientation=PageOrientation.portrait,
  required this.list,this
      .name='List', required this.keysToInclude});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      content: PdfPreview(
        maxPageWidth: orientation==PageOrientation.portrait?550.px:2000.px,
        shouldRepaint: false,
        pdfFileName: name,
        initialPageFormat: PdfPageFormat.a4,
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: false,
        allowSharing: false,
        dpi: 200,
        dynamicLayout: true,
        loadingWidget: const ProgressBar(
          strokeWidth: 8,
        ),
        build: (PdfPageFormat format) {
          return List2PDF(
            keysToInclude: keysToInclude,
            orientation: orientation,
            list: list,
            title: name,
          ).generatePDF();
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
                  subject: name,
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
      constraints: orientation==PageOrientation.portrait?BoxConstraints.loose
        (Size(600
          .px, 700.px)):BoxConstraints.loose
        (Size(800
          .px, 600.px)),
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
          '$name.pdf',
          "appliation/pdf");
    } else if (kIsWeb) {
      saveFileWeb(
          await futureFile(pageFormat),
          '$name.pdf');
    } else {
      String? path = await FilePicker.platform.saveFile(
        dialogTitle: "save".tr(),
        fileName: '$name.pdf',
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
