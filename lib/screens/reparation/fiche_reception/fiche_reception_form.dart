import 'package:appwrite/appwrite.dart' hide Client;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/client_database.dart';
import '../../../providers/vehicle_provider.dart';
import '../../entreprise/entreprise.dart';
import '../../prestataire/prestataire_table.dart';
import 'entretien_widget.dart';
import 'vehicle_damage.dart';
import '../../vehicle/manager/vehicles_table.dart';
import '../../../serializables/client.dart';
import '../../../serializables/reparation/etat_vehicle.dart';
import '../../../theme.dart';
import '../../../widgets/big_title_form.dart';
import '../../../widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../pdf_generation/pdf_preview_custom.dart';
import '../../../pdf_generation/pdf_theming.dart' as pdf_theme;
import '../../../serializables/reparation/entretien_vehicle.dart';
import '../../../serializables/reparation/fiche_reception.dart';
import '../../../serializables/reparation/reparation.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../utilities/vehicle_util.dart';
import '../../../widgets/on_tap_scale.dart';
import '../reparation/reparation_order_form/entreprise_placement.dart';

class FicheReceptionForm extends StatefulWidget {
  final FicheReception? reparation;

  const FicheReceptionForm({required super.key, this.reparation});

  @override
  State<FicheReceptionForm> createState() => FicheReceptionFormState();
}

class FicheReceptionFormState extends State<FicheReceptionForm>
    with AutomaticKeepAliveClientMixin<FicheReceptionForm> {
  static Map<Key, int> reservedOrders = {};

  EntretienVehicle entretienVehicle = EntretienVehicle();
  EtatVehicle etatVehicle = EtatVehicle();

  TextEditingController numOrdre = TextEditingController();
  DateTime selectedDate = DateTime.now();

  Client? selectedPrest;
  Vehicle? selectedVehicle;
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
      etatVehicle = widget.reparation!.etatActuel ?? EtatVehicle();
      remarqueEntretien.text = widget.reparation!.remarque ?? '';
      numOrdre.text = widget.reparation!.numero.toString();
      reservedOrders[widget.key!] = widget.reparation!.numero;
      matricule.text = widget.reparation!.vehiculemat ?? '';
      couleur.text = widget.reparation!.couleur ?? '';
      type.text = widget.reparation!.modele ?? '';
      nchassi.text = widget.reparation!.nchassi ?? '';
      nmoteur.text = widget.reparation!.nmoteur ?? '';
      km.text = widget.reparation!.kilometrage?.toString() ?? '0';
      carburant = widget.reparation!.gaz?.toDouble() ?? 4;
      selectedDate = widget.reparation!.dateEntre;
      matriculeConducteur.text = widget.reparation!.matriculeConducteur ?? '';
      nom.text = widget.reparation!.nomConducteur ?? '';
      prenom.text = widget.reparation!.prenomConducteur ?? '';
      anneeUtil = DateTime(widget.reparation!.anneeUtil ??
          selectedVehicle?.anneeUtil ??
          DateTime.now().year);
      setState(() {
        assigningOrederNumber = false;
      });
    }
  }

  Future<void> getVehicle() async {
    if (widget.reparation != null && widget.reparation!.vehicule != null) {
      selectedVehicle =
      await VehicleProvider().getVehicle(widget.reparation!.vehicule!);
    }
  }


  Future<void> getImages() async{

    if (widget.reparation != null && widget.reparation!.images.isNotEmpty) {
      List<Future<Uint8List?>> tasks=[];
      for(int i=0;i<widget.reparation!.images.length;i++){
        if(widget.reparation!.images[i]!=null){
          tasks.add(downloadImage(widget.reparation!.images[i].toString()));

        }
      }
      images=await Future.wait(tasks);
    }

  }
  Future<Uint8List> downloadImage(String id) async {

    return await DatabaseGetter.storage!.getFileView(bucketId: 'images', fileId: "$documentID$id.jpg").onError((e,s){
      return Future.value(Uint8List.fromList([]));
    }).then((s){
      return s;
    });
  }


  bool assigningOrederNumber = false;

  bool errorNumOrder = false;
  bool changedPics=false;

  void assignOrderNumber() async {
    assigningOrederNumber = true;
    if (mounted) {
      setState(() {});
    }
    await DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: reparationId,
        queries: [
          Query.orderDesc('numero'),
          Query.limit(1),
        ]).then((value) {
      if (value.documents.length == 1) {
        numOrdre.text = (value.documents[0]
            .convertTo(
                (p0) => Reparation.fromJson(p0 as Map<String, dynamic>))
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
      result = await DatabaseGetter.database!.listDocuments(
          databaseId: databaseId,
          collectionId: reparationId,
          queries: [
            Query.orderDesc('numero'),
            Query.equal('numero', int.parse(numOrdre.text)),
            Query.limit(1),
          ]).then((value) {
        if (value.documents.length == 1) {
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
                        if (errorNumOrder)
                          Text(
                            'numprorder',
                            style: TextStyle(color: Colors.red),
                          ).tr(),
                        if (errorNumOrder) smallSpace,
                        Row(
                          children: [
                            Text(
                              'ORDRE DE REPARATION',
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
                buildTable(appTheme),
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
                  VehicleDamage(
                    etatVehicle: etatVehicle,
                    vehicleType:
                    VehiclesUtilities.getGenreNumber(matricule.text),
                  ),
                if (showEtat) smallSpace,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EntretienWidget(entretienVehicle: entretienVehicle),
                        bigSpace,
                        SizedBox(
                          height: 180.px,
                          width: 400.px,
                          child: ZoneBox(
                            label: 'remarqueplus'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextBox(
                                controller: remarqueEntretien,
                                placeholder: 'remarqueplus'.tr(),
                                maxLines: 4,
                                placeholderStyle: placeStyle,
                                style: appTheme.writingStyle,
                                cursorColor: appTheme.color.darker,
                                decoration: WidgetStatePropertyAll(
                                    BoxDecoration(color: appTheme.fillColor)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                smallSpace,
                const BigTitleForm(
                  bigTitle: 'travaileffect',
                  littleTitle: 'ajoutertaches',
                ),
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
                  child: images[0]==null ||images[0]!.isEmpty
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
                  child: images[1]==null ||images[1]!.isEmpty
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
                  child: images[2]==null ||images[2]!.isEmpty
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
                  child: images[3]==null ||images[3]!.isEmpty
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
      changedPics=true;
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
                          'KM',
                          style: littleStyle,
                        ).tr(),
                        const Spacer(),
                        SizedBox(
                          width: 160.px,
                          child: TextBox(
                            controller: km,
                            placeholder: 'KM'.tr(),
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
    reservedOrders.remove(widget.key);
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
        dateEntre: selectedDate,
        anneeUtil: anneeUtil.year,
        marque: marque.text,
        couleur: couleur.text,
        etatActuel: showEtat ? etatVehicle : null,
        gaz: carburant.ceil(),
        kilometrage: int.tryParse(km.text),
        modele: type.text,
        nchassi: nchassi.text,
        nmoteur: nmoteur.text,
        vehicule: selectedVehicle?.id,
        images: changedPics?[
          images[0]!=null?0:null,
          images[1]!=null?1:null,
          images[2]!=null?2:null,
          images[3]!=null?3:null,
        ]:widget.reparation!=null?widget.reparation!.images:[null,null,null,null],
        vehiculemat: selectedVehicle?.matricule,
        remarque: remarqueEntretien.text,
        matriculeConducteur: matriculeConducteur.text,
        nomConducteur: nom.text,
        prenomConducteur: prenom.text);

    showDialog(
        context: context,
        builder: (context) {
          return PdfPreviewPO(fiche: fiche);
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
        dateEntre: selectedDate,
        anneeUtil: anneeUtil.year,
        couleur: couleur.text,
        etatActuel: showEtat ? etatVehicle : null,
        gaz: carburant.ceil(),
        kilometrage: int.tryParse(km.text),
        modele: type.text,
        nchassi: nchassi.text,
        nmoteur: nmoteur.text,
        vehicule: selectedVehicle?.id,
        vehiculemat: selectedVehicle?.matricule,
        remarque: remarqueEntretien.text,
        matriculeConducteur: matriculeConducteur.text,
        nomConducteur: nom.text,
        images: changedPics?[
          images[0]!=null?0:null,
          images[1]!=null?1:null,
          images[2]!=null?2:null,
          images[3]!=null?3:null,
        ]:widget.reparation!=null?widget.reparation!.images:[null,null,null,null],
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
          [updateFiche(fiche), uploadActivity(modif, fiche),uploadImages()])
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

  Future<void> uploadImages() async{

    if(changedPics){
      List<Future>tasks=[];
      for(int i=0;i<images.length;i++){
        if(images[i]!=null && images[i]!.isNotEmpty){
          if(widget.reparation!=null && widget.reparation?.images[i]!=null){
            await DatabaseGetter.storage!.deleteFile(
                bucketId: buckedId, fileId: "$documentID$i.jpg").onError((s,d){
              tasks.add(
                  DatabaseGetter.storage!.createFile(
                      bucketId: buckedId,
                      fileId: "$documentID$i.jpg",
                      file: InputFile.fromBytes(bytes: images[i]!, filename: "$documentID$i.jpg")));
            }).then((s){
              tasks.add(
                  DatabaseGetter.storage!.createFile(
                      bucketId: buckedId,
                      fileId: "$documentID$i.jpg",
                      file: InputFile.fromBytes(bytes: images[i]!, filename: "$documentID$i.jpg")));
            });

          }
          else{
            tasks.add(
                DatabaseGetter.storage!.createFile(
                    bucketId: buckedId,
                    fileId: "$documentID$i.jpg",
                    file: InputFile.fromBytes(bytes: images[i]!, filename: "$documentID$i.jpg")));
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
