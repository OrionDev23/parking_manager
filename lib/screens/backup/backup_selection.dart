import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:parc_oto/theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/driver_provider.dart';
import '../../providers/log_provider.dart';
import '../../providers/planning_provider.dart';
import '../../providers/repair_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../utilities/file_manipulation.dart';
import 'import_list_element.dart';

class BackupSelection extends StatefulWidget {
  const BackupSelection({super.key});

  @override
  State<BackupSelection> createState() => _BackupSelectionState();
}

class _BackupSelectionState extends State<BackupSelection> {

  @override
  void initState() {
    if (!VehicleProvider.downloadedVehicles) {
      refreshVehicles();
    }
    if (!DriverProvider.downloadedConducteurs) {
      refreshDrivers();
    }
    if (!RepairProvider.downloadedReparations) {
      refreshRepairs();
    }
    if (!LogProvider.downloadedActivities) {
      refreshLogs();
    }
    if (!PlanningProvider.downloadedPlanning) {
      refreshPlannings();
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FilledButton(
                        child:
                        checkers.every((element) => element == true)
                            ? const Text('clear').tr()
                            : const Text('selectall').tr(),
                        onPressed: () {
                          if (checkers.every((element) => element)) {
                            for (int i = 0; i < checkers.length; i++) {
                              checkers[i] = false;
                            }
                          } else {
                            for (int i = 0; i < checkers.length; i++) {
                              checkers[i] = true;
                            }
                          }
                          setState(() {});
                        }),
                  )
                ],
              ),
              vehicleElement(),
              condElement(),
              repairElement(),
              planningElement(),
              logElement(),
            ],
          ),
        ),
        SizedBox(
          height: 40.px,
          width: 400.px,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Button(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('annuler').tr()),
              ),
              smallSpace,
              Expanded(
                child: FilledButton(
                    onPressed: () {makeFile();}, child: const Text('confirmer')
                    .tr()),
              )
            ],
          ),
        ),
      ],
    );
  }

  List<bool> checkers = [false, false, false, false, false];
  List<bool> refreshers = [false, false, false, false, false];


  Future<void> refreshVehicles() async {
    if (!refreshers[0]) {
      setState(() {
        refreshers[0] = true;
      });
      await Future.wait([
        VehicleProvider().refreshVehicles(),
        VehicleProvider().refreshStates(),
        VehicleProvider().refreshDocuments()
      ]);
      setState(() {
        refreshers[0] = false;
      });
    }
  }

  Future<void> refreshDrivers() async {
    if (!refreshers[1]) {
      setState(() {
        refreshers[1] = true;
      });
      await Future.wait([
        DriverProvider().refreshConducteurs(),
        DriverProvider().refreshDocuments(),
        DriverProvider().refreshDisp()
      ]);
      setState(() {
        refreshers[1] = false;
      });
    }
  }

  Future<void> refreshRepairs() async {
    if (!refreshers[2]) {
      setState(() {
        refreshers[2] = true;
      });
      await Future.wait([
        RepairProvider().refreshReparations(),
        RepairProvider().refreshPrestataires()
      ]);
      setState(() {
        refreshers[2] = false;
      });
    }
  }

  Future<void> refreshPlannings() async {
    if (!refreshers[3]) {
      setState(() {
        refreshers[3] = true;
      });
      await Future.wait([
        PlanningProvider().refreshPlannings(),
      ]);
      setState(() {
        refreshers[3] = false;
      });
    }
  }

  Future<void> refreshLogs() async {
    if (!refreshers[4]) {
      setState(() {
        refreshers[4] = true;
      });
      await Future.wait([
        LogProvider().refreshLogs(),
      ]);
      setState(() {
        refreshers[4] = false;
      });
    }
  }

  String prepareText(Map<String, MapEntry<String, String>> counters) {
    String result = "";
    counters.forEach((key, value) {
      if (result.isEmpty) {
        result = key.tr(namedArgs: {value.key: value.value});
      } else {
        result = "$result, ${key.tr(namedArgs: {value.key: value.value})}";
      }
    });
    return result;
  }

  Widget vehicleElement() {
    return ImportListElement(
      title: 'vehicules'.tr(),
      checked: checkers[0],
      refreshing: refreshers[0],
      onRefresh: () async {
        await refreshVehicles();
      },
      onChecked: (s) {
        setState(() {
          checkers[0] = s ?? false;
        });
      },
      subTitle: checkers[0]
          ? prepareText({
        'vehiclescount': MapEntry<String, String>(
            'v', VehicleProvider.vehicles.length.toString()),
        'doccount': MapEntry<String, String>(
            'd', VehicleProvider.documentsVehicules.length.toString()),
        'statecount': MapEntry<String, String>(
            's', VehicleProvider.etats.length.toString()),
      })
          : null,
    );
  }

  Widget condElement() {
    return ImportListElement(
      title: 'chauffeurs'.tr(),
      checked: checkers[1],
      refreshing: refreshers[1],
      onRefresh: () async {
        await refreshDrivers();
      },
      onChecked: (s) {
        setState(() {
          checkers[1] = s ?? false;
        });
      },
      subTitle: checkers[1]
          ? prepareText({
        'conducteurcount':
        MapEntry('c', DriverProvider.conducteurs.length.toString()),
        'doccount': MapEntry(
            'd', DriverProvider.documentConducteurs.length.toString()),
        'dispcount': MapEntry('d',
            DriverProvider.disponibiliteConducteurs.length.toString()),
      })
          : null,
    );
  }

  Widget repairElement() {
    return ImportListElement(
      title: 'reparations'.tr(),
      checked: checkers[2],
      refreshing: refreshers[2],
      onRefresh: () async {
        await refreshRepairs();
      },
      onChecked: (s) {
        setState(() {
          checkers[2] = s ?? false;
        });
      },
      subTitle: checkers[2]
          ? prepareText({
        'reparationcount':
        MapEntry('r', RepairProvider.reparations.length.toString()),
        'prestcount':
        MapEntry('p', RepairProvider.prestataires.length.toString()),
      })
          : null,
    );
  }

  Widget planningElement() {
    return ImportListElement(
      title: 'planifications'.tr(),
      checked: checkers[3],
      refreshing: refreshers[3],
      onRefresh: () async {
        await refreshPlannings();
      },
      onChecked: (s) {
        setState(() {
          checkers[3] = s ?? false;
        });
      },
      subTitle: checkers[3]
          ? prepareText({
        'planningcount':
        MapEntry('p', PlanningProvider.plannings.length.toString()),
      })
          : null,
    );
  }

  Widget logElement() {
    return ImportListElement(
      title: 'journal'.tr(),
      checked: checkers[4],
      refreshing: refreshers[4],
      onRefresh: () async {
        await refreshLogs();
      },
      onChecked: (s) {
        setState(() {
          checkers[4] = s ?? false;
        });
      },
      subTitle: checkers[4]
          ? prepareText({
        'logcount':
        MapEntry('l', LogProvider.activities.length.toString()),
      })
          : null,
    );
  }


  void makeFile(){
    String result="{";
    if(checkers[0]){

      result='$result ${addList("vehicles", VehicleProvider.vehicles, true)}';
      result='$result ${addList("vehicledocs", VehicleProvider
          .documentsVehicules, true)}';
      result='$result ${addList("vehiclestates", VehicleProvider
          .etats, false)} ]';
    }
    if(checkers[1]){
      if(checkers[0]){
        result='$result,';
      }
      result='$result ${addList("drivers", DriverProvider.conducteurs, true)}';
      result='$result ${addList("driversdocs", DriverProvider
          .documentConducteurs, true)}';
      result='$result ${addList("driversstates", DriverProvider
          .disponibiliteConducteurs, false)} ]';
    }
    if(checkers[2]){
      if(checkers[0] || checkers[1]){
        result='$result,';
      }
      result='$result ${addList("repairs", RepairProvider.reparations, true)}';
      result='$result ${addList("providers", RepairProvider
          .prestataires, false)} ]';
    }
    if(checkers[3]){
      if(checkers[0] || checkers[1] || checkers[2]){
        result='$result,';
      }
      result='$result ${addList("plannings", PlanningProvider.plannings,
          false)} ]';
    }
    if(checkers[4]){
      if(checkers[0] || checkers[1] || checkers[2]|| checkers[3]){
        result='$result,';
      }
      result='$result ${addList("logs", LogProvider.activities,
          false)} ]';
    }
    result='$result }';
    DateTime now=DateTime.now();
    saveThisFile(Uint8List.fromList(utf8.encode(result)), "BACKUP ${now
        .day}-${now.month}-${now.year}-${now.hour}-${now.minute}-${now
        .second}",'json',"text/plain");
  }


  String addList(String title,Map<String,dynamic> elements,bool next){
    String result='"$title" :[';
    bool first=true;
    elements.forEach((key, value) {
      if(first){
        first=false;
        result='$result ${jsonify(value.toJson())}';
      }
      else{
        result='$result, ${jsonify(value.toJson())}';
      }
    });
    if(next){
      result='$result ],';
    }

    return result;
  }
}
