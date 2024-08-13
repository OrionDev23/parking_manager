import 'package:fluent_ui/fluent_ui.dart';

import '../../../../providers/client_database.dart';
import '../../../prestataire/prestataire_table.dart';


class FournisseurTable extends PrestataireTable {
  const FournisseurTable({super.key, super.archive = false, super.selectD});

  @override
  State<PrestataireTable> createState() => FournisseurTableState();
}

class FournisseurTableState extends PrestataireTableState {
  static ValueNotifier<String?> filterDocument = ValueNotifier(null);

  @override
  String getCollectionID() {
    return fournsID;
  }
}
