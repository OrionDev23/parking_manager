import 'dart:io';

import 'package:adv_log_fact/screens/chauffeur/piece_jointe.dart';
import 'package:adv_log_fact/utilitaire/database_downloader.dart';
import 'package:adv_log_fact/utilitaire/date_converter.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:firebase_dart/firebase_dart.dart' as fd;
import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../serializable.dart';
import '../../theme.dart';
import '../../utilitaire/data_sources/piecejointe_datasource.dart';

int chaufCounter = 0;

class ChauffeurForm extends StatefulWidget {
  final Chauffeur? chauf;
  final String? chaufID;
  final int id = chaufCounter++;
  ChauffeurForm({Key? key, this.chauf, this.chaufID}) : super(key: key);

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
  TextEditingController typeEngin = TextEditingController();
  TextEditingController matriculeTrac = TextEditingController();
  TextEditingController matriculeRemor = TextEditingController();
  TextEditingController tare = TextEditingController(text: '0.000');
  PaginatorController controller = PaginatorController();

  static Map<int, ValueNotifier<int>> updates = {};

  List<TableRow> rows = List.empty(growable: true);

  late PiecesDataSource piecesJointes;

  @override
  void initState() {
    if (updates[widget.id] == null) {
      updates[widget.id] = ValueNotifier(0);
    }
    initValues();
    super.initState();
  }

  void initValues() {
    chaufID = widget.chaufID;
    piecesJointes = PiecesDataSource(context, widget.id);
    if (widget.chauf != null) {
      loading = true;
      Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
        nom.text = widget.chauf!.nom ?? '';
        prenom.text = widget.chauf!.prenom ?? '';
        typeEngin.text = widget.chauf!.typeEngin ?? '';
        matriculeRemor.text = widget.chauf!.matriculeRemor ?? '';
        matriculeTrac.text = widget.chauf!.matriculeTrac ?? '';
        tare.text = (widget.chauf!.tare ?? 0).toStringAsFixed(3);
        widget.chauf!.pieces.forEach((key, value) {
          piecesJointes.addPiece(PieceJointe(
            nom: value.nom,
            lien: value.lien,
            expiration: DateConverter.getDate(value.expiration)
          )..controller.text = value.nom);
        });
        createRows();
        setState(() {
          loading = false;
        });
      });
    } else {
      createRows();
    }
  }

  bool? selected = false;

  void createRows() {
    for (int i = 0; i < piecesJointes.pieces.length; i++) {
      rows.add(piecesJointes.getRow(i));
    }
  }

  void updateRows() {
    int count = 0;
    for (int i = 0; i < rows.length; i++) {
      rows[i] = piecesJointes.getRow(i);
      if (piecesJointes.pieces[i].selected) {
        count++;
      }
    }
    if (count == piecesJointes.pieces.length && count != 0) {
      selected = true;
    } else if (count == 0) {
      selected = false;
    } else {
      selected = null;
    }
  }

  void addPiece() {
    setState(() {
      piecesJointes.addPiece(PieceJointe());
      rows.add(piecesJointes.getRow(piecesJointes.pieces.length - 1));
    });
  }

  void deletePiece() {
    var temp = piecesJointes.pieces.toList();
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].selected) {
        piecesJointes.pieces.removeWhere((p) {
          return p.id == temp[i].id;
        });
      }
    }
    rows.clear();
    createRows();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    const smallSpace = SizedBox(
      width: 5,
      height: 5,
    );
    const bigSpace = SizedBox(
      width: 10,
      height: 10,
    );

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
    return ValueListenableBuilder(
      valueListenable: updates[widget.id]!,
      builder: (BuildContext context, int value, Widget? child) {
        updateRows();
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
            Row(
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
            bigSpace,
            Row(
              children: [
                SizedBox(
                  width: 250,
                  child: TextBox(
                    controller: typeEngin,
                    placeholder: 'Type d\'engin',
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                SizedBox(
                    width: 187,
                    child: TextBox(
                      controller: tare,
                      placeholder: 'Tare (t)',
                    )),
              ],
            ),
            bigSpace,
            Row(
              children: [
                Flexible(
                    child: TextBox(
                  controller: matriculeTrac,
                  placeholder: 'Matricule du tracteur',
                )),
                smallSpace,
                Flexible(
                    child: TextBox(
                  controller: matriculeRemor,
                  placeholder: 'Matricule du remorque',
                )),
              ],
            ),
            bigSpace,
            Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: selected == false
                              ? null
                              : () {
                                  deletePiece();
                                },
                          style: ButtonStyle(
                            backgroundColor: ButtonState.all<Color>(
                              selected == true || selected == null
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            foregroundColor:
                                ButtonState.all<Color>(Colors.white),
                          ),
                          child: const Text('Supprimer'),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        FilledButton(
                            onPressed: addPiece, child: const Text('Ajouter'))
                      ],
                    ),
                  ),
                  Flexible(
                      child: Table(
                    children: [
                      TableRow(children: [
                        TableCell(
                            child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Checkbox(
                                checked: selected,
                                onChanged: (v) {
                                  setState(() {
                                    piecesJointes.selectAll(
                                        selected == null ? false : !selected!);
                                    selected =
                                        selected == null ? false : !selected!;
                                  });
                                },
                              ),
                              const Text(
                                'N°',
                              ),
                            ],
                          ),
                        )),
                        const TableCell(
                            child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Text(
                            'Désignation',
                            textAlign: TextAlign.center,
                          ),
                        )),
                        const TableCell(
                            child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Text(
                            'Scan',
                            textAlign: TextAlign.center,
                          ),
                        )),
                        const TableCell(
                            child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Text(
                                  'Date d\'expiration ?',
                                  textAlign: TextAlign.center,
                                ))),
                      ]),
                    ],
                  )),
                  Flexible(
                    child: Table(
                      border: TableBorder(
                          verticalInside: BorderSide(
                              color: appTheme.mode == ThemeMode.light
                                  ? Colors.black
                                  : Colors.grey,
                              width: 1)),
                      children: rows,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void upload() async {
    if (nom.value.text.isEmpty || prenom.text.isEmpty) {
      showMessage('Nom et prénom obligatoires', 'Erreur');
      return;
    }
    if (double.tryParse(tare.value.text) == null) {
      showMessage(
          'Vous devez entrer un poids valide en tonnes (tare)', 'Erreur');
      return;
    }
    for (int i = 0; i < piecesJointes.pieces.length; i++) {
      if (piecesJointes.pieces[i].controller.value.text.isEmpty) {
        showMessage(
            'Vous devriez donner une dénomination à toutes les pieces ajoutées',
            'Erreur');
        return;
      }
      if (piecesJointes.pieces[i].fileSelected == null &&
          piecesJointes.pieces[i].lien == null) {
        showMessage('Chaque piece jointe doit avoir un scan', 'Erreur');
        return;
      }
    }

    if (!uploading) {
      setState(() {
        uploading = true;
        progress = 0;
      });
      chaufID ??= DateTime.now()
          .difference(DateTime(2023, 04, 03, 05, 56, 0))
          .inMilliseconds
          .toString();
      try {
        await uploadPiecesPics();
        setState(() {
          progress = 70;
        });
        await uploadChauffeur();
        setState(() {
          progress = 90;
        });
        if (widget.chauf == null) {
          showMessage('Chauffeur ajouté !', "Fait");
        } else {
          showMessage('Chauffeur mis à jour !', "Fait");
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

  Future<void> uploadPiecesPics() async {
    if (chaufID != null) {
      linksGenerated.clear();
      List<Future<void>> tasks = List.empty(growable: true);
      for (int i = 0; i < piecesJointes.pieces.length; i++) {
        if (piecesJointes.pieces[i].fileSelected != null) {
          tasks.add(uploadApic(piecesJointes.pieces[i].fileSelected!, i));
        } else if (piecesJointes.pieces[i].lien != null) {
          linksGenerated[i] = piecesJointes.pieces[i].lien!;
        } else {
          throw Future.error(Exception('SCAN'));
        }
      }
      await Future.wait(tasks);
    } else {
      throw Future.error(Exception('ID-EMPTY'));
    }
  }

  Map<int, String> linksGenerated = {};

  Future<void> uploadApic(File picture, int id) async {
    if (chaufID != null) {
      fd.TaskSnapshot ev = await fd.FirebaseStorage.instance
          .ref('pieces/$chaufID/$id.jpg')
          .putData(await picture.readAsBytes());
      linksGenerated[id] = await ev.ref.getDownloadURL();
      setState(() {
        progress += progress + 70 / piecesJointes.pieces.length;
      });
    } else {
      throw Future.error(Exception('ID chauffeur vide'));
    }
  }

  Future<void> uploadChauffeur() async {
    var firestore = Firestore(projectId, auth: FirebaseAuth.instance);
    var date = DateTime.now().toString();
    Chauffeur chauf = Chauffeur(
        nom: nom.value.text,
        prenom: prenom.value.text,
        typeEngin: typeEngin.value.text,
        matriculeTrac: matriculeTrac.value.text,
        matriculeRemor: matriculeRemor.value.text,
        dateC: widget.chauf == null || widget.chauf?.dateC == null
            ? date
            : widget.chauf!.dateC!,
        dateM: date,
        tare: double.parse(tare.value.text),
        pieces: createPieces());
    DatabaseGetter.chauffeurs[chaufID!]=chauf;
    return await firestore
        .collection('chauffeurs')
        .document(chaufID!)
        .set(chauf.toJson());
  }

  Map<String, Piece> createPieces() {
    Map<String, Piece> result = {};
    for (int i = 0; i < piecesJointes.pieces.length; i++) {
      if (linksGenerated.containsKey(i)) {
        result[i.toString()] = Piece(
            nom: piecesJointes.pieces[i].controller.value.text,
            lien: linksGenerated[i]!,
            expiration: piecesJointes.pieces[i].expiration?.toString());
      } else {
        if (piecesJointes.pieces[i].lien != null) {
          result[i.toString()] = Piece(
              nom: piecesJointes.pieces[i].controller.value.text,
              lien: piecesJointes.pieces[i].lien!,
              expiration: piecesJointes.pieces[i].expiration?.toString());
        }
      }
    }
    return result;
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
