import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:parc_oto/datasources/vehicle_states/vehicle_states_datasrouce.dart';
import 'package:parc_oto/screens/reparation/manager/reparation_table.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_management.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../datasources/vehicle/vehicules_datasource.dart';
import '../../../providers/client_database.dart';
import '../../../serializables/vehicle/state.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';
import '../../../utilities/vehicle_util.dart';
import '../manager/vehicles_table.dart';

class StateForm extends StatefulWidget {
  final Etat? etat;
  final Vehicle? vehicle;
  final int? type;
  final VStatesDatasource? datasource;
  final VehiculeDataSource? vehicleDatasource;

  const StateForm({
    super.key,
    this.etat,
    this.vehicle,
    this.type,
    this.vehicleDatasource,
    this.datasource,
  });

  @override
  State<StateForm> createState() => StateFormState();
}

class StateFormState extends State<StateForm> {
  int type = 0;
  double valeur = 0;
  String remarque = '';

  DateTime date = DateTime.now();
  Reparation? selectedReparation;
  Vehicle? selectedVehicle;

  bool affectNow = false;

  bool loadingVehicle = false;
  bool loadingReparation = false;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    if (widget.etat != null) {
      documentID = widget.etat!.id;
      remarque = widget.etat!.remarque ?? '';
      valeur = widget.etat!.valeur ?? 0;
      type = widget.etat!.type;
      date = widget.etat!.date ?? widget.etat!.createdAt ?? DateTime.now();
      if (widget.etat!.ordreID != null) {
        downloadReparation(widget.etat!.ordreID!);
      }
    } else if (widget.vehicle != null) {
      selectedVehicle = widget.vehicle;
      if (widget.type != null) {
        type = widget.type!;
      }
    }
  }

  Future<void> downloadVehicle(String id) async {
    loadingVehicle = true;
    await ClientDatabase.database!
        .getDocument(
            databaseId: databaseId, collectionId: vehiculeid, documentId: id)
        .then((value) {
      if (value.data.isNotEmpty) {
        selectedVehicle = value
            .convertTo((p0) => Vehicle.fromJson(p0 as Map<String, dynamic>));
      }
    });
    if (mounted) {
      setState(() {
        loadingVehicle = false;
      });
    }
  }

  Future<void> downloadReparation(String id) async {
    loadingReparation = true;
    await ClientDatabase.database!
        .getDocument(
            databaseId: databaseId, collectionId: reparationId, documentId: id)
        .then((value) {
      if (value.data.isNotEmpty) {
        selectedReparation = value
            .convertTo((p0) => Reparation.fromJson(p0 as Map<String, dynamic>));
      }
    });
    if (mounted) {
      setState(() {
        loadingReparation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Container(
        decoration: BoxDecoration(
            color: appTheme.backGroundColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: kElevationToShadow[2]),
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: <Widget>[
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                    leading: const Text('vehicule').tr(),
                    title: Text(selectedVehicle?.matricule ??
                        widget.vehicle?.matricule ??
                        widget.etat?.vehicleMat ??
                        '/'),
                    onPressed: widget.vehicle != null ||
                            loadingVehicle ||
                            widget.etat?.vehicle != null
                        ? null
                        : () async {
                            selectedVehicle = await showDialog<Vehicle>(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return ContentDialog(
                                    constraints: BoxConstraints.tight(
                                        Size(700.px, 550.px)),
                                    title: const Text('selectvehicle').tr(),
                                    style: ContentDialogThemeData(
                                        titleStyle: appTheme.writingStyle
                                            .copyWith(
                                            fontWeight:
                                            FontWeight.bold)),
                                    content: const VehicleTable(
                                      selectV: true,
                                    ),
                                    actions: [Button(child: const Text('fermer').tr(),
                                        onPressed: (){
                                          Navigator.of(context).pop();
                                        })],
                                  );
                                });
                            setState(() {});
                          },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                    leading: Row(
                      children: [
                        Icon(FluentIcons.category_classification,
                            color: appTheme.color.lightest),
                        bigSpace,
                        Text('chstates',
                                style: placeStyle.copyWith(
                                    fontWeight: FontWeight.bold))
                            .tr(),
                      ],
                    ),
                    title: ComboBox<int>(
                      items: List.generate(
                          5,
                          (index) => ComboBoxItem<int>(
                                value: index,
                                child:
                                    Text(VehiclesUtilities.getEtatName(index))
                                        .tr(),
                              )),
                      value: type,
                      onChanged: (s) {
                        setState(() {
                          type = s ?? 0;
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      leading: SizedBox(
                          width: 120.px,
                          child: Text('date',
                                  style: placeStyle.copyWith(
                                      fontWeight: FontWeight.bold))
                              .tr()),
                      title: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              flex: 7,
                              child: DatePicker(
                                locale: appTheme.locale,
                                selected: date,
                                startDate: DateTime(1900),
                                endDate: DateTime(2100),
                                onChanged: (s) {
                                  if (s != date) {
                                    date = DateTime(s.year, s.month, s.day,
                                        date.hour, date.minute, date.second);

                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const m.VerticalDivider(),
                            Expanded(
                                flex: 3,
                                child: TimePicker(
                                  hourFormat: HourFormat.HH,
                                  locale: appTheme.locale,
                                  selected: date,
                                  onChanged: (s) {
                                    if (date != s) {
                                      date = DateTime(date.year, date.month,
                                          date.day, s.hour, s.minute, s.second);
                                      setState(() {});
                                    }
                                  },
                                )),
                          ])),
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.all(5),
                    leading: Icon(
                      FluentIcons.add_notes,
                      color: appTheme.color.lightest,
                    ),
                    title: TextBox(
                      controller: TextEditingController(text: remarque),
                      onChanged: (String value) {
                        remarque = value;
                      },
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      placeholder: 'adddescription'.tr(),
                      maxLength: 100,
                      style: TextStyle(
                          fontSize: 18,
                          color: appTheme.writingStyle.color,
                          fontWeight: FontWeight.w400),
                      decoration: BoxDecoration(
                        color: appTheme.fillColor,
                      ),
                    ),
                  ),
                  const Divider(),
                  if (type == 2)
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      leading: const Text('reparation').tr(),
                      title: Text(selectedReparation?.numero != null ||
                              widget.etat?.ordreNum != null
                          ? NumberFormat('00000000').format(
                              selectedReparation?.numero ??
                                  widget.etat?.ordreNum)
                          : '/'),
                      onPressed: loadingReparation ||
                              widget.etat?.ordreID != null
                          ? null
                          : () async {
                              selectedReparation =    await showDialog<Reparation>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) {
                                    return ContentDialog(
                                      constraints: BoxConstraints.tight(
                                          Size(700.px, 550.px)),
                                      title: const Text('selectreparation').tr(),
                                      style: ContentDialogThemeData(
                                          titleStyle: appTheme.writingStyle
                                              .copyWith(
                                              fontWeight:
                                              FontWeight.bold)),
                                      content: const ReparationTable(
                                        selectD: true,
                                      ),
                                      actions: [Button(child: const Text('fermer').tr(),
                                          onPressed: (){
                                            Navigator.of(context).pop();
                                          })],
                                    );
                                  });


                              setState(() {
                                valeur =
                                    selectedReparation?.getPrixTTC() ?? valeur;
                              });
                            },
                    ),
                  if (type == 2) const Divider(),
                  if (type == 2)
                    ListTile(
                      contentPadding: const EdgeInsets.all(5),
                      leading: Icon(
                        FluentIcons.money,
                        color: appTheme.color.lightest,
                      ),
                      title: TextBox(
                        controller: TextEditingController(
                            text: valeur.toStringAsFixed(2)),
                        onChanged: (String value) {
                          valeur = double.tryParse(value) ?? 0;
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        maxLines: 1,
                        placeholder: 'montantt'.tr(),
                        maxLength: 30,
                        style: TextStyle(
                            fontSize: 18,
                            color: appTheme.writingStyle.color,
                            fontWeight: FontWeight.w400),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^(\d+)?\.?\d{0,2}'))
                        ],
                        decoration: BoxDecoration(
                          color: appTheme.fillColor,
                        ),
                      ),
                    ),
                  if (type == 2) const Divider(),
                  if (widget.vehicle == null)
                    ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                        title: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                'assignnow',
                                style: placeStyle.copyWith(
                                    fontWeight: FontWeight.bold),
                              ).tr(),
                              bigSpace,
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: ToggleSwitch(
                                    checked: affectNow,
                                    onChanged: (bool value) {
                                      setState(() {
                                        affectNow = value;
                                      });
                                    },
                                  )),
                            ])),
                ],
              ),
            ),
            bigSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(child: const Text('fermer').tr(),onPressed: (){Navigator.of
                (context).pop();}),
                bigSpace,
                FilledButton(
                    onPressed: sumbmiting ? null : submit,
                    child: sumbmiting
                        ? const ProgressRing()
                        : const Text('confirmer').tr()),
              ],
            ),
          ],
        ));
  }

  bool sumbmiting = false;

  String? documentID;

  void submit() async {
    if (selectedVehicle == null &&
        widget.etat?.vehicle == null &&
        widget.vehicle == null) {
      showMessage('vehiclerequired', 'erreur');
      return;
    }
    setState(() {
      sumbmiting = true;
    });
    documentID ??= DateTime.now()
        .difference(ClientDatabase.ref)
        .inMilliseconds
        .abs()
        .toString();
    Etat etat = Etat(
      id: documentID!,
      vehicle: selectedVehicle?.id ??
          widget.etat?.vehicle ??
          widget.vehicle?.id ??
          '',
      vehicleMat: selectedVehicle?.matricule ??
          widget.etat?.vehicleMat ??
          widget.vehicle?.matricule ??
          '',
      remarque: remarque,
      type: type,
      createdBy: ClientDatabase.me.value?.id,
      ordreID: selectedReparation?.id,
      ordreNum: selectedReparation?.numero,
      valeur: valeur,
    );
    await updateOrCreate(etat).then((value) {
      if (affectNow || widget.vehicle != null) {
        ClientDatabase.database!.updateDocument(
            databaseId: databaseId,
            collectionId: vehiculeid,
            documentId: selectedVehicle?.id ??
                widget.vehicle?.id ??
                widget.etat?.vehicle ??
                '',
            data: {
              'etat': documentID,
              'etatactuel': type,
            }).then((value) {
          if (widget.vehicle != null && widget.vehicleDatasource != null) {
            widget.vehicleDatasource!.data[widget.vehicleDatasource!.data
                    .indexOf(MapEntry(widget.vehicle!.id, widget.vehicle!))] =
                MapEntry(widget.vehicle!.id,
                    widget.vehicle!.changeEtat(documentID!));
            widget.vehicleDatasource!.refreshDatasource();
          } else if (affectNow) {
            widget.datasource?.refreshDatasource();
          }
        });
      }
      Navigator.pop(context);

      displayMessageDone();
      VehicleManagementState.stateChanges.value++;
    }).onError((error, stackTrace) {
      setState(() {
        displayMessageError();
        showMessage('erreur', 'erreur');
        sumbmiting = false;
      });
    });
  }

  Future<void> updateOrCreate(Etat etat) async {
    if (widget.etat != null) {
      await ClientDatabase.database!.updateDocument(
        databaseId: databaseId,
        collectionId: etatId,
        documentId: documentID!,
        data: etat.toJson(),
      );

      ClientDatabase().ajoutActivity(5, documentID!, docName: etat.vehicleMat);
    } else {
      await ClientDatabase.database!.createDocument(
        databaseId: databaseId,
        collectionId: etatId,
        documentId: documentID!,
        data: etat.toJson(),
      );
      ClientDatabase().ajoutActivity(4, documentID!, docName: etat.vehicleMat);
    }
  }

  void showMessage(String message, String title) {
    showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title).tr(),
        content: Text(
          message,
        ).tr(),
        actions: [
          Button(
            child: const Text('OK').tr(),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void displayMessageDone() {
    displayInfoBar(context, builder: (co, s) {
      return InfoBar(
        severity: InfoBarSeverity.success,
        title: Text(widget.etat != null ? 'etatmodif' : 'etatajout').tr(),
      );
    });
  }

  void displayMessageError() {
    displayInfoBar(context, builder: (co, s) {
      return InfoBar(
        severity: InfoBarSeverity.error,
        title: const Text('erreur').tr(),
      );
    });
  }
}
