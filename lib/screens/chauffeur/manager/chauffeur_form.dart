import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicles_table.dart';
import 'package:parc_oto/serializables/conducteur/conducteur.dart';
import 'package:parc_oto/serializables/conducteur/disponibilite_chauffeur.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';
import '../../../utilities/form_validators.dart';
import '../../entreprise/entreprise.dart';
import '../../sidemenu/pane_items.dart';
import '../../sidemenu/sidemenu.dart';
import '../../vehicle/manager/vehicle_tabs.dart';


class ChauffeurForm extends StatefulWidget {
  final Conducteur? chauf;

  const ChauffeurForm({
    super.key,
    this.chauf,
  });

  @override
  State<ChauffeurForm> createState() => ChauffeurFormState();
}

class ChauffeurFormState extends State<ChauffeurForm> {
  bool uploading = false;
  double progress = 0;
  String? chaufID;

  int? etat;

  TextEditingController matricule = TextEditingController();
  TextEditingController nom = TextEditingController();
  TextEditingController prenom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController telephone = TextEditingController();
  TextEditingController adresse = TextEditingController();

  TextEditingController selectedAppartenance = TextEditingController();
  TextEditingController selectedDirection = TextEditingController();
  TextEditingController selectedDepartment = TextEditingController();
  TextEditingController profession = TextEditingController();
  DateTime? birthDay;
  bool service=false;
  @override
  void initState() {
    initValues();
    super.initState();
  }

  List<String> vehicules = [];

  void initValues() {
    if (widget.chauf != null) {
      matricule.text = widget.chauf!.matricule;
      chaufID = widget.chauf!.id;
      etat = widget.chauf!.etat;
      etatID = widget.chauf!.etatactuel;
      nom.text = widget.chauf!.name;
      prenom.text = widget.chauf!.prenom;
      email.text = widget.chauf!.email ?? '';
      telephone.text = widget.chauf!.telephone ?? '';
      adresse.text = widget.chauf!.adresse ?? '';
      birthDay = widget.chauf!.dateNaissance;
      vehicules.addAll(widget.chauf!.vehicules ?? []);
      selectedDirection.text =
          VehiclesUtilities.getDirection(widget.chauf!.direction);
      selectedAppartenance.text =
          VehiclesUtilities.getAppartenance(widget.chauf!.filliale);
      selectedDepartment.text=VehiclesUtilities.getDepartment(widget.chauf!.departement);
      profession.text=widget.chauf!.profession??'';
      service=widget.chauf!.service;
    }
  }

  bool? selected = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    if (uploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Sauvegarde en cours ...'),
            smallSpace,
            ProgressBar(
              value: progress,
            ),
          ],
        ),
      );
    }
    bool portrait = Device.orientation == Orientation.portrait;
    return Container(
      color: appTheme.backGroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              color: appTheme.backGroundColor,
              child: ListView(
                padding:
                    portrait ? null : EdgeInsets.symmetric(horizontal: 200.px),
                shrinkWrap: true,
                children: [
                  SizedBox(
                    height: 700.px,
                    width: 500.px,
                    child: Column(
                      children: [
                        Flexible(
                          flex: 2,
                          child: ZoneBox(
                            label: 'matricule'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextBox(
                                controller: matricule,
                                placeholder: 'matricule'.tr(),
                                style: appTheme.writingStyle,
                                placeholderStyle: placeStyle,
                                cursorColor: appTheme.color.darker,
                                decoration: BoxDecoration(
                                  color: appTheme.fillColor,
                                ),
                                onChanged: (s) {
                                  checkChanges();
                                },
                              ),
                            ),
                          ),
                        ),
                        smallSpace,
                        Flexible(
                          flex: 2,
                          child: ZoneBox(
                            label: 'fullname'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Flexible(
                                      child: TextBox(
                                    controller: nom,
                                    placeholder: 'Nom',
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    cursorColor: appTheme.color.darker,
                                    decoration: BoxDecoration(
                                      color: appTheme.fillColor,
                                    ),
                                    onChanged: (s) {
                                      checkChanges();
                                    },
                                  )),
                                  smallSpace,
                                  Flexible(
                                      child: TextBox(
                                    controller: prenom,
                                    placeholder: 'Prénom',
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    cursorColor: appTheme.color.darker,
                                    decoration: BoxDecoration(
                                      color: appTheme.fillColor,
                                    ),
                                    onChanged: (s) {
                                      checkChanges();
                                    },
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        smallSpace,
                        Flexible(
                          flex: 2,
                          child: ZoneBox(
                            label: 'poste'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  Flexible(
                                      child: TextBox(
                                        controller: profession,
                                        placeholder: 'poste'.tr(),
                                        style: appTheme.writingStyle,
                                        placeholderStyle: placeStyle,
                                        cursorColor: appTheme.color.darker,
                                        decoration: BoxDecoration(
                                          color: appTheme.fillColor,
                                        ),
                                        onChanged: (s) {
                                          checkChanges();
                                        },
                                      )),
                                  smallSpace,
                                  Flexible(
                                      child: Row(
                                        children: [
                                          const Text('fonction').tr(),
                                          smallSpace,
                                          ToggleSwitch(checked: service,
                                              onChanged: (s){
                                            setState(() {
                                              service=s;
                                            });
                                              }),
                                          smallSpace,
                                          const Text('service').tr(),
                                        ],
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        smallSpace,
                        Flexible(
                          flex: 2,
                          child: ZoneBox(
                              label: 'birthday'.tr(),
                              child: Container(
                                height: 5.h,
                                padding: const EdgeInsets.all(10),
                                child: DatePicker(
                                  selected: birthDay,
                                  onChanged: (d) {
                                    setState(() {
                                      birthDay = d;
                                    });
                                    checkChanges();
                                  },
                                ),
                              )),
                        ),
                        smallSpace,
                        Flexible(
                          flex: 4,
                          child: ZoneBox(
                            label: 'contact'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 250,
                                        child: TextBox(
                                          controller: email,
                                          placeholder: 'email'.tr(),
                                          style: appTheme.writingStyle,
                                          placeholderStyle: placeStyle,
                                          cursorColor: appTheme.color.darker,
                                          decoration: BoxDecoration(
                                            color: appTheme.fillColor,
                                          ),
                                          onChanged: (s) {
                                            checkChanges();
                                          },
                                        ),
                                      ),
                                      smallSpace,
                                      SizedBox(
                                          width: 187,
                                          child: TextBox(
                                            controller: telephone,
                                            placeholder: 'telephone'.tr(),
                                            style: appTheme.writingStyle,
                                            placeholderStyle: placeStyle,
                                            cursorColor: appTheme.color.darker,
                                            decoration: BoxDecoration(
                                              color: appTheme.fillColor,
                                            ),
                                            onChanged: (s) {
                                              checkChanges();
                                            },
                                          )),
                                    ],
                                  ),
                                  smallSpace,
                                  Flexible(
                                      child: TextBox(
                                    controller: adresse,
                                    placeholder: 'adresse'.tr(),
                                    maxLines: 3,
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    cursorColor: appTheme.color.darker,
                                    decoration: BoxDecoration(
                                      color: appTheme.fillColor,
                                    ),
                                    onChanged: (s) {
                                      checkChanges();
                                    },
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        smallSpace,
                        Flexible(
                          flex: 4,
                          child: ZoneBox(
                            label: 'affectation'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  Flexible(
                                    child: AutoSuggestBox<String>(
                                      placeholder: 'filiale'.tr(),
                                      placeholderStyle: placeStyle,
                                      controller: selectedAppartenance,
                                      items: List.generate(
                                          MyEntrepriseState.p!.filiales!.length,
                                          (index) => AutoSuggestBoxItem(
                                              value: MyEntrepriseState
                                                  .p!.filiales![index],
                                              label: MyEntrepriseState
                                                  .p!.filiales![index]
                                                  .toUpperCase())),
                                    ),
                                  ),
                                  smallSpace,
                                  Flexible(
                                    child: AutoSuggestBox<String>(
                                      placeholder: 'direction'.tr(),
                                      placeholderStyle: placeStyle,
                                      controller: selectedDirection,
                                      items: List.generate(
                                          MyEntrepriseState
                                              .p!.directions!.length,
                                          (index) => AutoSuggestBoxItem(
                                              value: MyEntrepriseState
                                                  .p!.directions![index],
                                              label: MyEntrepriseState
                                                  .p!.directions![index]
                                                  .toUpperCase())),
                                    ),
                                  ),
                                  smallSpace,
                                  Flexible(
                                    child: AutoSuggestBox<String>(
                                      placeholder: 'departement'.tr(),
                                      placeholderStyle: placeStyle,
                                      controller: selectedDepartment,
                                      items: List.generate(
                                          MyEntrepriseState.p!.departments!.length,
                                              (index) => AutoSuggestBoxItem(
                                              value: MyEntrepriseState
                                                  .p!.departments![index],
                                              label: MyEntrepriseState
                                                  .p!.departments![index]
                                                  .toUpperCase())),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        smallSpace,
                        Flexible(
                          flex: 2,
                          child: ZoneBox(
                            label: 'disponibilite'.tr(),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: DropDownButton(
                                title: Text(DriverProvider.getEtat(etat)).tr(),
                                placement: FlyoutPlacementMode.bottomCenter,
                                closeAfterClick: false,
                                items: [
                                  MenuFlyoutItem(
                                    text: const Text('disponible').tr(),
                                    onPressed: () {
                                      setState(() {
                                        etat = 0;
                                      });
                                    },
                                  ),
                                  const MenuFlyoutSeparator(),
                                  MenuFlyoutItem(
                                    text: const Text('mission').tr(),
                                    onPressed: () {
                                      etat = 1;
                                      setState(() {});
                                    },
                                  ),
                                  const MenuFlyoutSeparator(),
                                  MenuFlyoutItem(
                                    text: const Text('absent').tr(),
                                    onPressed: () {
                                      etat = 2;
                                      setState(() {});
                                    },
                                  ),
                                  if (ClientDatabase().isAdmin())
                                    const MenuFlyoutSeparator(),
                                  if (ClientDatabase().isAdmin())
                                    MenuFlyoutItem(
                                      text: const Text('quitteentre').tr(),
                                      onPressed: () {
                                        etat = 3;
                                        setState(() {});
                                      },
                                    ),
                                ],
                                onClose: () {
                                  checkChanges();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  smallSpace,
                  vehiclesWidget(appTheme),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: changes && !uploading ? upload : null,
                child: const Text('confirmer').tr(),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  double tilesHeight = 50.px;
  Widget vehiclesWidget(AppTheme appTheme) {
    return SizedBox(
      height:
          vehicules.isEmpty ? 100.px : vehicules.length * tilesHeight + 80.px,
      child: ZoneBox(
        label: 'vehicules'.tr(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 35.px,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                        onPressed: () async {
                          Vehicle? vehicle = await showDialog<Vehicle>(
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
                          if (vehicle != null &&
                              !vehicules.contains(vehicle.matricule)) {
                            vehicules.add(vehicle.matricule);
                            setState(() {});
                          }
                        },
                        child: const Text('add').tr())
                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: vehicules.isEmpty ? 1 : vehicules.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if (vehicules.isEmpty) {
                    return Center(
                        child: SizedBox(
                      height: 20.px,
                      child: Text('vehiculesempty',
                              style: TextStyle(
                                  color: Colors.grey[100],
                                  fontStyle: FontStyle.italic))
                          .tr(),
                    ));
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor: ButtonState.all<Color>(appTheme.fillColor),
                      title: Text(
                        vehicules[index],
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        children: [
                          Button(
                            child: const Text('voir').tr(),
                            onPressed: () {
                              String v=vehicules[index];
                              showMyVehicule(v);
                            },
                          ),
                          smallSpace,
                          IconButton(
                            icon: const Icon(
                              FluentIcons.cancel,
                              size: 15,
                            ),
                            onPressed: () {
                              setState(() {
                                vehicules.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void showMyVehicule(String? matricule) {
    if (matricule != null) {

      PanesListState.index.value = PaneItemsAndFooters.originalItems
              .indexOf(PaneItemsAndFooters.vehicles) +
          1;
      VehicleTabsState.currentIndex.value = 0;
      VehicleTableState.filterVehicule.value = '"$matricule"';

      VehicleTableState.filterNow = true;

    }
  }

  bool changes = false;

  void checkChanges() {
    if (widget.chauf != null) {
      if (matricule.text == widget.chauf!.matricule &&
          nom.text == widget.chauf!.name &&
          prenom.text == widget.chauf!.prenom &&
          birthDay == widget.chauf!.dateNaissance &&
          ((disp == null && etat == widget.chauf!.etat) ||
              (disp != null && disp!.type == etat)) &&
          adresse.text == widget.chauf!.adresse &&
          telephone.text == widget.chauf!.telephone && profession
          .text==widget.chauf!.profession && service==widget.chauf!.service &&
          selectedDepartment.text==VehiclesUtilities.getDepartment(widget
              .chauf!.departement) &&
          selectedAppartenance.text==VehiclesUtilities.getAppartenance(widget
              .chauf!.filliale) &&
          selectedDirection.text==VehiclesUtilities.getDirection(widget
              .chauf!.direction) &&
          email.text == widget.chauf!.email) {
        if (changes) {
          setState(() {
            changes = false;
          });
        }
      } else {
        if (!changes) {
          setState(() {
            changes = true;
          });
        }
      }
    } else {
      if (!changes) {
        setState(() {
          changes = true;
        });
      }
    }
  }

  void upload() async {
    if (matricule.value.text.isEmpty) {
      showMessage('matriculerequis', 'erreur');
      return;
    }
    if (nom.value.text.isEmpty || prenom.text.isEmpty) {
      showMessage('nomprenreq', 'erreur');
      return;
    }

    if (!uploading) {
      setState(() {
        uploading = true;
        progress = 0;
      });
      chaufID ??= DateTime.now()
          .difference(ClientDatabase.ref)
          .inMilliseconds
          .toString();
      etatID ??= DateTime.now()
          .difference(ClientDatabase.ref)
          .inMilliseconds
          .abs()
          .toString();
      try {
        await uploadEtat();
        setState(() {
          progress = 50;
        });
        await uploadChauffeur();

        setState(() {
          progress = 90;
          changes = false;
        });
        if (widget.chauf == null) {
          showMessage('chaufsuccess', "ok");
        } else {
          showMessage('chaufupdate', "ok");
        }
      } catch (e) {
        setState(() {
          uploading = false;
          showMessage('errupld', 'erreur');
        });
      }
      setState(() {
        uploading = false;
        progress = 100;
      });
    }
  }

  DisponibiliteChauffeur? disp;
  String? etatID;

  Future<void> uploadChauffeur() async {
    Conducteur chauf = Conducteur(
      id: chaufID!,
      matricule: matricule.text,
      name: nom.value.text,
      prenom: prenom.value.text,
      email: FormValidators.isEmail(email.value.text)?email.value.text:null,
      telephone: telephone.value.text,
      filliale: selectedAppartenance.text.replaceAll(' ', '').trim(),
      direction: selectedDirection.text.replaceAll(' ', '').trim(),
      departement: selectedDepartment.text.replaceAll('', '').tr(),
      profession: profession.text,
      service: service,
      adresse: adresse.value.text,
      dateNaissance: birthDay,
      etat: etat,
      etatactuel: etatID,
    );
    if (widget.chauf != null) {
      await ClientDatabase.database!
          .updateDocument(
              databaseId: databaseId,
              collectionId: chauffeurid,
              documentId: chaufID!,
              data: chauf.toJson())
          .then((value) {
        ClientDatabase().ajoutActivity(17, chaufID!,
            docName: '${chauf.name} ${chauf.prenom}');
      }).onError((AppwriteException error, stackTrace) {
      });
    } else {
      await ClientDatabase.database!
          .createDocument(
              databaseId: databaseId,
              collectionId: chauffeurid,
              documentId: chaufID!,
              data: chauf.toJson())
          .then((value) {
        ClientDatabase().ajoutActivity(16, chaufID!,
            docName: '${chauf.name} ${chauf.prenom}');

      }).onError((AppwriteException error, stackTrace) {
      });
    }
  }

  Future<Document?> uploadEtat() async {
    if (disp == null || disp!.type != etat) {
      if (disp?.id == etatID ||
          etatID == null ||
          etatID == widget.chauf?.etatactuel) {
        etatID = DateTime.now()
            .difference(ClientDatabase.ref)
            .inMilliseconds
            .abs()
            .toString();
      }
      disp = DisponibiliteChauffeur(
          id: etatID!,
          type: etat ?? 0,
          createdBy: ClientDatabase.me.value?.id,
          chauffeur: chaufID!,
          chauffeurNom: '${nom.text} ${prenom.text}');
      return await ClientDatabase.database!
          .createDocument(
              databaseId: databaseId,
              collectionId: chaufDispID,
              documentId: etatID!,
              data: disp!.toJson())
          .then((value) {
        ClientDatabase()
            .ajoutActivity(20, etatID!, docName: disp?.chauffeurNom);
        return value;
      });
    } else {
      return null;
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
}
