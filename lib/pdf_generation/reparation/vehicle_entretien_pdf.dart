import 'package:parc_oto/serializables/reparation/entretien_vehicle.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

import '../../serializables/reparation/fiche_reception.dart';
import '../../serializables/reparation/reparation.dart';
import '../pdf_theming.dart';
import '../pdf_utilities.dart';

class VehicleEntretienPDF {
  final Reparation? reparation;
  final FicheReception? fiche;
  late final EntretienVehicle entretienVehicle;

  VehicleEntretienPDF({this.reparation,this.fiche}) {
    entretienVehicle = reparation?.entretien ?? fiche?.entretien??EntretienVehicle();
  }

  Widget vehicleEntretien() {
    Map<String, dynamic> entretienJson = entretienVehicle.toJson();
    List<Widget> entretiens = PdfUtilities.getTextListFromMap(
        entretienJson, 0, entretienJson.length,
        width: 4.3);

    return Container(
      width: 20 * PdfPageFormat.cm,
      height: 3.9 * PdfPageFormat.cm,
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
                height: 2.9 * PdfPageFormat.cm,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...List.generate(4, (index) => Container(
                        padding: const EdgeInsets.all(3),

                        child: Column(
                          children:
                          entretiens.getRange(index*7, (index+1)*7<entretiens
                              .length+1?(index+1)*7:entretiens.length)
                              .toList
                            (growable:
                          false),
                        ),
                      ),),
                      bigSpace,
                      bigSpace,
                    ])),
          ]),
    );
  }
  
  
}
