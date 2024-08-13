import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/serializables/client.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../serializables/reparation/reparation.dart';

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

class PdfUtilities {
  Client? p;

  Future<void> initPrestataire(Reparation reparation) async {
    p = await RepairProvider().getPrestataire(reparation.prestataire);
  }

  static List<Widget> getTextListFromMap(
      Map<String, dynamic> map, int debut, int fin,
      {double width = 3.7}) {
    List<Widget> result = List.empty(growable: true);
    map.forEach((key, value) {
      if (key != 'showOnList') {
        result.add(SizedBox(
            width: width * PdfPageFormat.cm,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    key.uppercaseFirst(),
                    style: smallText.copyWith(
                      fontSize: 9,
                    ),
                  ),
                  dotsSpacer(),
                  if (value is num)
                    Text('${value.ceil()} %',
                        style: smallText.copyWith(fontSize: 9)),
                  if (value is bool)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        border: Border.all(color: orange),
                      ),
                      child: value
                          ? Icon(
                              IconData(iconCodePoint, matchTextDirection: true),
                              color: orangeDeep,
                              size: 6,
                            )
                          : null,
                    ),
                ])));
      }
    });
    return result
        .getRange(debut, fin < result.length ? fin : result.length)
        .toList();
  }
}
