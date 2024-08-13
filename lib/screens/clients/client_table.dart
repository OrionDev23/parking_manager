import 'package:fluent_ui/fluent_ui.dart';

import '../../providers/client_database.dart';
import '../prestataire/prestataire_table.dart';


class ClientTable extends PrestataireTable {
  const ClientTable({super.key, super.archive = false, super.selectD});

  @override
  State<PrestataireTable> createState() => ClientTableState();
}

class ClientTableState extends PrestataireTableState {
  @override
  String getCollectionID() {
    return clientsID;
  }
}
