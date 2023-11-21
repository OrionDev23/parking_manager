
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';

class DocumentForm extends StatefulWidget {

  final DocumentVehicle? vd;
  const DocumentForm({super.key, this.vd});

  @override
  DocumentFormState createState() => DocumentFormState();
}

class DocumentFormState extends State<DocumentForm> {


  DateTime selectedDate=DateTime.now();
  TextEditingController nom=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
