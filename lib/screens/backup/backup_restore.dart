import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_appwrite/dart_appwrite.dart' as da;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:gzip/gzip.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/restore/restore_database.dart';
import 'package:parc_oto/serializables/conducteur/disponibilite_chauffeur.dart';
import 'package:parc_oto/serializables/conducteur/document_chauffeur.dart';
import 'package:parc_oto/serializables/client.dart';
import 'package:parc_oto/serializables/vehicle/document_vehicle.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../serializables/activity.dart';
import '../../serializables/backup.dart';
import '../../serializables/conducteur/conducteur.dart';
import '../../serializables/planning.dart';
import '../../serializables/reparation/reparation.dart';
import '../../serializables/vehicle/state.dart';
import '../../serializables/vehicle/vehicle.dart';
import '../../theme.dart';
import 'import_list_element.dart';

class BackupRestore extends StatefulWidget {

  final Backup? backup;
  final Uint8List? backupFile;
  const BackupRestore({super.key, this.backup, this.backupFile});

  @override
  State<BackupRestore> createState() => _BackupRestoreState();
}

class _BackupRestoreState extends State<BackupRestore> {

  Uint8List? loadedFile;
  double progress=0;

  @override
  void initState() {
    loadFile();
    super.initState();
  }

  bool deleteAllData=false;
  bool appendAllData=false;
  bool addNewData=true;
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: BoxConstraints(
        minWidth: 500.px,
        maxWidth: 600.px
      ),
      content: ListView(
        shrinkWrap: true,
        children: [
          if(progress<100)
            const ProgressBar(),
          if(progress==100)
            StaggeredGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: elementsToImport(),
            ),
          if(progress==100)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ToggleSwitch(
                checked: addNewData,
                content: const Text('addnewdata').tr(),
                onChanged: (s){
                  setState(() {

                    if(!s && !deleteAllData && !appendAllData){
                      addNewData=true;
                    }
                    else{
                      addNewData=s;
                      if(s){
                        deleteAllData=false;
                        appendAllData=false;
                      }
                    }
                  });
                },
              ),
            ),
          if(progress==100)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ToggleSwitch(
                checked: appendAllData,
                content: const Text('appenddata').tr(),
                onChanged: (s){
                  setState(() {
                    appendAllData=s;
                    if(s){
                      deleteAllData=false;
                      addNewData=false;
                    }
                    if(!s && !deleteAllData){
                      addNewData=true;
                    }
                  });
                },
              ),
            ),
          if(progress==100)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ToggleSwitch(
                  checked: deleteAllData,
                  content: const Text('deletealldata').tr(),
                  onChanged: (s){
                    setState(() {
                      deleteAllData=s;
                      if(s){
                        appendAllData=false;
                        addNewData=false;
                      }
                      if(!s && !deleteAllData){
                        addNewData=true;
                      }
                    });
                  },
              ),
            ),

        ],
      ),
      actions: [
        Button(onPressed: restoring?null:()
    =>context.pop(),child: const Text('fermer').tr(),),
        FilledButton(onPressed: !restoring && progress==100 &&
            somethingIsSelected
          ()?confirmSelection:null, child:restoring?const ProgressRing():
        const Text('confirmer').tr()),
      ],
    );
  }

  void confirmSelection(){
    if(somethingIsSelected() && !restoring){
      restoreData();
    }
  }

  bool somethingIsSelected(){
    return vehiculesSelected || vehiclesDocsSelected || vehiclesStatesSelected
        || driversSelected || driversDocsSelected || driversStatesSelected
        || repairsSelected || providersSelected || logsSelected ||
        planningsSelected;
  }


  List<Widget> elementsToImport(){
    return [
      if(vehicles.isNotEmpty)
        ImportListElement(
          title: 'thevehicules'.tr(),
          checked: vehiculesSelected,
          onChecked: (s) {
            setState(() {
              vehiculesSelected = s ?? false;
            });
          },
          subTitle: vehiculesSelected
              ?'vehiclescount'.tr(namedArgs:{'v':vehicles.length.toString()})
              : null,
        ),
      if(vehiclesDocs.isNotEmpty)
        ImportListElement(
          title: 'vehicledocuments'.tr(),
          checked: vehiclesDocsSelected,
          onChecked: (s) {
            setState(() {
              vehiclesDocsSelected = s ?? false;
            });
          },
          subTitle: vehiclesDocsSelected
              ?'doccount'.tr(namedArgs:{'d':vehiclesDocs.length.toString()})
              : null,
        ),
      if(vehiclesStates.isNotEmpty)
        ImportListElement(
          title: 'vehicledocuments'.tr(),
          checked: vehiclesStatesSelected,
          onChecked: (s) {
            setState(() {
              vehiclesStatesSelected = s ?? false;
            });
          },
          subTitle: vehiclesStatesSelected
              ?'statecount'.tr(namedArgs:{'s':vehiclesStates.length.toString()})
              : null,
        ),
      if(drivers.isNotEmpty)
        ImportListElement(
          title: 'thechauffeurs'.tr(),
          checked: driversSelected,
          onChecked: (s) {
            setState(() {
              driversSelected = s ?? false;
            });
          },
          subTitle: driversSelected
              ?'conducteurcount'.tr(namedArgs:{'c':drivers.length
              .toString()})
              : null,
        ),
      if(driversDocs.isNotEmpty)
        ImportListElement(
          title: 'chaufdocuments'.tr(),
          checked: driversDocsSelected,
          onChecked: (s) {
            setState(() {
              driversDocsSelected = s ?? false;
            });
          },
          subTitle: driversDocsSelected
              ?'doccount'.tr(namedArgs:{'d':driversDocs.length
              .toString()})
              : null,
        ),
      if(driversStates.isNotEmpty)
        ImportListElement(
          title: 'disponibilite'.tr(),
          checked: driversStatesSelected,
          onChecked: (s) {
            setState(() {
              driversStatesSelected = s ?? false;
            });
          },
          subTitle: driversStatesSelected
              ?'dispcount'.tr(namedArgs:{'d':driversStates.length
              .toString()})
              : null,
        ),
      if(logs.isNotEmpty)
        ImportListElement(
          title: 'journal'.tr(),
          checked: logsSelected,
          onChecked: (s) {
            setState(() {
              logsSelected = s ?? false;
            });
          },
          subTitle: logsSelected
              ?'logcount'.tr(namedArgs:{'l':logs.length
              .toString()})
              : null,
        ),
      if(plannings.isNotEmpty)
        ImportListElement(
          title: 'planifications'.tr(),
          checked: planningsSelected,
          onChecked: (s) {
            setState(() {
              planningsSelected = s ?? false;
            });
          },
          subTitle: planningsSelected
              ?'planningcount'.tr(namedArgs:{'p':logs.length
              .toString()})
              : null,
        ),
      if(repairs.isNotEmpty)
        ImportListElement(
          title: 'thereparations'.tr(),
          checked: repairsSelected,
          onChecked: (s) {
            setState(() {
              repairsSelected = s ?? false;
            });
          },
          subTitle: repairsSelected
              ?'reparationcount'.tr(namedArgs:{'r':logs.length
              .toString()})
              : null,
        ),
      if(providers.isNotEmpty)
        ImportListElement(
          title: 'prestataires'.tr(),
          checked: providersSelected,
          onChecked: (s) {
            setState(() {
              providersSelected = s ?? false;
            });
          },
          subTitle: providersSelected
              ?'prestcount'.tr(namedArgs:{'p':logs.length
              .toString()})
              : null,
        ),
    ];
  }

  void loadFile() async{
    if(widget.backupFile==null&& widget.backup!=null){
      DatabaseGetter.storage!.getFileDownload(bucketId: backupId, fileId: widget
          .backup!.id).then((value) {
        loadedFile=value;
        decompressFile();
        setState(() {
          progress=60;
        });
      });
    }
    else if(widget.backupFile!=null){
      loadedFile=widget.backupFile;
      decompressFile();
      setState(() {
        progress=60;
      });
    }

  }

  void decompressFile() async{
    if(loadedFile!=null){
      var zipper=GZip();
      loadedFile=Uint8List.fromList(await zipper.decompress(loadedFile!));
      setState(() {
        progress=70;
      });
      decryptFile();

    }
  }
  String? decryptedString;
  void decryptFile(){
    if(loadedFile!=null && DatabaseGetter.encrypter!=null){
      decryptedString=DatabaseGetter.encrypter!.decrypt64(utf8.decode(loadedFile!),
          iv: DatabaseGetter.iv);
      setState(() {
        progress=80;
      });
      convertToMap();
    }
  }

  void convertToMap(){
    Map<String,dynamic> content=jsonDecode(decryptedString!);
    Future.wait([
    if(content.containsKey('vehicles'))
    getVehicles(content['vehicles']!),
    if(content.containsKey('vehicledocs'))
    getVehiclesDocs(content['vehicledocs']!),
    if(content.containsKey('vehiclestates'))
    getVehiclesStates(content['vehiclestates']!),
    if(content.containsKey('drivers'))
    getDrivers(content['drivers']!),
    if(content.containsKey('driversdocs'))
    getDriversDocs(content['driversdocs']!),
    if(content.containsKey('driversstates'))
    getDriversStates(content['driversstates']!),
    if(content.containsKey('repairs'))
    getRepairs(content['repairs']!),
    if(content.containsKey('providers'))
    getProviders(content['providers']!),
    if(content.containsKey('logs'))
    getLogs(content['logs']!),
    if(content.containsKey('plannings'))
    getPlannings(content['plannings']!),
    ]);

    setState(() {
      progress=100;
    });

  }

  Map<String,Vehicle> vehicles={};
  bool vehiculesSelected=true;
  Map<String,DocumentVehicle> vehiclesDocs={};
  bool vehiclesDocsSelected=true;

  Map<String,Etat> vehiclesStates={};
  bool vehiclesStatesSelected=true;

  Map<String,Reparation> repairs={};
  bool repairsSelected=true;

  Map<String,Client> providers={};
  bool providersSelected=true;

  Map<String,Conducteur> drivers={};
  bool driversSelected=true;

  Map<String,DocumentChauffeur> driversDocs={};
  bool driversDocsSelected=true;

  Map<String,DisponibiliteChauffeur> driversStates={};
  bool driversStatesSelected=true;

  Map<String,Planning> plannings={};
  bool planningsSelected=true;

  Map<String,Activity> logs={};
  bool logsSelected=true;

  Future<void> getVehicles(List<dynamic> list) async {
    for(var element in list){
      vehicles[element[r'$id']]=Vehicle.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getVehiclesDocs(List<dynamic> list) async {
    for(var element in list){
      vehiclesDocs[element[r'$id']]=DocumentVehicle.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getVehiclesStates(List<dynamic> list) async {
    for(var element in list){
      vehiclesStates[element[r'$id']]=Etat.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getDrivers(List<dynamic> list) async {
    for(var element in list){
      drivers[element[r'$id']]=Conducteur.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getDriversDocs(List<dynamic> list) async {
    for(var element in list){
      driversDocs[element[r'$id']]=DocumentChauffeur.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getDriversStates(List<dynamic> list) async {
    for(var element in list){
      driversStates[element[r'$id']]=DisponibiliteChauffeur.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getRepairs(List<dynamic> list) async {
    for(var element in list){
      repairs[element[r'$id']]=Reparation.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getProviders(List<dynamic> list) async {
    for(var element in list){
      providers[element[r'$id']]=Client.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getPlannings(List<dynamic> list) async {
    for(var element in list){
      plannings[element[r'$id']]=Planning.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }
  Future<void> getLogs(List<dynamic> list) async {
    for(var element in list){
      logs[element[r'$id']]=Activity.fromJson(jsonDecode(jsonEncode
        (element)));
    }

  }

  bool restoring=false;
  Future<void> restoreData() async{
    if(DatabaseGetter.encrypter!=null && !restoring){
      setState(() {
        restoring=true;
      });
      da.Client client = da.Client()
        ..setEndpoint(endpoint)
        ..setProject(project)
        ..setKey(secretKey);

      RestoreDatabase restoreDatabase=RestoreDatabase(databases: da.Databases
        (client),
      vehicles: vehiculesSelected?vehicles:null,
      vehiclesDocs: vehiclesDocsSelected?vehiclesDocs:null,
      vehiclesStates: vehiclesStatesSelected?vehiclesStates:null,
      drivers: driversSelected?drivers:null,
      driversDocs: driversDocsSelected?driversDocs:null,
      driversStates: driversStatesSelected?driversStates:null,
      repairs: repairsSelected?repairs:null,
      providers: providersSelected?providers:null,
      logs: logsSelected?logs:null,
      plannings: planningsSelected?plannings:null,
      );

      if(addNewData){
        await restoreDatabase.addNewData();
      }
      else if(appendAllData){
        await restoreDatabase.addOrUpdateNewData();

      }
      else if(deleteAllData){
        print('normalement tsupprimi');
        await restoreDatabase.deleteThenAddData();

      }
      else{
        await restoreDatabase.addNewData();
      }

      Future.delayed(const Duration(milliseconds: 20)).then((s){
        context.pop();

        displayInfoBar(context,
            builder: (BuildContext context, void Function() close) {
              return InfoBar(
                title: const Text('done').tr(),
                severity: InfoBarSeverity.success,
              );
            }, duration: snackbarShortDuration);
      });

    }

    setState(() {
      restoring=false;
    });

  }


}
