import 'dart:async';

import 'package:appwrite/appwrite.dart' hide Client;
import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../../../providers/client_database.dart';
import '../../../../providers/repair_provider.dart';
import '../../../../providers/vehicle_provider.dart';
import '../../../../serializables/reparation/fiche_reception.dart';
import '../../../entreprise/entreprise.dart';
import '../../../prestataire/prestataire_table.dart';
import '../../fiche_reception/manager/fiche_reception_table.dart';
import 'entretien_widget.dart';
import '../../../../serializables/client.dart';
import '../../../../serializables/reparation/etat_vehicle.dart';
import '../../../../theme.dart';
import '../../../../widgets/big_title_form.dart';
import '../../../../widgets/zone_box.dart';

import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../pdf_generation/pdf_preview_custom.dart';
import '../../../../pdf_generation/pdf_theming.dart' as pdf_theme;
import '../../../../serializables/reparation/designation.dart';
import '../../../../serializables/reparation/entretien_vehicle.dart';
import '../../../../serializables/reparation/reparation.dart';
import '../../../../serializables/vehicle/vehicle.dart';
import '../../../../utilities/vehicle_util.dart';
import '../../../../widgets/empty_table_widget.dart';
import 'designation_reparation.dart';
import 'entreprise_placement.dart';

Size _responsiveSelectionDialogSize(BuildContext context) {
  final screenSize = MediaQuery.sizeOf(context);
  return Size(
    (screenSize.width - 32).clamp(0.0, 700.0).toDouble(),
    (screenSize.height - 80).clamp(0.0, 550.0).toDouble(),
  );
}

class ReparationForm extends StatefulWidget {
  final Reparation? reparation;

  const ReparationForm({required super.key, this.reparation});

  @override
  State<ReparationForm> createState() => ReparationFormState();
}

class ReparationFormState extends State<ReparationForm>
    with AutomaticKeepAliveClientMixin<ReparationForm> {
  static Map<Key, int> reservedOrders = {};
  Timer? _orderNumberValidationTimer;
  int _orderNumberValidationRevision = 0;

  EntretienVehicle entretienVehicle = EntretienVehicle();
  EtatVehicle etatVehicle = EtatVehicle();
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

  bool showEtretient = true;

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
      entretienVehicle = widget.reparation!.entretien ?? EntretienVehicle();
      remarqueEntretien.text = widget.reparation!.remarque ?? '';
      numOrdre.text = widget.reparation!.numero.toString();
      reservedOrders[widget.key!] = widget.reparation!.numero;
      matricule.text = widget.reparation!.vehiculemat ?? '';
      nchassi.text = widget.reparation!.nchassi ?? '';
      selectedDate = widget.reparation!.date;
      designations = List.generate(
        widget.reparation!.designations?.length ?? 0,
        (index) {
          return DesignationReparation(
            key: UniqueKey(),
            designation: widget.reparation!.designations![index],
          );
        },
      );
      setState(() {
        assigningOrederNumber = false;
      });
    }
  }

  Future<void> getPrestatataire() async {
    if (widget.reparation != null && widget.reparation!.prestataire != null) {
      selectedPrest = await RepairProvider().getPrestataire(
        widget.reparation!.prestataire!,
      );
    }
  }

  Future<void> getVehicle({String? vehicleFromFiche}) async {
    if (vehicleFromFiche != null && selectedFicheReception != null) {
      selectedVehicle = await VehicleProvider().getVehicle(vehicleFromFiche);
    } else {
      if (widget.reparation != null && widget.reparation!.vehicule != null) {
        selectedVehicle = await VehicleProvider().getVehicle(
          widget.reparation!.vehicule!,
        );
      }
    }
  }

  Future<void> getFicheReception() async {
    if (widget.reparation != null &&
        widget.reparation!.ficheReception != null) {
      selectedFicheReception = await RepairProvider().getFiche(
        widget.reparation!.ficheReception!,
      );
    }
  }

  bool assigningOrederNumber = false;

  bool errorNumOrder = false;
  bool changedPics = false;

  void assignOrderNumber() async {
    assigningOrederNumber = true;
    if (mounted) {
      setState(() {});
    }
    await DatabaseGetter.database!
        .listRows(
          databaseId: databaseId,
          tableId: reparationId,
          queries: [Query.orderDesc('numero'), Query.limit(1)],
        )
        .then((value) {
          if (value.rows.length == 1) {
            numOrdre.text =
                (value.rows[0]
                            .convertTo((p0) => Reparation.fromJson(p0))
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

  Future<bool> _validateOrderNumberBeforeSave() async {
    if (widget.reparation != null) return int.tryParse(numOrdre.text.trim()) != null;

    final value = numOrdre.text.trim();
    final number = int.tryParse(value);
    if (number == null) {
      if (mounted && !errorNumOrder) {
        setState(() => errorNumOrder = true);
      }
      return false;
    }

    _orderNumberValidationTimer?.cancel();
    final revision = ++_orderNumberValidationRevision;
    var duplicated = testIfReservedContained(number);

    if (!duplicated) {
      try {
        final result = await DatabaseGetter.database!.listRows(
          databaseId: databaseId,
          tableId: reparationId,
          queries: [
            Query.orderDesc('numero'),
            Query.equal('numero', number),
            Query.limit(1),
          ],
        );
        duplicated = result.rows.isNotEmpty;
      } catch (error, stackTrace) {
        debugPrint(
          '[ParcOto Repair] save-time number validation failed: '
          '$error\\n$stackTrace',
        );
      }
    }

    if (!mounted ||
        revision != _orderNumberValidationRevision ||
        numOrdre.text.trim() != value) {
      return false;
    }

    if (!duplicated) {
      reservedOrders[widget.key!] = number;
    }
    if (errorNumOrder != duplicated) {
      setState(() => errorNumOrder = duplicated);
    }
    return !duplicated;
  }

  /// Debounces the uniqueness query. The input stays focused while the
  /// user types, and stale Appwrite responses cannot overwrite newer input.
  void _scheduleOrderNumberValidation(String text) {
    _orderNumberValidationTimer?.cancel();
    final revision = ++_orderNumberValidationRevision;
    final number = int.tryParse(text);

    if (number == null) {
      reservedOrders.remove(widget.key);
      if (errorNumOrder) {
        setState(() => errorNumOrder = false);
      }
      return;
    }

    _orderNumberValidationTimer = Timer(
      const Duration(milliseconds: 350),
      () async {
        if (testIfReservedContained(number)) {
          if (!mounted || revision != _orderNumberValidationRevision) return;
          if (!errorNumOrder) {
            setState(() => errorNumOrder = true);
          }
          return;
        }

        var duplicated = false;
        try {
          final result = await DatabaseGetter.database!.listRows(
            databaseId: databaseId,
            tableId: reparationId,
            queries: [
              Query.orderDesc('numero'),
              Query.equal('numero', number),
              Query.limit(1),
            ],
          );
          duplicated = result.rows.isNotEmpty;
        } catch (_) {
          // A temporary network failure must not block the form, matching
          // the previous behavior.
        }

        if (!mounted ||
            revision != _orderNumberValidationRevision ||
            numOrdre.text != text) {
          return;
        }

        if (!duplicated) {
          reservedOrders[widget.key!] = number;
        }
        if (errorNumOrder != duplicated) {
          setState(() => errorNumOrder = duplicated);
        }
      },
    );
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

  void getVehicleThenSetValues() async {
    setState(() {
      assigningOrederNumber = true;
    });
    await getVehicle(vehicleFromFiche: selectedFicheReception?.vehicule);
    if (selectedVehicle != null) {
      setVehicleValues();
    }
    setState(() {
      assigningOrederNumber = false;
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 760;
    return ScaffoldPage(
      content: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: appTheme.backGroundColor),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 20,
                  vertical: compact ? 8 : 12,
                ),
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    children: [
                      if (MyEntrepriseState.p != null)
                        const EntreprisePlacement(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (errorNumOrder)
                            Text(
                              'numprorder',
                              style: TextStyle(color: Colors.red),
                            ).tr(),
                          if (errorNumOrder) smallSpace,
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text(
                                'ordrereparation'.tr().toUpperCase(),
                                style: headerStyle,
                              ),
                              Container(
                                width: 200.px,
                                height: 40.px,
                                decoration: BoxDecoration(border: Border.all()),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Row(
                                    children: [
                                      Text('num', style: boldStyle).tr(),
                                      smallSpace,
                                      Flexible(
                                        child: ParcotoTextBox(
                                          controller: numOrdre,
                                          enabled: widget.reparation == null,
                                          placeholder: 'num'.tr(),
                                          placeholderStyle: placeStyle,
                                          style: appTheme.writingStyle,
                                          cursorColor: appTheme.color.darker,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          onChanged: _scheduleOrderNumberValidation,
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
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text('date', style: boldStyle).tr(),
                      smallSpace,
                      SizedBox(
                        width: 200.px,
                        height: 44.px,
                        child: ParcotoFieldSurface(
                          child: DatePicker(
                            selected: selectedDate,
                            onChanged: (s) {
                              setState(() {
                                selectedDate = s;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  smallSpace,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: compact ? screenWidth - 56 : (screenWidth - 80) * 0.58,
                        child: SizedBox(
                          height: 50.px,
                          child: ListTile(
                            leading: Text(
                              'fichereception',
                              style: boldStyle,
                            ).tr(),
                            title: Text(
                              selectedFicheReception != null
                                  ? NumberFormat(
                                      '00000000',
                                      'fr',
                                    ).format(selectedFicheReception?.numero)
                                  : 'nonind'.tr(),
                            ),
                            onPressed: () async {
                              selectedFicheReception =
                                  await showDialog<FicheReception>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return ContentDialog(
                                        constraints: BoxConstraints.tight(
                                          _responsiveSelectionDialogSize(context),
                                        ),
                                        title: const Text('selectedfiche').tr(),
                                        style: ContentDialogThemeData(
                                          titleStyle: appTheme.writingStyle
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        content: const FicheReceptionTable(
                                          selectD: true,
                                        ),
                                        actions: [
                                          Button(
                                            child: const Text('fermer').tr(),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                              getVehicleThenSetValues();
                            },
                          ),
                        ),
                      ),
                      if (selectedVehicle != null)
                        IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () {
                            selectedVehicle = null;
                            setVehicleValues();
                          },
                        ),
                      SizedBox(
                        width: compact ? screenWidth - 56 : (screenWidth - 80) * 0.38,
                        child: SizedBox(
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
                                      _responsiveSelectionDialogSize(context),
                                    ),
                                    title: const Text('selectprestataire').tr(),
                                    style: ContentDialogThemeData(
                                      titleStyle: appTheme.writingStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: const PrestataireTable(
                                      selectD: true,
                                    ),
                                    actions: [
                                      Button(
                                        child: const Text('fermer').tr(),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  smallSpace,
                  BigTitleForm(
                    bigTitle: 'entretienvehicule',
                    littleTitle: 'selectentretien',
                    trailing: Row(
                      children: [
                        const Text('afficherquestion').tr(),
                        smallSpace,
                        ToggleSwitch(
                          checked: showEtretient,
                          onChanged: (s) {
                            setState(() {
                              showEtretient = s;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (showEtretient)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compactMaintenance = constraints.maxWidth < 1100;
                        final notesWidth = compactMaintenance
                            ? constraints.maxWidth
                            : 400.0;
                        final checklistWidth = compactMaintenance
                            ? constraints.maxWidth
                            : constraints.maxWidth - notesWidth - 16;
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: appTheme.color.darker.withValues(alpha: .25),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              SizedBox(
                                width: checklistWidth,
                                child: EntretienWidget(
                                  entretienVehicle: entretienVehicle,
                                ),
                              ),
                              SizedBox(
                                width: notesWidth,
                                height: 180,
                                child: ZoneBox(
                                  label: 'remarqueplus'.tr(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ParcotoTextBox(
                                      controller: remarqueEntretien,
                                      placeholder: 'remarqueplus'.tr(),
                                      maxLines: 4,
                                      placeholderStyle: placeStyle,
                                      style: appTheme.writingStyle,
                                      cursorColor: appTheme.color.darker,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
              const Center(child: ProgressBar()),
          ],
        ),
      ),
      bottomBar: Container(
        decoration: BoxDecoration(color: appTheme.backGroundColor),
        padding: const EdgeInsets.all(10),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  appTheme.color.lightest,
                ),
              ),
              onPressed: uploading ? null : showPdf,
              child: const Text('voir'),
            ),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(appTheme.color.darkest),
              ),
              onPressed: uploading ? null : uploadForm,
              child: const Text('save').tr(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _orderNumberValidationTimer?.cancel();
    _orderNumberValidationRevision++;
    reservedOrders.remove(widget.key);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<DesignationReparation> designations = List.empty(growable: true);

  void addDesignation() {
    designations.add(
      DesignationReparation(
        key: UniqueKey(),
        designation: Designation(designation: ''),
      ),
    );
    setState(() {});
  }

  Widget designationTable(AppTheme appTheme) {
    return Container(
      decoration: BoxDecoration(border: Border.all()),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                  onPressed: selectedDesignationsExist()
                      ? deleteAllSelected
                      : null,
                  child: const Text('delete').tr(),
                ),
                smallSpace,
                FilledButton(
                  onPressed: addDesignation,
                  child: const Text('add').tr(),
                ),
              ],
            ),
          ),
          smallSpace,
          Container(
            decoration: BoxDecoration(
              color: appTheme.color.lightest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(5),
              ),
            ),
            padding: const EdgeInsets.all(5),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    TableCell(
                      child: const Text(
                        'desi',
                        textAlign: TextAlign.center,
                      ).tr(),
                    ),
                    TableCell(
                      child: const Text(
                        'qte',
                        textAlign: TextAlign.center,
                      ).tr(),
                    ),
                    TableCell(
                      child: const Text(
                        'TVA',
                        textAlign: TextAlign.center,
                      ).tr(),
                    ),
                    TableCell(
                      child: const Text(
                        'prix',
                        textAlign: TextAlign.center,
                      ).tr(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          designations.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(10),
                  width: 300.px,
                  height: 320.px,
                  child: const NoDataWidget(),
                )
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: appTheme.fillColor),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(5),
                    ),
                  ),
                  child: Column(children: getDesignationList(appTheme)),
                ),
        ],
      ),
    );
  }

  bool selectedDesignationsExist() {
    for (int i = 0; i < designations.length; i++) {
      if (designations[i].designation.selected) {
        return true;
      }
    }
    return false;
  }

  void deleteAllSelected() {
    List<DesignationReparation> temp = List.from(designations);
    for (int i = 0; i < temp.length; i++) {
      if (temp[i].designation.selected) {
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
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  checked: designations[index].designation.selected,
                  onChanged: (s) {
                    setState(() {
                      designations[index].designation.selected = s ?? false;
                    });
                  },
                ),
                smallSpace,
                Flexible(
                  child: SizedBox(height: 35.px, child: designations[index]),
                ),
              ],
            ),
            smallSpace,
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
      ficheReception: selectedFicheReception?.id ?? '',
      date: selectedDate,
      designations: designations.map((e) => e.designation).toList(),
      entretien: entretienVehicle,
      nchassi: nchassi.text,
      showEntretien: showEtretient,
      prestataire: selectedPrest?.id,
      prestatairenom: selectedPrest?.nom,
      vehicule: selectedVehicle?.id,
      vehiculemat: selectedVehicle?.matricule,
      remarque: remarqueEntretien.text,
      ficheReceptionNumber: selectedFicheReception?.numero ?? 0,
    );

    showDialog(
      context: context,
      builder: (context) {
        return PdfPreviewPO(reparation: reparation);
      },
    );
  }

  void uploadForm() async {
    if (!await _validateOrderNumberBeforeSave()) return;
    if (!mounted || uploading) return;

    if (selectedFicheReception == null) {
      displayInfoBar(
        context,
        builder: (BuildContext context, void Function() close) {
          return InfoBar(
            title: const Text('ficherequired').tr(),
            severity: InfoBarSeverity.error,
          );
        },
        duration: snackbarShortDuration,
      );
      return;
    }
    if (selectedVehicle == null) {
      displayInfoBar(
        context,
        builder: (BuildContext context, void Function() close) {
          return InfoBar(
            title: const Text('vehiclenotfound').tr(),
            severity: InfoBarSeverity.error,
          );
        },
        duration: snackbarShortDuration,
      );
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
      designations: designations.map((e) => e.designation).toList(),
      entretien: entretienVehicle,
      showEntretien: showEtretient,
      nchassi: nchassi.text,
      prestataire: selectedPrest?.id,
      prestatairenom: selectedPrest?.nom,
      vehicule: selectedVehicle?.id,
      vehiculemat: selectedVehicle?.matricule,
      remarque: remarqueEntretien.text,
      ficheReception: selectedFicheReception?.id ?? '',
      ficheReceptionNumber: selectedFicheReception?.numero ?? 0,
    );

    if (!modif) {
      await Future.wait([
            createReparation(reparation),
            uploadActivity(modif, reparation),
          ])
          .then((value) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('reparationajout').tr(),
                    severity: InfoBarSeverity.success,
                  );
                },
                duration: snackbarShortDuration,
              );
            }
          })
          .onError((error, stackTrace) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('echec').tr(),
                    severity: InfoBarSeverity.error,
                  );
                },
                duration: snackbarShortDuration,
              );
            }
          });
    } else {
      await Future.wait([
            updateReparation(reparation),
            uploadActivity(modif, reparation),
          ])
          .then((value) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('reparationmodif').tr(),
                    severity: InfoBarSeverity.success,
                  );
                },
                duration: snackbarShortDuration,
              );
            }
          })
          .onError((error, stackTrace) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (BuildContext context, void Function() close) {
                  return InfoBar(
                    title: const Text('echec').tr(),
                    severity: InfoBarSeverity.error,
                  );
                },
              );
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
          data: reparation.toJson(),
        )
        .then((value) {})
        .onError((AppwriteException error, stackTrace) {
          setState(() {});
        });
  }

  Future<void> createReparation(Reparation reparation) async {
    await DatabaseGetter().addDocument(
      collectionId: reparationId,
      documentId: documentID!,
      data: reparation.toJson(),
    );
  }

  Future<void> uploadActivity(bool update, Reparation reparation) async {
    if (update) {
      await DatabaseGetter().ajoutActivity(
        11,
        reparation.id,
        docName: pdf_theme.numberFormat.format(reparation.numero),
      );
    } else {
      await DatabaseGetter().ajoutActivity(
        10,
        reparation.id,
        docName: pdf_theme.numberFormat.format(reparation.numero),
      );
    }
  }
}
