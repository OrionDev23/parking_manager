import 'package:parc_oto/serializables/entretien_vehicle.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../../serializables/reparation.dart';
import '../pdf_theming.dart';
import '../pdf_utilities.dart';

class VehicleEntretienPDF{
  final Reparation reparation;
  late final EntretienVehicle entretienVehicle;

  VehicleEntretienPDF(this.reparation){
    entretienVehicle=reparation.entretien??EntretienVehicle();
  }

  Widget vehicleEntretien(){
    Map<String, dynamic> entretienJson =
        entretienVehicle.toJson();
    List<Widget> entretiens = PdfUtilities.getTextListFromMap(entretienJson, 0, entretienJson.length,width: 4.3);

    return Container(
      width: 20 * PdfPageFormat.cm,
      height: 2.7 * PdfPageFormat.cm,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Text('Entretien du vehicule', style: kindaBigTextBold),
        SizedBox(
            width: 20 * PdfPageFormat.cm,
            height: 1.8 * PdfPageFormat.cm,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: entretiens
                          .getRange(0, 4)
                          .toList(growable: false),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: entretiens
                          .getRange(4, 8)
                          .toList(growable: false),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: entretiens
                          .getRange(8, 12)
                          .toList(growable: false),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: entretiens
                          .getRange(12, 16)
                          .toList(growable: false),
                    ),
                  ),
                  bigSpace,
                  bigSpace,
                ])),
      ]),
    );
  }
}