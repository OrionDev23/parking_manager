import 'dart:io' as f;

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dzair_data_usage/langs.dart' as l;
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../serializables/vehicle/vehicle.dart';
import '../utilities/algeria_lists.dart';
import '../utilities/vehicle_util.dart';

class ImportVehicles extends StatefulWidget {
  final FilePickerResult file;

  const ImportVehicles({super.key, required this.file});

  @override
  State<ImportVehicles> createState() => _ImportVehiclesState();
}

class _ImportVehiclesState extends State<ImportVehicles> {
  bool loading = true;
  double progressLoadingFile = 0;

  @override
  void initState() {
    loadFile();
    super.initState();
  }

  Map<String, Vehicle> importedVehicles = {};
  Map<String, int> columnToRead = {};

  bool invalidFile = false;

  int invalidTables=0;

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
        print('trying table $table');
        setState(() {
          progressLoadingFile += 80 / (excel.tables.length);
        });
        if (isFileValid(excel, table)) {
          print('table $table is valid');
          for (var row in excel.tables[table]!.rows) {
            addVehicle(row);
          }
        } else {
          invalidTables ++;
          break;
        }
      }
      if(invalidTables==excel.tables.length){
        invalidFile=true;
      }
    }

    setState(() {
      progressLoadingFile = 100;
      loading = false;
    });
  }

  void addVehicle(List<Data?> data) {
    String matricule =
        data[columnToRead['mat']!]!.value.toString().replaceAll(' ', '').trim();
    if (matricule.contains('matricul') ||
        (!matricule.contains('-') && int.tryParse(matricule) == null)) {
      return;
    }
    bool etrang = matricule.split('-').length != 3;
    String id = columnToRead.containsKey('numero')
        ?data[columnToRead['numero']!]!.value.toString():matricule;
    int etat = getEtat(columnToRead.containsKey('etat')
        ?data[columnToRead['etat']!]!.value
        .toString():"0");
    int perimetre=getPerimetre(columnToRead.containsKey('perimetre')
        ?data[columnToRead['perimetre']!]!.value
        .toString():null);
    String model = columnToRead.containsKey('model')?
    data[columnToRead['model']!]!
        .value.toString():'';
    String nom = columnToRead.containsKey('nom')?data[columnToRead['nom']!]!
        .value.toString():"";
    String prenom = columnToRead.containsKey('prenom')
        ?data[columnToRead['prenom']!]!.value.toString():"";
    String filliale=columnToRead.containsKey('filliale')
        ?data[columnToRead['filliale']!]!.value.toString():"";
    String apartenance=columnToRead.containsKey('appartenance')
        ?data[columnToRead['appartenance']!]!.value.toString():"";
    List<String> ms = matricule.split('-');
    int? wilaya = etrang ? null : int.tryParse(ms[2]) ?? 16;

    ///toDo get filliale ids
    Vehicle vehicle = Vehicle(
        id: id,
        matricule: matricule,
        perimetre: perimetre,
        matriculeEtrang: etrang,
        etatactuel: etat,
        nom: nom,
        prenom: prenom,
        type: model,
        filliale: filliale,
        appartenance: apartenance,
        wilaya: etrang ? null : wilaya,
        daira: etrang
            ? null
            : AlgeriaList()
                    .getDairas(
                        AlgeriaList().getWilayaByNum(wilaya.toString()) ?? '')
                    .firstOrNull
                    ?.getDairaName(l.Language.FR) ??
                '',
        commune: etrang
            ? null
            : AlgeriaList()
                    .getCommune(
                        AlgeriaList().getWilayaByNum(wilaya.toString()) ?? '')
                    .firstOrNull
                    ?.getDairaName(l.Language.FR) ??
                '',
        genre: (etrang ? 1 : (int.tryParse(ms[1]) ?? 100) ~/ 100).toString(),
        anneeUtil: VehiclesUtilities.getAnneeFromMatricule(matricule));

    importedVehicles[vehicle.matricule] = vehicle;
  }

  int getEtat(String? etats) {
    int etat = 0;
    switch (etats?.toLowerCase().trim()) {
      case 'en marche':
        etat = 3;
        break;
      case 'disponible':
        etat = 0;
        break;
      case 'libre':
        etat = 0;
        break;
      case 'en panne':
        etat = 1;
        break;
      case 'panne':
        etat = 1;
        break;
      case 'reforme':
        etat = 4;
        break;
      case 'garage':
        etat = 2;
        break;
      case 'en reparation':
        etat = 2;
        break;
      case 'en garage':
        etat = 2;
        break;
      case 'reparation':
        etat = 2;
        break;
    }
    return etat;
  }

  int getPerimetre(String? perimetre){
    switch(perimetre?.toUpperCase()){
      case 'BUSINESS':return 0;
      case 'HORS PERIMETRE':return 1;
      case 'INDUSTRIE' :return 2;
      default: return 0;
    }
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
              if (value.value.toLowerCase().contains('matricul') &&
                  !foundMatric) {
                columnToRead['mat'] = cell.columnIndex;
                foundMatric = true;
              }

              if (value.value.toLowerCase().contains('model')|| value.value
                  .toLowerCase().contains('modèl')) {
                columnToRead['model'] = cell.columnIndex;
              }
              if (value.value.toLowerCase() == 'n') {
                columnToRead['numero'] = cell.columnIndex;
              }
              if (value.value.toLowerCase().contains('état') ||
                  value.value.toLowerCase().contains('etat') ||
                  value.value.toLowerCase().contains('state')) {
                columnToRead['etat'] = cell.columnIndex;
              }
              if (value.value.toLowerCase().contains('nom') ||
                  value.value.toLowerCase().contains('familyname') ||
                  value.value
                      .toLowerCase()
                      .replaceAll(' ', '')
                      .contains('secondname')) {
                columnToRead['nom'] = cell.columnIndex;
              }
              if (value.value.toLowerCase().contains('prenom') ||
                  value.value.toLowerCase().contains('prénom') ||
                  value.value
                      .toLowerCase()
                      .replaceAll(' ', '')
                      .contains('firstname')) {
                columnToRead['prenom'] = cell.columnIndex;
              }
              if(value.value.toLowerCase().contains('appartenance  vehicule')){
                columnToRead['appartenance']=cell.columnIndex;
              }
              if(value.value.toLowerCase().contains('filiale')){
                columnToRead['filliale']=cell.columnIndex;
              }
              if(value.value.toLowerCase().contains('périmetre') || value
                  .value.toLowerCase().contains('perimetre')){
                columnToRead['perimetre']=cell.columnIndex;
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
            children: importedVehicles.entries
                .map((e) => ListTile.selectable(
                      selected: e.value.selected,
                      onSelectionChange: (s) {
                        setState(() {
                          e.value.selected = s;
                        });
                      },
                      trailing: Row(
                        children: [
                          Text(
                            VehiclesUtilities.getTypeName(
                                e.value.etatactuel ?? 0),
                            style: TextStyle(color: Colors.grey[100]),
                          ).tr(),
                          smallSpace,
                          Checkbox(
                            checked: e.value.selected,
                            onChanged: (bool? value) {
                              setState(() {
                                e.value.selected = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                      title: Text(e.value.type ?? ''),
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
      importedVehicles.forEach((key, value) {
        if (value.selected) {
          tasks.add(uploadVehicle(value, databases));
        }
      });

      await Future.wait(tasks);
      setState(() {
        doneUploading = true;
      });
    }
  }

  Future<void> uploadVehicle(Vehicle v, Databases db) async {
    await db
        .createDocument(
            databaseId: databaseId,
            collectionId: vehiculeid,
            documentId: v.id,
            data: v.toJson())
        .then((value) {
      setState(() {
        uploaded++;
      });
    }).onError((AppwriteException error, stackTrace) {
      print('erreur vehicule ${v.matricule} : ${error.message}');
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
    importedVehicles.forEach((key, value) {
      value.selected = selectAll ?? false;
    });

    setState(() {});
  }

  void checkSelection() {
    bool? firstSelection;

    importedVehicles.forEach((key, value) {
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
    importedVehicles.forEach((key, value) {
      if (value.selected) {
        result++;
      }
    });
    return result;
  }
}
