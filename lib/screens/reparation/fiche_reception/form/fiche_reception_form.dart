import 'package:appwrite/appwrite.dart' hide Client;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/serializables/reparation/etat_vehicle_gts.dart';
import '../../../../admin_parameters.dart';
import '../../../../providers/client_database.dart';
import '../../../../providers/vehicle_provider.dart';
import '../../../entreprise/entreprise.dart';
import '../../reparation/manager/reparation_table.dart';
import '../../reparation/reparation_order_form/entretien_widget.dart';
import '../../../vehicle/manager/vehicles_table.dart';
import '../../../../serializables/reparation/etat_vehicle.dart';
import '../../../../theme.dart';
import '../../../../widgets/big_title_form.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../pdf_generation/pdf_preview_custom.dart';
import '../../../../pdf_generation/pdf_theming.dart' as pdf_theme;
import '../../../../serializables/reparation/entretien_vehicle.dart';
import '../../../../serializables/reparation/fiche_reception.dart';
import '../../../../serializables/reparation/reparation.dart';
import '../../../../serializables/vehicle/vehicle.dart';
import '../../../../utilities/vehicle_util.dart';
import '../../../../widgets/on_tap_scale.dart';
import '../../reparation/reparation_order_form/entreprise_placement.dart';
import 'vehicle_damage.dart';
import 'vehicle_damage_gts.dart';

class FicheReceptionForm extends StatefulWidget {
  final FicheReception? fiche;

  const FicheReceptionForm({required super.key, this.fiche});

  @override
  State<FicheReceptionForm> createState() => FicheReceptionFormState();
}

class FicheReceptionFormState extends State<FicheReceptionForm>
    with AutomaticKeepAliveClientMixin<FicheReceptionForm> {
  static Map<Key, int> reservedFiches = {};

  EntretienVehicle entretienVehicle = EntretienVehicle();
  EtatVehicleInterface etatVehicle = gts?EtatVehicleGTS():EtatVehicle();

  TextEditingController numOrdre = TextEditingController();
  DateTime dateEntre = DateTime.now();
  DateTime? dateSortie;

  Vehicle? selectedVehicle;
  Reparation? selectedReparation;
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

  bool showEtat = true;
  bool showEtretient = true;
  bool showImages = true;

  @override
  void initState() {
    if (widget.fiche != null) {
      initValues();
    } else {
      assignFicheNumber();
    }
    super.initState();
  }

  void initValues() async {
    if (widget.fiche != null) {
      documentID = widget.fiche!.id;
      assigningFicheNumber = true;
      await Future.wait([getVehicle(), getReparation(), getImages()]);

      if (mounted) {
        setState(() {});
      }
      etatVehicle = widget.fiche!.etatActuel ?? EtatVehicle();
      entretienVehicle = widget.fiche!.entretien ?? EntretienVehicle();
      remarqueEntretien.text = widget.fiche!.remarque ?? '';
      numOrdre.text = widget.fiche!.numero.toString();
      reservedFiches[widget.key!] = widget.fiche!.numero;
      matricule.text = widget.fiche!.vehiculemat ?? '';
      couleur.text = widget.fiche!.couleur ?? '';
      type.text = widget.fiche!.modele ?? '';
      nchassi.text = widget.fiche!.nchassi ?? '';
      nmoteur.text = widget.fiche!.nmoteur ?? '';
      km.text = widget.fiche!.kilometrage?.toString() ?? '0';
      carburant = widget.fiche!.gaz?.toDouble() ?? 4;
      dateEntre = widget.fiche!.dateEntre;
      matriculeConducteur.text = widget.fiche!.matriculeConducteur ?? '';
      nom.text = widget.fiche!.nomConducteur ?? '';
      prenom.text = widget.fiche!.prenomConducteur ?? '';
      anneeUtil = DateTime(widget.fiche!.anneeUtil ??
          selectedVehicle?.anneeUtil ??
          DateTime.now().year);
      setState(() {
        assigningFicheNumber = false;
      });
    }
  }

  Future<void> getVehicle() async {
    if (widget.fiche != null && widget.fiche!.vehicule != null) {
      selectedVehicle =
          await VehicleProvider().getVehicle(widget.fiche!.vehicule!);
    }
  }

  Future<void> getReparation() async {
    if (widget.fiche != null && widget.fiche!.reparation != null) {
      selectedReparation =
          await RepairProvider().getReparation(widget.fiche!.reparation!);
    }
  }

  Future<void> getImages() async {
    if (widget.fiche != null && widget.fiche!.images.isNotEmpty) {
      List<Future<Uint8List?>> tasks = [];
      for (int i = 0; i < widget.fiche!.images.length; i++) {
        if (widget.fiche!.images[i] != null) {
          tasks.add(downloadImage(widget.fiche!.images[i].toString()));
        }
      }
      images = await Future.wait(tasks);
    }
  }

  Future<Uint8List> downloadImage(String id) async {
    return await DatabaseGetter.storage!
        .getFileView(bucketId: 'images', fileId: "$documentID$id.jpg")
        .onError((e, s) {
      return Future.value(Uint8List.fromList([]));
    }).then((s) {
      return s;
    });
  }

  bool assigningFicheNumber = false;

  bool errorNumFiche = false;
  bool changedPics = false;

  void assignFicheNumber() async {
    assigningFicheNumber = true;
    if (mounted) {
      setState(() {});
    }
    await DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: fichesreceptionId,
        queries: [
          Query.orderDesc('numero'),
          Query.limit(1),
        ]).then((value) {
      if (value.documents.length == 1) {
        numOrdre.text = (value.documents[0]
                    .convertTo((p0) =>
                        FicheReception.fromJson(p0 as Map<String, dynamic>))
                    .numero +
                1)
            .toString();
      } else {
        numOrdre.text = (reservedFiches.length + 1).toString();
      }

      while (testIfReservedContainedFiches(int.parse(numOrdre.text))) {
        numOrdre.text = (int.parse(numOrdre.text) + 1).toString();
      }
      reservedFiches[widget.key!] = (int.parse(numOrdre.text));
    });

    assigningFicheNumber = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> testIfFichesNumberExists() async {
    bool result = false;

    if (testIfReservedContainedFiches(int.parse(numOrdre.text))) {
      setState(() {
        errorNumFiche = true;
      });
      result = true;
    } else {
      result = await DatabaseGetter.database!.listDocuments(
          databaseId: databaseId,
          collectionId: fichesreceptionId,
          queries: [
            Query.orderDesc('numero'),
            Query.equal('numero', int.parse(numOrdre.text)),
            Query.limit(1),
          ]).then((value) {
        if (value.documents.length == 1) {
          setState(() {
            errorNumFiche = true;
          });
          return true;
        } else {
          setState(() {
            errorNumFiche = false;
          });
          return false;
        }
      }).onError((error, stackTrace) {
        return Future.value(false);
      });
    }

    return result;
  }

  bool testIfReservedContainedFiches(int value) {
    bool result = false;
    reservedFiches.forEach((key, v) {
      if (value == v && key != widget.key) {
        result = true;
        return;
      }
    });

    return result;
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
    bool portrait = MediaQuery.of(context).orientation == Orientation.portrait;
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
                        if (errorNumFiche)
                          Text(
                            'numprorder',
                            style: TextStyle(color: Colors.red),
                          ).tr(),
                        if (errorNumFiche) smallSpace,
                        Row(
                          children: [
                            Text(
                              'fichereception'.tr().toUpperCase(),
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
                                        enabled: widget.fiche == null,
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
                                            if (!await testIfFichesNumberExists()) {
                                              reservedFiches[widget.key!] =
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
                      'dateentre',
                      style: boldStyle,
                    ).tr(),
                    smallSpace,
                    SizedBox(
                      width: 200.px,
                      height: 30.px,
                      child: DatePicker(
                        selected: dateEntre,
                        onChanged: (s) {
                          setState(() {
                            dateEntre = s;
                          });
                        },
                      ),
                    ),
                    bigSpace,
                    Text(
                      'datesortie',
                      style: boldStyle,
                    ).tr(),
                    smallSpace,
                    SizedBox(
                      width: 200.px,
                      height: 30.px,
                      child: DatePicker(
                        selected: dateSortie,
                        startDate: dateEntre,
                        onChanged: (s) {
                          setState(() {
                            dateSortie = s;
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
                      width: 250.px,
                      height: 50.px,
                      child: ListTile(
                        leading: Text(
                          'vehicule',
                          style: boldStyle,
                        ).tr(),
                        title:
                            Text(selectedVehicle?.matricule ?? 'nonind'.tr()),
                        onPressed: () async {
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
                                              fontWeight: FontWeight.bold)),
                                  content: const VehicleTable(
                                    selectV: true,
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
                          setVehicleValues();
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
                          'reparation',
                          style: boldStyle,
                        ).tr(),
                        title:
                        Text(selectedReparation?.numero==null?'nonind'.tr():NumberFormat("000000").format(selectedReparation!.numero)),
                        onPressed: () async {
                          selectedReparation = await showDialog<Reparation>(
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
                                          fontWeight: FontWeight.bold)),
                                  content: const ReparationTable(
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
                        },
                      ),
                    ),
                    smallSpace,
                    if (selectedReparation != null)
                      IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () {
                            selectedReparation = null;
                            setVehicleValues();
                          }),
                  ],
                ),
                buildTable(appTheme),
                smallSpace,
                Container(
                  height: 100.px,
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'descriptiondegats',
                        style: littleStyle,
                      ).tr(),
                      smallSpace,
                      Flexible(
                        child: TextBox(
                          controller: remarqueEntretien,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          placeholder: 'descriptiondegats'.tr(),
                          placeholderStyle: placeStyle.copyWith(),
                          textAlignVertical: TextAlignVertical.top,
                          suffix: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text('charactersremaining',style:placeStyle).tr(namedArgs: {
                              'nbr':(100-remarqueEntretien.text.length).toString()
                            }),
                          ),
                          maxLines: 4,
                          maxLength: 100,
                          onChanged: (s){
                            setState(() {

                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                smallSpace,
                BigTitleForm(
                  bigTitle: 'imagesdegats',
                  littleTitle: 'uploaddimages',
                  trailing: Row(
                    children: [
                      const Text('afficherquestion').tr(),
                      smallSpace,
                      ToggleSwitch(
                          checked: showImages,
                          onChanged: (s) {
                            setState(() {
                              showImages = s;
                            });
                          }),
                    ],
                  ),
                ),
                if (showImages) imagesContainer(portrait),
                smallSpace,
                BigTitleForm(
                  bigTitle: 'etatvehicule',
                  littleTitle: 'selectetat',
                  trailing: Row(
                    children: [
                      const Text('afficherquestion').tr(),
                      smallSpace,
                      ToggleSwitch(
                          checked: showEtat,
                          onChanged: (s) {
                            setState(() {
                              showEtat = s;
                            });
                          }),
                    ],
                  ),
                ),
                if (showEtat)
                  gts?VehicleDamageGts(
                    etatVehicle: etatVehicle as EtatVehicleGTS,
                    vehicleType:
                        VehiclesUtilities.getGenreNumber(matricule.text),
                  ):VehicleDamage(
                    etatVehicle: etatVehicle as EtatVehicle,
                    vehicleType:
                    VehiclesUtilities.getGenreNumber(matricule.text),
                  ),
                if (showEtat) smallSpace,
                BigTitleForm(
                  bigTitle: 'entretienvehicule',
                  littleTitle: 'selectentretienprec',
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
                          }),
                    ],
                  ),
                ),
                if (showEtretient)
                  Container(
                    height: 260.px,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: EntretienWidget(entretienVehicle: entretienVehicle),
                  ),
              ],
            ),
          ),
          if (assigningFicheNumber)
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

  List<Uint8List?> images = [
    Uint8List.fromList([]),
    Uint8List.fromList([]),
    Uint8List.fromList([]),
    Uint8List.fromList([]),
  ];

  Widget imagesContainer(bool portrait) {
    return StaggeredGrid.count(
        crossAxisCount: portrait ? 1 : 2,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        children: [
          StaggeredGridTile.fit(
              crossAxisCellCount: 1,
              child: OnTapScaleAndFade(
                onTap: () {
                  pickImage(0);
                },
                child: Container(
                  height: 200.px,
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: images[0] == null || images[0]!.isEmpty
                      ? Icon(FluentIcons.add)
                      : Image.memory(
                          images[0]!,
                          fit: BoxFit.fitHeight,
                        ),
                ),
              )),
          StaggeredGridTile.fit(
              crossAxisCellCount: 1,
              child: OnTapScaleAndFade(
                onTap: () {
                  pickImage(1);
                },
                child: Container(
                  height: 200.px,
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: images[1] == null || images[1]!.isEmpty
                      ? Icon(FluentIcons.add)
                      : Image.memory(
                          images[1]!,
                          fit: BoxFit.fitHeight,
                        ),
                ),
              )),
          StaggeredGridTile.fit(
              crossAxisCellCount: 1,
              child: OnTapScaleAndFade(
                onTap: () {
                  pickImage(2);
                },
                child: Container(
                  height: 200.px,
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: images[2] == null || images[2]!.isEmpty
                      ? Icon(FluentIcons.add)
                      : Image.memory(
                          images[2]!,
                          fit: BoxFit.fitHeight,
                        ),
                ),
              )),
          StaggeredGridTile.fit(
              crossAxisCellCount: 1,
              child: OnTapScaleAndFade(
                onTap: () {
                  pickImage(3);
                },
                child: Container(
                  height: 200.px,
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: images[3] == null || images[3]!.isEmpty
                      ? Icon(FluentIcons.add)
                      : Image.memory(
                          images[3]!,
                          fit: BoxFit.fitHeight,
                        ),
                ),
              )),
        ]);
  }

  void pickImage(int index) async {
    ImagePicker picker = ImagePicker();
    XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      images[index] = await image.readAsBytes();
      changedPics = true;
      setState(() {});
    }
  }

  Table buildTable(AppTheme appTheme) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      border: TableBorder.all(),
      columnWidths: {
        0: FixedColumnWidth(80.px),
        1: FixedColumnWidth(80.px),
        2: FixedColumnWidth(80.px),
        3: FixedColumnWidth(80.px),
      },
      children: [
        TableRow(children: [
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'marque',
                  style: littleStyle,
                ).tr(),
                const Spacer(),
                SizedBox(
                  width: 160.px,
                  child: TextBox(
                    controller: marque,
                    placeholder: 'marque'.tr(),
                    style: appTheme.writingStyle,
                    decoration: WidgetStatePropertyAll(
                        BoxDecoration(color: appTheme.fillColor)),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'type',
                  style: littleStyle,
                ).tr(),
                const Spacer(),
                SizedBox(
                  width: 160.px,
                  child: TextBox(
                    controller: type,
                    placeholder: 'type'.tr(),
                    style: appTheme.writingStyle,
                    decoration: WidgetStatePropertyAll(
                        BoxDecoration(color: appTheme.fillColor)),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'nchassi',
                  style: littleStyle,
                ).tr(),
                smallSpace,
                Flexible(
                  child: TextBox(
                    controller: nchassi,
                    placeholder: 'nchassi'.tr(),
                    style: appTheme.writingStyle,
                    decoration: WidgetStatePropertyAll(
                        BoxDecoration(color: appTheme.fillColor)),
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Text(
                  'matricule',
                  style: littleStyle,
                ).tr(),
                smallSpace,
                Flexible(
                  child: TextBox(
                    controller: matricule,
                    enabled: selectedVehicle == null,
                    //readOnly: selectedVehicle!=null,
                    placeholder: 'matricule'.tr(),
                    style: appTheme.writingStyle,
                    decoration: WidgetStatePropertyAll(
                        BoxDecoration(color: appTheme.fillColor)),

                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                  ),
                ),
              ],
            ),
          )),
        ]),
        TableRow(children: [
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'nmoteur',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: nmoteur,
                            placeholder: 'nmoteur'.tr(),
                            style: appTheme.writingStyle,
                            decoration: WidgetStatePropertyAll(
                                BoxDecoration(color: appTheme.fillColor)),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.px,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'kilometrage',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: km,
                            placeholder: 'KM',
                            style: appTheme.writingStyle,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: WidgetStatePropertyAll(
                                BoxDecoration(color: appTheme.fillColor)),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
          TableCell(
              child: Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
                height: 120.px,
                width: 180.px,
                child: SfRadialGauge(
                  animationDuration: 500,
                  title: GaugeTitle(
                    text: 'carburant'.tr(),
                    textStyle: littleStyle,
                    alignment: GaugeAlignment.near,
                  ),
                  axes: [
                    RadialAxis(
                      canScaleToFit: true,
                      minimum: 0,
                      maximum: 8,
                      radiusFactor: 1,
                      onAxisTapped: (s) {
                        setState(() {
                          carburant = s;
                        });
                      },
                      ranges: [
                        GaugeRange(
                          startValue: 0,
                          endValue: 0.5,
                          label: 'E',
                          color: appTheme.color.darkest,
                        ),
                        GaugeRange(
                          startValue: 7.5,
                          endValue: 8,
                          label: 'F',
                          color: appTheme.color.lightest,
                        ),
                      ],
                      annotations: [
                        GaugeAnnotation(
                          widget: Text(
                            '4/8',
                            style: littleStyle,
                          ),
                          axisValue: 4,
                          positionFactor: 0.7,
                        ),
                      ],
                      pointers: [
                        NeedlePointer(
                          animationDuration: 500,
                          needleLength: 0.4,
                          needleColor: appTheme.color,
                          needleStartWidth: 1.px,
                          needleEndWidth: 5.px,
                          knobStyle: KnobStyle(color: appTheme.color.darkest),
                          value: carburant,
                          enableAnimation: true,
                          enableDragging: true,
                        ),
                      ],
                      interval: 2,
                      startAngle: 180,
                      showFirstLabel: false,
                      showLastLabel: false,
                      showLabels: false,
                      endAngle: 360,
                    )
                  ],
                )),
          )),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'color',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: couleur,
                            placeholder: 'color'.tr(),
                            style: appTheme.writingStyle,
                            decoration: WidgetStatePropertyAll(
                                BoxDecoration(color: appTheme.fillColor)),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.px,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'anneeutil',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                            width: 80.px,
                            child: DatePicker(
                              selected: anneeUtil,
                              showDay: false,
                              showMonth: false,
                            ))
                      ],
                    ),
                  ),
                ],
              )),
          TableCell(
              verticalAlignment: TableCellVerticalAlignment.top,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'matriculeemploye',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: matriculeConducteur,
                            placeholder: 'matriculeemploye'.tr(),
                            style: appTheme.writingStyle,
                            decoration: WidgetStatePropertyAll(
                                BoxDecoration(color: appTheme.fillColor)),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.px,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'nom',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: nom,
                            placeholder: 'nom'.tr(),
                            style: appTheme.writingStyle,
                            decoration: WidgetStatePropertyAll(
                                BoxDecoration(color: appTheme.fillColor)),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1.px,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        Text(
                          'prenom',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: prenom,
                            placeholder: 'prenom'.tr(),
                            style: appTheme.writingStyle,
                            decoration: WidgetStatePropertyAll(
                                BoxDecoration(color: appTheme.fillColor)),
                            cursorColor: appTheme.color.darker,
                            placeholderStyle: placeStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
        ]),
      ],
    );
  }

  @override
  void dispose() {
    reservedFiches.remove(widget.key);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  String? documentID;

  bool uploading = false;

  void showPdf() {
    FicheReception fiche = FicheReception(
        id: '',
        numero: int.parse(numOrdre.text),
        dateEntre: dateEntre,
        anneeUtil: anneeUtil.year,
        marque: marque.text,
        couleur: couleur.text,
        etatActuel: etatVehicle,
        showEtat: showEtat,
        showEntretien: showEtretient,
        showImages: showImages,
        entretien: entretienVehicle,
        gaz: carburant.ceil(),
        kilometrage: int.tryParse(km.text),
        modele: type.text,
        nchassi: nchassi.text,
        nmoteur: nmoteur.text,
        vehicule: selectedVehicle?.id,
        images: changedPics
            ? [
                images[0] != null ? 0 : null,
                images[1] != null ? 1 : null,
                images[2] != null ? 2 : null,
                images[3] != null ? 3 : null,
              ]
            : widget.fiche != null
                ? widget.fiche!.images
                : [null, null, null, null],
        vehiculemat: selectedVehicle?.matricule,
        remarque: remarqueEntretien.text,
        matriculeConducteur: matriculeConducteur.text,
        nomConducteur: nom.text,
        prenomConducteur: prenom.text);

    showDialog(
        context: context,
        builder: (context) {
          return PdfPreviewPO(fiche: fiche,images: images,);
        });
  }

  void uploadForm() async {
    setState(() {
      uploading = true;
    });
    bool modif = documentID != null;
    documentID ??= DateTime.now()
        .difference(DatabaseGetter.ref)
        .inMilliseconds
        .abs()
        .toString();
    FicheReception fiche = FicheReception(
        id: documentID!,
        marque: marque.text,
        numero: int.parse(numOrdre.text),
        dateEntre: dateEntre,
        anneeUtil: anneeUtil.year,
        couleur: couleur.text,
        etatActuel: etatVehicle,
        entretien: entretienVehicle,
        gaz: carburant.ceil(),
        kilometrage: int.tryParse(km.text),
        modele: type.text,
        nchassi: nchassi.text,
        nmoteur: nmoteur.text,
        showImages: showImages,
        showEntretien: showEtretient,
        showEtat: showEtat,
        vehicule: selectedVehicle?.id,
        vehiculemat: selectedVehicle?.matricule,
        remarque: remarqueEntretien.text,
        matriculeConducteur: matriculeConducteur.text,
        nomConducteur: nom.text,
        images: changedPics
            ? [
                images[0] != null ? 0 : null,
                images[1] != null ? 1 : null,
                images[2] != null ? 2 : null,
                images[3] != null ? 3 : null,
              ]
            : widget.fiche != null
                ? widget.fiche!.images
                : [null, null, null, null],
        prenomConducteur: prenom.text);

    if (!modif) {
      await Future.wait([
        createFiche(fiche),
        uploadActivity(modif, fiche),
        uploadImages(),
      ]).then((value) {
        if (mounted) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('receptionajout').tr(),
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
      await Future.wait([
        updateFiche(fiche),
        uploadActivity(modif, fiche),
        uploadImages()
      ]).then((value) {
        if (mounted) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('receptionmodif').tr(),
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

  Future<void> uploadImages() async {
    if (changedPics) {
      List<Future> tasks = [];
      for (int i = 0; i < images.length; i++) {
        if (images[i] != null && images[i]!.isNotEmpty) {
          if (widget.fiche != null && widget.fiche?.images[i] != null) {
            await DatabaseGetter.storage!
                .deleteFile(bucketId: buckedId, fileId: "$documentID$i.jpg")
                .onError((s, d) {
              tasks.add(DatabaseGetter.storage!.createFile(
                  bucketId: buckedId,
                  fileId: "$documentID$i.jpg",
                  file: InputFile.fromBytes(
                      bytes: images[i]!, filename: "$documentID$i.jpg")));
            }).then((s) {
              tasks.add(DatabaseGetter.storage!.createFile(
                  bucketId: buckedId,
                  fileId: "$documentID$i.jpg",
                  file: InputFile.fromBytes(
                      bytes: images[i]!, filename: "$documentID$i.jpg")));
            });
          } else {
            tasks.add(DatabaseGetter.storage!.createFile(
                bucketId: buckedId,
                fileId: "$documentID$i.jpg",
                file: InputFile.fromBytes(
                    bytes: images[i]!, filename: "$documentID$i.jpg")));
          }
        }
      }
      await Future.wait(tasks);
    }
  }

  Future<void> updateFiche(FicheReception fiche) async {
    await DatabaseGetter.database!
        .updateDocument(
            databaseId: databaseId,
            collectionId: fichesreceptionId,
            documentId: documentID!,
            data: fiche.toJson())
        .then((value) {})
        .onError((AppwriteException error, stackTrace) {
      setState(() {});
    });
  }

  Future<void> createFiche(FicheReception fiche) async {
    await DatabaseGetter.database!.createDocument(
        databaseId: databaseId,
        collectionId: fichesreceptionId,
        documentId: documentID!,
        data: fiche.toJson());
  }

  Future<void> uploadActivity(bool update, FicheReception fiche) async {
    if (update) {
      await DatabaseGetter().ajoutActivity(67, fiche.id,
          docName: pdf_theme.numberFormat.format(fiche.numero));
    } else {
      await DatabaseGetter().ajoutActivity(66, fiche.id,
          docName: pdf_theme.numberFormat.format(fiche.numero));
    }
  }
}
