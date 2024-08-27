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
    String model = columnToRead.containsKey('model')? data[columnToRead['model']!]!.value.toString():'';
    String nom = columnToRead.containsKey('nom')?data[columnToRead['nom']!]!
        .value.toString():"";
    String matriculeEmploye=columnToRead.containsKey('matEmp')
        ?data[columnToRead['matEmp']!]!
        .value.toString():"";
    String emplacement=columnToRead.containsKey('emplacement')
        ?data[columnToRead['emplacement']!]!
        .value.toString():"";
    String poste=columnToRead.containsKey('poste')
        ?data[columnToRead['poste']!]!
        .value.toString():"";
    String prenom = columnToRead.containsKey('prenom')
        ?data[columnToRead['prenom']!]!.value.toString():"";
    String filliale=columnToRead.containsKey('filliale')
        ?VehiclesUtilities.getAppartenance
      (data[columnToRead['filliale']!]!.value.toString()).replaceAll(' ', ''
    ).trim().toUpperCase():"";
    String apartenance=columnToRead.containsKey('appartenance')
        ?VehiclesUtilities.getAppartenance
      (data[columnToRead['appartenance']!]!.value
        .toString())
      .replaceAll(' ', '').trim().toUpperCase()
        :"";
    String apartenanceSalar=columnToRead.containsKey('appartenancesalar')
        ?VehiclesUtilities.getAppartenance
      (data[columnToRead['appartenancesalar']!]!.value
        .toString())
        .replaceAll(' ', '').trim().toUpperCase()
        :"";
    bool service=columnToRead.containsKey('service')
        ?data[columnToRead['service']!]?.value.toString().toLowerCase()
    .trim()=='service'?true:false:false;
    bool decision=columnToRead.containsKey('decision')
        ?data[columnToRead['decision']!]?.value.toString().toLowerCase()
        .trim()=='oui'?true:false:false;
    String departement=columnToRead.containsKey('departement')
        ?VehiclesUtilities.getDepartment
      (data[columnToRead['departement']!]!.value
        .toString())
        .replaceAll(' ', '').trim().toUpperCase()
        :"";
    String direction=columnToRead.containsKey('direction')
        ?VehiclesUtilities.getDirection
      (data[columnToRead['direction']!]!.value
        .toString())
      .replaceAll(' ', '').trim().toUpperCase()
        :"";
    List<String> ms = matricule.split('-');
    int? wilaya = etrang ? null : int.tryParse(ms[2]) ?? 16;
    int genre=etrang ? 1 : (int.tryParse(ms[1]) ?? 100) ~/ 100;
    bool lourd=columnToRead.containsKey('poids')
        ?data[columnToRead['poids']!]!.value.toString().toUpperCase()
        .contains('LOU'):genre==2||genre==4|| genre==5 || genre==6||genre==8 ;
    Vehicle vehicle = Vehicle(
        id: id,
        matricule: matricule,
        perimetre: perimetre,
        matriculeEtrang: etrang,
        etatactuel: etat,
        nom: nom,
        prenom: prenom,
        type: model,
        emplacement:emplacement,
        filliale: filliale,
        appartenance: apartenance,
        direction: direction,
        matriculeConducteur: matriculeEmploye,
        departement: departement,
        decision: decision,
        service: service,
        appartenanceconducteur: apartenanceSalar,
        profession: poste,
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
        genre: (genre).toString(),
        lourd: lourd,
        anneeUtil: VehiclesUtilities.getAnneeFromMatricule(matricule));

    if(kDebugMode){
      print(vehicle.toJson());
    }
    if(importedVehicles.containsKey(vehicle.matricule)){
      replaceVehicleEmptiness(vehicle);
    }
    else{
      importedVehicles[vehicle.matricule] = vehicle;
    }
  }

  void replaceVehicleEmptiness(Vehicle v){
    if(importedVehicles[v.matricule]!.etatactuel==null || importedVehicles[v
        .matricule]!.etatactuel==0){
      importedVehicles[v.matricule]!.etatactuel=v.etatactuel;
    }
    if(importedVehicles[v.matricule]!.perimetre==0){
      importedVehicles[v.matricule]!.perimetre=v.perimetre;
    }
    if(importedVehicles[v.matricule]!.nom==null || importedVehicles[v
        .matricule]!.nom!.isEmpty){
      importedVehicles[v.matricule]!.nom=v.nom;
    }
    if(importedVehicles[v.matricule]!.prenom==null || importedVehicles[v
        .matricule]!.prenom!.isEmpty){
      importedVehicles[v.matricule]!.prenom=v.prenom;
    }
    if(importedVehicles[v.matricule]!.type==null || importedVehicles[v
        .matricule]!.type!.isEmpty){
      importedVehicles[v.matricule]!.type=v.type;
    }
    if(importedVehicles[v.matricule]!.appartenance==null || importedVehicles[v
        .matricule]!.appartenance!.isEmpty){
      importedVehicles[v.matricule]!.appartenance=v.appartenance;
    }
    if(importedVehicles[v.matricule]!.filliale==null || importedVehicles[v
        .matricule]!.filliale!.isEmpty){
      importedVehicles[v.matricule]!.filliale=v.filliale;
    }
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
    switch(perimetre?.toUpperCase().trim()){
      case 'BUSINESS' || 'buisiness':
        return 0;
      case 'HORS PERIMETRE' || 'hors perimetre':
        return 1;
      case 'INDUSTRIE' || 'industrie' :
        return 2;
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
              if(value.value.text!=null){
                if (value.value.text!.toLowerCase()=='immatriculation' &&
                    !foundMatric) {
                  columnToRead['mat'] = cell.columnIndex;
                  foundMatric = true;
                }

                if (value.value.text!.toLowerCase().contains('model')|| value.value.text!
                    .toLowerCase().contains('modèl')) {
                  columnToRead['model'] = cell.columnIndex;
                }
                if (value.value.text!.toLowerCase() == 'n') {
                  columnToRead['numero'] = cell.columnIndex;
                }
                if (value.value.text!.toLowerCase().contains('état') ||
                    value.value.text!.toLowerCase().contains('etat') ||
                    value.value.text!.toLowerCase().contains('state')) {
                  columnToRead['etat'] = cell.columnIndex;
                }
                if (value.value.text!.toLowerCase().replaceAll(' ','').trim()=='nom' ||
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
                if(value.value.text!.toLowerCase().trim()=='appartenance vehicule'){
                  columnToRead['appartenance']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim()=='appartenance salarié'){
                  columnToRead['appartenancesalar']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().contains('filiale') && value
                    .value.text!.toLowerCase().contains('vehicule')){
                  columnToRead['filliale']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().contains('direction') ){
                  columnToRead['direction']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().contains('departement') ){
                  columnToRead['departement']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().contains('matricule employé') ){
                  columnToRead['matemp']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('périmetre') || value
                    .value.text!.toLowerCase().trim().contains('perimetre')){
                  columnToRead['perimetre']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('service') || value
                    .value.text!.toLowerCase().trim().contains('fonction')){
                  columnToRead['service']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('décision') ||
                    value.value.text!.toLowerCase().trim().contains('decision')){
                  columnToRead['decision']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('emplacement')){
                  columnToRead['emplacement']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('poids') || value
                    .value.text!.toLowerCase().trim().replaceAll(' ', '').contains
                  ('Lourd/Leger')){
                  columnToRead['poids']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('matricule '
                    'employé') || value
                    .value.text!.toLowerCase().trim().replaceAll(' ', '').contains
                  ('matriculeemploye')){
                  columnToRead['matEmp']=cell.columnIndex;
                }
                if(value.value.text!.toLowerCase().trim().contains('poste occupé') || value
                    .value.text!.toLowerCase().trim().replaceAll(' ', '').contains
                  ('poste')){
                  columnToRead['poste']=cell.columnIndex;
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
                            VehiclesUtilities.getEtatName(
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
      if (kDebugMode) {
        print('erreur vehicule ${v.matricule} : ${error.message}');
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
