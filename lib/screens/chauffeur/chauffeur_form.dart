
import 'package:appwrite/models.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/conducteur.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../theme.dart';

int chaufCounter = 0;

class ChauffeurForm extends StatefulWidget {
  final Conducteur? chauf;
  final int id = chaufCounter++;
  ChauffeurForm({super.key, this.chauf,});

  @override
  State<ChauffeurForm> createState() => ChauffeurFormState();
}

class ChauffeurFormState extends State<ChauffeurForm> {
  bool uploading = false;
  bool loading = false;
  double progress = 0;
  String? chaufID;

  TextEditingController nom = TextEditingController();
  TextEditingController prenom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController telephone = TextEditingController();
  TextEditingController adresse = TextEditingController();
  DateTime? birthDay;
  PaginatorController controller = PaginatorController();

  static Map<int, ValueNotifier<int>> updates = {};

  List<TableRow> rows = List.empty(growable: true);

  @override
  void initState() {
    if (updates[widget.id] == null) {
      updates[widget.id] = ValueNotifier(0);
    }
    initValues();
    super.initState();
  }

  void initValues() {
    if (widget.chauf != null) {
      nom.text = widget.chauf!.name;
      prenom.text = widget.chauf!.prenom;
      email.text = widget.chauf!.email ?? '';
      telephone.text = widget.chauf!.telephone ?? '';
      adresse.text = widget.chauf!.adresse ?? '';
      birthDay=widget.chauf!.dateNaissance;
    }
  }

  bool? selected = false;



  @override
  Widget build(BuildContext context) {

    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Chargement en cours ...'),
            smallSpace,
            ProgressBar(
              value: progress,
            ),
          ],
        ),
      );
    }
    if (uploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Sauvegarde en cours ...'),
            smallSpace,
            ProgressBar(
              value: progress,
            ),
          ],
        ),
      );
    }
    return ScaffoldPage.scrollable(
      bottomBar: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: !uploading ? upload : null,
              child: const Text('Sauvegarder'),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      children: [
        ZoneBox(
          label: 'fullname'.tr(),
          child: Row(
            children: [
              Flexible(
                  child: TextBox(
                controller: nom,
                placeholder: 'Nom',
              )),
              smallSpace,
              Flexible(
                  child: TextBox(
                controller: prenom,
                placeholder: 'Prénom',
              )),
            ],
          ),
        ),
        smallSpace,
        ZoneBox(label: 'birthday'.tr(),
        child:
        SizedBox(height: 5.h,
          child: DatePicker(selected: birthDay,onChanged: (d){
          setState(() {
            birthDay=d;
          });
        },),)
        ),
        smallSpace,
        ZoneBox(
          label:'contact'.tr(),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: TextBox(
                      controller: email,
                      placeholder: 'email'.tr(),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  SizedBox(
                      width: 187,
                      child: TextBox(
                        controller: telephone,
                        placeholder: 'telephone'.tr(),
                      )),
                ],
              ),
              Flexible(child: TextBox(
                controller: adresse,
                maxLength: 3,
              )),
            ],
          ),
        ),
      ],
    );
  }

  void upload() async {
    if (nom.value.text.isEmpty || prenom.text.isEmpty) {
      showMessage('Nom et prénom obligatoires', 'Erreur');
      return;
    }
    if (!uploading) {
      setState(() {
        uploading = true;
        progress = 0;
      });
      chaufID ??= DateTime.now()
          .difference(ClientDatabase.ref)
          .inMilliseconds
          .toString();
      try {
        await uploadChauffeur();
        setState(() {
          progress = 90;
        });
        if (widget.chauf == null) {
          showMessage('Conducteur ajouté !', "Fait");
        } else {
          showMessage('Conducteur mis à jour !', "Fait");
        }
      } catch (e) {
        setState(() {
          uploading = false;
          showMessage('Erreur d\'upload, vérifiez votre connexion et réessayez',
              'Erreur');
        });
      }
      setState(() {
        uploading = false;
        progress = 100;
      });
    }
  }


  Map<int, String> linksGenerated = {};

  Future<Document> uploadChauffeur() async {

    var dateFormat=DateFormat('y/m/d','fr');
    Conducteur chauf = Conducteur(
        id:chaufID!,
        name: nom.value.text,
        prenom: prenom.value.text,
        email: email.value.text,
        telephone: telephone.value.text,
        adresse: adresse.value.text,
        dateNaissance: birthDay,
        search: '${dateFormat.format(birthDay??DateTime.now())} '
            '${nom.value.text} ${prenom.value.text} ${email.value.text} '
            '${telephone.value.text} ${adresse.value.text} $chaufID',
        );
    return await ClientDatabase.database!.createDocument(
        databaseId: databaseId,
        collectionId: chauffeurid,
        documentId: chaufID!,
        data: chauf.toJson());
  }


  void showMessage(String message, String title) {
    showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(
          message,
        ),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
