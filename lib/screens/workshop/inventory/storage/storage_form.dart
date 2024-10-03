import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/pieces/part.dart';

class StorageForm extends StatefulWidget {
  const StorageForm({super.key});

  @override
  State<StorageForm> createState() => _StorageFormState();
}

class _StorageFormState extends State<StorageForm> {

  VehiclePart? selectedPart;
  double qte=1;
  List<DateTime?>expirationDates=[];
  bool differentDate=false;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
