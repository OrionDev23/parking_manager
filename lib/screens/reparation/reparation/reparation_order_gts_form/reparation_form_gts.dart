import 'package:appwrite/appwrite.dart' hide Client;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/screens/reparation/reparation/reparation_order_gts_form/task_group_widget.dart';
import 'package:parc_oto/serializables/reparation/task_group.dart';
import '../../../../providers/client_database.dart';
import '../../../../providers/repair_provider.dart';
import '../../../../providers/vehicle_provider.dart';
import '../../../../serializables/reparation/fiche_reception.dart';
import '../../../entreprise/entreprise.dart';
import '../../../prestataire/prestataire_table.dart';
import '../../fiche_reception/manager/fiche_reception_table.dart';
import '../../../../serializables/client.dart';
import '../../../../theme.dart';
import '../../../../widgets/big_title_form.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../pdf_generation/pdf_preview_custom.dart';
import '../../../../pdf_generation/pdf_theming.dart' as pdf_theme;
import '../../../../serializables/reparation/reparation.dart';
import '../../../../serializables/vehicle/vehicle.dart';
import '../../../../utilities/vehicle_util.dart';
import '../../../../widgets/empty_table_widget.dart';
import '../reparation_order_form/entreprise_placement.dart';

class ReparationFormGts extends StatefulWidget {
  final Reparation? reparation;

  const ReparationFormGts({required super.key, this.reparation});

  @override
  State<ReparationFormGts> createState() => ReparationFormGtsState();
}

class ReparationFormGtsState extends State<ReparationFormGts>
    with AutomaticKeepAliveClientMixin<ReparationFormGts> {
  static Map<Key, int> reservedOrders = {};

  TextEditingController numOrdre = TextEditingController();
  DateTime selectedDate = DateTime.now();

  Client? selectedPrest;
  Vehicle? selectedVehicle;
  FicheReception? selectedFicheReception;
  TextEditingController marque = TextEditingController();
  TextEditingController type = TextEditingController();
  TextEditingController matricule = TextEditingController();
  TextEditingController km = TextEditingController();
  TextEditingController couleur = TextEditingController();

  TextEditingController nchassi = TextEditingController();
  TextEditingController nmoteur = TextEditingController();
  TextEditingController matriculeConducteur = TextEditingController();
  TextEditingController nom = TextEditingController();
  TextEditingController prenom = TextEditingController();
  DateTime anneeUtil = DateTime.now();

  double carburant = 4;

  TextEditingController remarqueEntretien = TextEditingController();
  @override
  void initState() {
    if (widget.reparation != null) {
      initValues();
    } else {
      assignOrderNumber();
    }
    super.initState();
  }

  void initValues() async {
    if (widget.reparation != null) {
      documentID = widget.reparation!.id;
      assigningOrederNumber = true;
      remarqueEntretien.text = widget.reparation!.remarque ?? '';
      numOrdre.text = widget.reparation!.numero.toString();
      reservedOrders[widget.key!] = widget.reparation!.numero;
      matricule.text = widget.reparation!.vehiculemat ?? '';
      nchassi.text = widget.reparation!.nchassi ?? '';
      selectedDate = widget.reparation!.date;
      designations =
          List.generate(widget.reparation!.tasks?.length ?? 0, (index) {
        return TaskGroupWidget(
            key: UniqueKey(),
            taskGroup: widget.reparation!.tasks![index]);
      });
      setState(() {
        assigningOrederNumber = false;
      });
    }
  }

  Future<void> getPrestatataire() async {
    if (widget.reparation != null && widget.reparation!.prestataire != null) {
      selectedPrest = await RepairProvider()
          .getPrestataire(widget.reparation!.prestataire!);
    }
  }

  Future<void> getVehicle({String? vehicleFromFiche}) async {
    if(vehicleFromFiche!=null && selectedFicheReception!=null){
      selectedVehicle = await VehicleProvider().getVehicle(vehicleFromFiche);
    }
    else{
      if (widget.reparation != null && widget.reparation!.vehicule != null) {
        selectedVehicle =
        await VehicleProvider().getVehicle(widget.reparation!.vehicule!);
      }
    }

  }
  Future<void> getFicheReception() async {
    if (widget.reparation != null && widget.reparation!.ficheReception != null) {
      selectedFicheReception =
          await RepairProvider().getFiche(widget.reparation!.ficheReception!);
    }
  }



  bool assigningOrederNumber = false;

  bool errorNumOrder = false;
  bool changedPics=false;

  void assignOrderNumber() async {
    assigningOrederNumber = true;
    if (mounted) {
      setState(() {});
    }
    await DatabaseGetter.database!.listRows(
        databaseId: databaseId,
        tableId: reparationId,
        queries: [
          Query.orderDesc('numero'),
          Query.limit(1),
        ]).then((value) {
      if (value.rows.length == 1) {
        numOrdre.text = (value.rows[0]
                    .convertTo(
                        (p0) => Reparation.fromJson(p0))
                    .numero +
                1)
            .toString();
      } else {
        numOrdre.text = (reservedOrders.length + 1).toString();
      }

      while (testIfReservedContained(int.parse(numOrdre.text))) {
        numOrdre.text = (int.parse(numOrdre.text) + 1).toString();
      }
      reservedOrders[widget.key!] = (int.parse(numOrdre.text));
    });

    assigningOrederNumber = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> testIfOrderNumberExists() async {
    bool result = false;

    if (testIfReservedContained(int.parse(numOrdre.text))) {
      setState(() {
        errorNumOrder = true;
      });
      result = true;
    } else {
      result = await DatabaseGetter.database!.listRows(
          databaseId: databaseId,
          tableId: reparationId,
          queries: [
            Query.orderDesc('numero'),
            Query.equal('numero', int.parse(numOrdre.text)),
            Query.limit(1),
          ]).then((value) {
        if (value.rows.length == 1) {
          setState(() {
            errorNumOrder = true;
          });
          return true;
        } else {
          setState(() {
            errorNumOrder = false;
          });
          return false;
        }
      }).onError((error, stackTrace) {
        return Future.value(false);
      });
    }

    return result;
  }

  bool testIfReservedContained(int value) {
    bool result = false;
    reservedOrders.forEach((key, v) {
      if (value == v && key != widget.key) {
        result = true;
        return;
      }
    });

    return result;
  }

  void getVehicleThenSetValues() async{
    setState(() {
      assigningOrederNumber=true;
    });
    await getVehicle(vehicleFromFiche: selectedFicheReception?.vehicule);
    if(selectedVehicle!=null){
      setVehicleValues();
    }
    setState(() {
      assigningOrederNumber=false;
    });

  }

  void setVehicleValues() {
    if (selectedVehicle == null) {
      marque.clear();
      type.clear();
      nchassi.clear();
      matricule.clear();
    } else {
      marque.text = VehiclesUtilities.getMarqueName(selectedVehicle!.marque);
      type.text = selectedVehicle!.type ?? '';
      nchassi.text = selectedVehicle!.numeroSerie ?? '';
      matricule.text = selectedVehicle!.matricule;
      anneeUtil = DateTime(selectedVehicle!.anneeUtil ?? 2023);
      nom.text = selectedVehicle!.nom ?? '';
      prenom.text = selectedVehicle!.prenom ?? '';
      matriculeConducteur.text = selectedVehicle!.matriculeConducteur ?? '';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      content: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  children: [
                    if (MyEntrepriseState.p != null)
                      const EntreprisePlacement(),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (errorNumOrder)
                          Text(
                            'numprorder',
                            style: TextStyle(color: Colors.red),
                          ).tr(),
                        if (errorNumOrder) smallSpace,
                        Row(
                          children: [
                            Text(
                              'ordrereparation'.tr().toUpperCase(),
                              style: headerStyle,
                            ),
                            smallSpace,
                            Container(
                              width: 200.px,
                              height: 40.px,
                              decoration: BoxDecoration(
                                border: Border.all(),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    Text(
                                      'num',
                                      style: boldStyle,
                                    ).tr(),
                                    smallSpace,
                                    Flexible(
                                      child: TextBox(
                                        controller: numOrdre,
                                        enabled: widget.reparation == null,
                                        placeholder: 'num'.tr(),
                                        placeholderStyle: placeStyle,
                                        style: appTheme.writingStyle,
                                        cursorColor: appTheme.color.darker,
                                        decoration: WidgetStatePropertyAll(
                                            BoxDecoration(
                                                color: appTheme.fillColor)),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onChanged: (s) async {
                                          if (s.isNotEmpty) {
                                            if (!await testIfOrderNumberExists()) {
                                              reservedOrders[widget.key!] =
                                                  int.parse(s);
                                              setState(() {});
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'date',
                      style: boldStyle,
                    ).tr(),
                    smallSpace,
                    SizedBox(
                      width: 200.px,
                      height: 30.px,
                      child: DatePicker(
                        selected: selectedDate,
                        onChanged: (s) {
                          setState(() {
                            selectedDate = s;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                smallSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 350.px,
                      height: 50.px,
                      child: ListTile(
                        leading: Text(
                          'fichereception',
                          style: boldStyle,
                        ).tr(),
                        title:
                            Text(selectedFicheReception!=null?NumberFormat('00000000', 'fr').format(selectedFicheReception?.numero) : 'nonind'.tr()),
                        onPressed: () async {
                          selectedFicheReception = await showDialog<FicheReception>(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return ContentDialog(
                                  constraints: BoxConstraints.tight(
                                      Size(700.px, 550.px)),
                                  title: const Text('selectedfiche').tr(),
                                  style: ContentDialogThemeData(
                                      titleStyle: appTheme.writingStyle
                                          .copyWith(
                                              fontWeight: FontWeight.bold)),
                                  content: const FicheReceptionTable(
                                    selectD: true,
                                  ),
                                  actions: [
                                    Button(
                                        child: const Text('fermer').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        })
                                  ],
                                );
                              });
                          getVehicleThenSetValues();
                          },
                      ),
                    ),
                    smallSpace,
                    if (selectedVehicle != null)
                      IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () {
                            selectedVehicle = null;
                            setVehicleValues();
                          }),
                    const Spacer(),
                    SizedBox(
                      width: 250.px,
                      height: 50.px,
                      child: ListTile(
                        leading: Text(
                          'prestataire',
                          style: boldStyle,
                        ).tr(),
                        title: Text(selectedPrest?.nom ?? 'nonind'.tr()),
                        onPressed: () async {
                          selectedPrest = await showDialog<Client>(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return ContentDialog(
                                  constraints: BoxConstraints.tight(
                                      Size(700.px, 550.px)),
                                  title: const Text('selectprestataire').tr(),
                                  style: ContentDialogThemeData(
                                      titleStyle: appTheme.writingStyle
                                          .copyWith(
                                              fontWeight: FontWeight.bold)),
                                  content: const PrestataireTable(
                                    selectD: true,
                                  ),
                                  actions: [
                                    Button(
                                        child: const Text('fermer').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        })
                                  ],
                                );
                              });
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                smallSpace,
                const BigTitleForm(
                  bigTitle: 'travaileffect',
                  littleTitle: 'ajoutertaches',
                ),
                designationTable(appTheme),
              ],
            ),
          ),
          if (assigningOrederNumber)
            Positioned(
              top: 40.h,
              left: 40.w,
              child: const ProgressBar(),
            )
        ]),
      ),
      bottomBar: Container(
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(appTheme.color.lightest),
                ),
                onPressed: uploading ? null : showPdf,
                child: const Text('voir')),
            smallSpace,
            FilledButton(
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(appTheme.color.darkest),
                ),
                onPressed: uploading ? null : uploadForm,
                child: const Text('save').tr())
          ],
        ),
      ),
    );
  }





  @override
  void dispose() {
    reservedOrders.remove(widget.key);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<TaskGroupWidget> designations = List.empty(growable: true);

  void addDesignation() {
    designations.add(TaskGroupWidget(key:UniqueKey(),taskGroup: TaskGroup(numero: '',tasks: [''],time: 0,)));
    setState(() {});
  }

  Widget designationTable(AppTheme appTheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: appTheme.color.darkest),
          bottom: BorderSide(color: appTheme.color.darkest),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                    onPressed:
                        selectedDesignationsExist() ? deleteAllSelected : null,
                    child: const Text('delete').tr()),
                smallSpace,
                FilledButton(
                    onPressed: addDesignation, child: const Text('addgroup').tr()),
              ],
            ),
          ),
          smallSpace,
          Container(
            decoration: BoxDecoration(
              color: appTheme.color.darkest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            padding: const EdgeInsets.all(5),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(9),
                3: FlexColumnWidth(3),
              },
              children: [
                TableRow(children: [

                  TableCell(child: SizedBox()),
                  TableCell(
                      child: const Text(
                    'numero',
                    textAlign: TextAlign.start,
                  ).tr()),
                  TableCell(
                      child: const Text(
                    'desi',
                    textAlign: TextAlign.start,
                  ).tr()),
                  TableCell(
                      child: const Text(
                    '',
                    textAlign: TextAlign.center,
                  )),
                ]),
              ],
            ),
          ),
          designations.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(10),
                  width: 300.px,
                  height: 320.px,
                  child: const NoDataWidget())
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: appTheme.fillColor),
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(5)),
                  ),
                  child: Column(children: getDesignationList(appTheme)),
                ),
        ],
      ),
    );
  }

  bool selectedDesignationsExist() {
    for (int i = 0; i < designations.length; i++) {
      if (designations[i].taskGroup.selected) {
        return true;
      }
    }
    return false;
  }

  void deleteAllSelected() {
    List<TaskGroupWidget> temp = List.from(designations);
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].taskGroup.selected) {
        designations.remove(temp[i]);
      }
    }
    setState(() {});
  }

  List<Widget> getDesignationList(AppTheme appTheme) {
    return List.generate(designations.length, (index) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? appTheme.fillColor : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox(height: 65.px,),

                Checkbox(
                    checked: designations[index].taskGroup.selected,
                    onChanged: (s) {
                      setState(() {
                        designations[index].taskGroup.selected = s ?? false;
                      });
                    }),
              ],
            ),
            smallSpace,
            Flexible(
              child: designations[index],
            ),
          ],
        ),
      );
    });
  }

  String? documentID;

  bool uploading = false;

  void showPdf() {
    Reparation reparation = Reparation(
        id: '',
        numero: int.parse(numOrdre.text),
        ficheReception: selectedFicheReception?.id??'',
        date: selectedDate,
        tasks: designations.map((e) => e.taskGroup).toList(),
        nchassi: nchassi.text,
      showEntretien: false,

      prestataire: selectedPrest?.id,
        prestatairenom: selectedPrest?.nom,
        vehicule: selectedVehicle?.id,
        vehiculemat: selectedVehicle?.matricule,
       ficheReceptionNumber: selectedFicheReception?.numero??0,);

    showDialog(
        context: context,
        builder: (context) {
          return PdfPreviewPO(reparation: reparation);
        });
  }

  void uploadForm() async {
    if(selectedFicheReception==null){
      displayInfoBar(context,
          builder: (BuildContext context, void Function() close) {
        return InfoBar(
          title: const Text('ficherequired').tr(),
          severity: InfoBarSeverity.error,
        );
      }, duration: snackbarShortDuration);
      return;
    }
    if(selectedVehicle==null){

      displayInfoBar(context,
          builder: (BuildContext context, void Function() close) {
        return InfoBar(
          title: const Text('vehiclenotfound').tr(),
          severity: InfoBarSeverity.error,
        );
      }, duration: snackbarShortDuration);
      return;
    }
    setState(() {
      uploading = true;
    });
    bool modif = documentID != null;
    documentID ??= DateTime.now()
        .difference(DatabaseGetter.ref)
        .inMilliseconds
        .abs()
        .toString();
    Reparation reparation = Reparation(
        id: documentID!,
        numero: int.parse(numOrdre.text),
        date: selectedDate,
        tasks: designations.map((e) => e.taskGroup).toList(),
        nchassi: nchassi.text,
        showEntretien: false,
        prestataire: selectedPrest?.id,
        prestatairenom: selectedPrest?.nom,
        vehicule: selectedVehicle?.id,
        vehiculemat: selectedVehicle?.matricule,
      ficheReception: selectedFicheReception?.id??'', ficheReceptionNumber: selectedFicheReception?.numero??0,);

    if (!modif) {
      await Future.wait([
        createReparation(reparation),
        uploadActivity(modif, reparation),
      ]).then((value) {
        if (mounted) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('reparationajout').tr(),
              severity: InfoBarSeverity.success,
            );
          }, duration: snackbarShortDuration);
        }
      }).onError((error, stackTrace) {
        if (mounted) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('echec').tr(),
              severity: InfoBarSeverity.error,
            );
          }, duration: snackbarShortDuration);
        }
      });
    } else {
      await Future.wait(
              [updateReparation(reparation), uploadActivity(modif, reparation),])
          .then((value) {
        if (mounted) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('reparationmodif').tr(),
              severity: InfoBarSeverity.success,
            );
          }, duration: snackbarShortDuration);
        }
      }).onError((error, stackTrace) {
        if (mounted) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('echec').tr(),
              severity: InfoBarSeverity.error,
            );
          });
        }
      });
    }

    uploading = false;

    if (mounted) {
      setState(() {});
    }
  }


  Future<void> updateReparation(Reparation reparation) async {
    await DatabaseGetter.database!
        .updateRow(
            databaseId: databaseId,
            tableId: reparationId,
            rowId: documentID!,
            data: reparation.toJson())
        .then((value) {})
        .onError((AppwriteException error, stackTrace) {
      setState(() {});
    });
  }

  Future<void> createReparation(Reparation reparation) async {
    await DatabaseGetter.database!.createRow(
        databaseId: databaseId,
        tableId: reparationId,
        rowId: documentID!,
        data: reparation.toJson());
  }

  Future<void> uploadActivity(bool update, Reparation reparation) async {
    if (update) {
      await DatabaseGetter().ajoutActivity(11, reparation.id,
          docName: pdf_theme.numberFormat.format(reparation.numero));
    } else {
      await DatabaseGetter().ajoutActivity(10, reparation.id,
          docName: pdf_theme.numberFormat.format(reparation.numero));
    }
  }

}
