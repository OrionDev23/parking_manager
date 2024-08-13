import 'package:fluent_ui/fluent_ui.dart';

import '../../../utilities/form_validators.dart';
import '../../providers/client_database.dart';
import '../../serializables/client.dart';
import '../prestataire/prestataire_form.dart';

class ClientForm extends PrestataireForm {
  const ClientForm({super.key, super.prest});

  @override
  State<PrestataireForm> createState() => ClientFormState();
}

class ClientFormState extends PrestataireFormState {
  @override
  void showDoneMessages() {
    if (widget.prest == null) {
      showMessage('clientsuccess', "ok");
    } else {
      showMessage('clientupdate', "ok");
    }
  }

  @override
  Future<void> uploadPrestataire() async {
    Client prest = Client(
      id: prestID!,
      nom: nom.text,
      email: FormValidators.isEmail(email.text) ? email.text : null,
      telephone: telephone.text,
      adresse: adresse.text,
      art: art.text,
      rc: rc.text,
      nif: nif.text,
      nis: nis.text,
      description: descr.text,
      search: '${nom.text} ${nif.text} ${nis.text} ${rc.text} ${email.text} '
          '${telephone.text} ${adresse.text} ${descr.text} $prestID ${art.text}',
    );
    if (widget.prest != null) {
      return await DatabaseGetter()
          .updateDocument(
              collectionId: clientsID,
              documentId: prestID!,
              data: prest.toJson())
          .then((value) {
        DatabaseGetter().ajoutActivity(37, prestID!, docName: prest.nom);

        return value;
      });
    } else {
      return await DatabaseGetter()
          .addDocument(
              collectionId: clientsID,
              documentId: prestID!,
              data: prest.toJson())
          .then((value) {
        DatabaseGetter().ajoutActivity(36, prestID!, docName: prest.nom);

        return value;
      });
    }
  }
}
