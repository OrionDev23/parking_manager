import 'dart:io' as f;

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/conducteur/conducteur.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../utilities/vehicle_util.dart';

class ImportConducteurs extends StatefulWidget {
  final FilePickerResult file;

  const ImportConducteurs({super.key, required this.file});

  @override
  State<ImportConducteurs> createState() => _ImportConducteursState();
}

class _ImportConducteursState extends State<ImportConducteurs> {
  bool loading = true;
  double progressLoadingFile = 0;

  @override
  void initState() {
    loadFile();
    super.initState();
  }

  Map<String, Conducteur> importedConducteurs = {};
  Map<String, int> columnToRead = {};

  bool invalidFile = false;

  int invalidTables = 0;

  void loadFile() async {
    if (!loading) {
      setState(() {
        loading = true;
      });
    }
    Uint8List? bytes = widget.file.files.first.bytes;
    if (kIsWeb) {
      bytes = widget.file.files.first.bytes;
    } else {
      bytes = await f.File(widget.file.files.single.path!).readAsBytes();
    }
    if (bytes != null) {
      setState(() {
        progressLoadingFile = 10;
      });
      var excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.keys) {
        if (kDebugMode) {
          print('trying table $table');
        }
        setState(() {
          progressLoadingFile += 80 / (excel.tables.length);
        });
        if (isFileValid(excel, table)) {
          if (kDebugMode) {
            print('table $table is valid');
          }
          for (var row in excel.tables[table]!.rows) {
            addConducteur(row);
          }
        } else {
          invalidTables++;
          break;
        }
      }
      if (invalidTables == excel.tables.length) {
        invalidFile = true;
      }
    }

    setState(() {
      progressLoadingFile = 100;
      loading = false;
    });
  }

  void addConducteur(List<Data?> data) {
    String matricule =
        data[columnToRead['mat']!]!.value.toString().replaceAll(' ', '').trim();
    if (matricule.contains('matricul') ||
        (!matricule.contains('-') && int.tryParse(matricule) == null)) {
      return;
    }
    String id = matricule.replaceAll('-', '').trim();
    String nom = columnToRead.containsKey('nom')
        ? data[columnToRead['nom']!]!.value.toString()
        : "";
    String vehicule = columnToRead.containsKey('vehicule')
        ? data[columnToRead['vehicule']!]!.value.toString().replaceAll(' ', '')
        : "";
    String prenom = columnToRead.containsKey('prenom')
        ? data[columnToRead['prenom']!]!.value.toString()
        : "";
    String apartenance = columnToRead.containsKey('appartenance')
        ? VehiclesUtilities.getAppartenance(
                data[columnToRead['appartenance']!]!.value.toString())
            .replaceAll(' ', '')
            .trim()
            .toUpperCase()
        : "";
    String direction = columnToRead.containsKey('direction')
        ? VehiclesUtilities.getDirection(
                data[columnToRead['direction']!]!.value.toString())
            .replaceAll(' ', '')
            .trim()
            .toUpperCase()
        : "";
    Conducteur conducteur = Conducteur(
      id: id,
      matricule: matricule,
      name: nom,
      prenom: prenom,
      vehicules: [vehicule],
      filliale: apartenance,
      direction: direction,
    );
    if (importedConducteurs.containsKey(conducteur.matricule)) {
      addVehiclesToConducteur(conducteur);
    } else {
      importedConducteurs[conducteur.matricule] = conducteur;
    }
  }

  void addVehiclesToConducteur(Conducteur v) {
    importedConducteurs[v.matricule]!.vehicules!.addAll(v.vehicules!);
  }

  bool isFileValid(Excel excel, String table) {
    bool foundMatric = false;

    for (var row in excel.tables[table]!.rows) {
      for (var cell in row) {
        if (cell?.value != null) {
          switch (cell?.value) {
            case null:
              break;
            case FormulaCellValue():
              break;
            case IntCellValue():
              break;

            case DoubleCellValue():
              break;

            case DateCellValue():
              break;

            case TextCellValue():
              final value = cell!.value as TextCellValue;
              if(value.value.text!=null){
                if ((value.value.text!.toLowerCase()
                    .contains
                  ('matricule employe') ||
                    value.value.text!.toLowerCase().contains('matricule '
                        'employé') ||
                    value.value
                        .text!.toLowerCase()
                        .contains('matricule conducteur')) &&
                    !foundMatric) {
                  columnToRead['mat'] = cell.columnIndex;
                  foundMatric = true;
                }
                if (value.value.text!.toLowerCase()
                    .contains('immatriculation')||
                    value.value.text!.toLowerCase().contains('matricule '
                        'vehicule'))
                {
                  columnToRead['vehicule']=cell.columnIndex;
                }
                if (value.value.text!.toLowerCase().replaceAll(' ','').trim()
                    =='nom' ||
                    value.value.text!.toLowerCase().contains('familyname') ||
                    value.value.text!
                        .toLowerCase()
                        .replaceAll(' ', '')
                        .contains('secondname')) {
                  columnToRead['nom'] = cell.columnIndex;
                }
                if (value.value.text!.toLowerCase().contains('prenom') ||
                    value.value.text!.toLowerCase().contains('prénom') ||
                    value.value.text!
                        .toLowerCase()
                        .replaceAll(' ', '')
                        .contains('firstname')) {
                  columnToRead['prenom'] = cell.columnIndex;
                }
                if (value.value.text!.toLowerCase().contains('appartenance') &&
                    (value.value.text!.toLowerCase().contains('salarié') ||
                        value.value.text!.toLowerCase().contains('employe') ||
                        value.value.text!.toLowerCase().contains('employé'))) {
                  columnToRead['appartenance'] = cell.columnIndex;
                }
                if (value.value.text!.toLowerCase().contains('direction')) {
                  columnToRead['direction'] = cell.columnIndex;
                }
              }

              break;
            case BoolCellValue():
              break;

            case TimeCellValue():
              break;

            case DateTimeCellValue():
              break;
          }
        }
      }
      if (foundMatric) {
        break;
      }
    }

    return foundMatric;
  }

  bool doneUploading = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ContentDialog(
      title: const Text("importlist").tr(),
      constraints: BoxConstraints.loose(Size(600.px, 500.px)),
      content: loading
          ? Center(
              child: ProgressBar(
                value: progressLoadingFile,
              ),
            )
          : invalidFile
              ? invalidFileWidget()
              : uploading
                  ? uploadWidget(appTheme)
                  : getList(),
      actions: [
        Button(
            child: doneUploading
                ? const Text('fermer').tr()
                : const Text('annuler').tr(),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        if (!doneUploading)
          FilledButton(
              onPressed:
                  loading || invalidFile || uploading ? null : uploadVehicles,
              child: const Text('confirmer').tr())
      ],
    );
  }

  bool? selectAll = false;

  Widget getList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectimport',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        ).tr(),
        bigSpace,
        SizedBox(
          height: 30.px,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Checkbox(
                checked: selectAll,
                onChanged: (s) {
                  setState(() {
                    selectAll = s ?? false;
                  });
                  selectAllVehicles();
                },
                content: const Text('selectall').tr(),
              ),
              const Text('lselection')
                  .tr(namedArgs: {'select': getNumberOfSelected().toString()})
            ],
          ),
        ),
        Flexible(
          child: ListView(
            children: importedConducteurs.entries
                .map((e) => ListTile.selectable(
                      selected: e.value.selected,
                      onSelectionChange: (s) {
                        setState(() {
                          e.value.selected = s;
                        });
                      },
                      trailing: Checkbox(
                        checked: e.value.selected,
                        onChanged: (bool? value) {
                          setState(() {
                            e.value.selected = value ?? false;
                          });
                        },
                      ),
                      title: Text('${e.value.name} ${e.value.prenom}'),
                      leading: Text(e.value.matricule),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget invalidFileWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            color: Colors.grey[100],
          ),
          smallSpace,
          const Text(
            'invalidvehiclefile',
            textAlign: TextAlign.justify,
            style: TextStyle(
              wordSpacing: 2,
            ),
          ).tr(),
        ],
      ),
    );
  }

  void uploadVehicles() async {
    if (!uploading) {
      setState(() {
        uploading = true;
      });
      Client client = Client()
        ..setEndpoint(endpoint)
        ..setProject(project)
        ..setKey(secretKey);
      Databases databases = Databases(client);
      List<Future> tasks = [];
      importedConducteurs.forEach((key, value) {
        if (value.selected) {
          tasks.add(uploadConducteur(value, databases));
        }
      });

      await Future.wait(tasks);
      setState(() {
        doneUploading = true;
      });
    }
  }

  Future<void> uploadConducteur(Conducteur c, Databases db) async {
    await db
        .createDocument(
            databaseId: databaseId,
            collectionId: chauffeurid,
            documentId: c.id,
            data: c.toJson())
        .then((value) {
      setState(() {
        uploaded++;
      });
    }).onError((AppwriteException error, stackTrace) {
      if (kDebugMode) {
        print('erreur conducteur ${c.matricule} : ${error.message}');
      }
      setState(() {
        notUploaded++;
      });
    });
  }

  Widget uploadWidget(AppTheme appTheme) {
    int nSelected = getNumberOfSelected();
    const double fSize = 18;
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 450.px,
                child: ProgressBar(
                  value: (uploaded + notUploaded) * 100 / nSelected,
                  strokeWidth: 25,
                  activeColor: appTheme.color.darkest,
                  backgroundColor: appTheme.fillColor,
                ),
              ),
              const Spacer(),
              Text(
                '${((uploaded + notUploaded) * 100 / nSelected).toStringAsFixed(2)} %',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: fSize),
              )
            ],
          ),
          bigSpace,
          Row(
            children: [
              Text('uploaded'.tr(),
                  style: TextStyle(
                    fontSize: fSize,
                    fontWeight: FontWeight.bold,
                    color: appTheme.color.darkest,
                  )),
              const Spacer(),
              Text('\t\t\t\t${uploaded.toInt()} / $nSelected',
                  style: TextStyle(
                      fontSize: fSize, color: appTheme.color.darkest)),
            ],
          ),
          smallSpace,
          Row(
            children: [
              Text('skipped'.tr(),
                  style: TextStyle(
                    fontSize: fSize,
                    fontWeight: FontWeight.bold,
                    color: appTheme.color.lightest,
                  )),
              const Spacer(),
              Text('\t\t\t\t${notUploaded.toInt()} / $nSelected',
                  style: TextStyle(
                      fontSize: fSize, color: appTheme.color.lightest)),
            ],
          ),
        ]));
  }

  bool uploading = false;
  double uploaded = 0;
  double notUploaded = 0;

  void selectAllVehicles() {
    importedConducteurs.forEach((key, value) {
      value.selected = selectAll ?? false;
    });

    setState(() {});
  }

  void checkSelection() {
    bool? firstSelection;

    importedConducteurs.forEach((key, value) {
      if (firstSelection == null) {
        firstSelection = value.selected;
      } else {
        if (value.selected != firstSelection) {
          selectAll = null;
          return;
        }
      }
    });

    setState(() {});
  }

  int getNumberOfSelected() {
    int result = 0;
    importedConducteurs.forEach((key, value) {
      if (value.selected) {
        result++;
      }
    });
    return result;
  }
}
