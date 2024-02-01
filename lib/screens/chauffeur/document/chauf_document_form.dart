import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_table.dart';
import 'package:parc_oto/serializables/conducteur/conducteur.dart';
import 'package:parc_oto/serializables/conducteur/document_chauffeur.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';

class CDocumentForm extends StatefulWidget {
  final DocumentChauffeur? dc;
  final String? cid;
  final Conducteur? c;

  const CDocumentForm({super.key, this.dc, this.cid, this.c});

  @override
  CDocumentFormState createState() => CDocumentFormState();
}

class CDocumentFormState extends State<CDocumentForm>
    with AutomaticKeepAliveClientMixin<CDocumentForm> {
  DateTime? selectedDate;
  TextEditingController nom = TextEditingController();

  Conducteur? selectedConducteur;

  String? documentID;

  bool loadingConducteur = false;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    if (widget.dc != null) {
      nom.text = widget.dc!.nom;
      documentID = widget.dc!.id;
      selectedDate = widget.dc!.dateExpiration;
      if (widget.dc!.chauffeur != null) {
        downloadChauffeur(widget.dc!.chauffeur!);
      }
    } else if (widget.c != null) {
      selectedConducteur = widget.c;
    } else if (widget.cid != null) {
      downloadChauffeur(widget.cid!);
    }
    documentID ??=
        DateTime.now().difference(ClientDatabase.ref).inMilliseconds.toString();
  }

  void downloadChauffeur(String id) async {
    loadingConducteur = true;
    await ClientDatabase.database!
        .getDocument(
            databaseId: databaseId, collectionId: chauffeurid, documentId: id)
        .then((value) {
      if (value.data.isNotEmpty) {
        selectedConducteur = value
            .convertTo((p0) => Conducteur.fromJson(p0 as Map<String, dynamic>));
      }
    });
    if (mounted) {
      setState(() {
        loadingConducteur = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return SizedBox(
      width: 420.px,
      height: 500.px,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              decoration: BoxDecoration(
                  color: appTheme.backGroundColor,
                  boxShadow: kElevationToShadow[2],
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              width: 420.px,
              height: 300.px,
              child: Column(
                children: [
                  Flexible(
                    child: ZoneBox(
                      label: 'chauffeur'.tr(),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ListTile(
                          title: Text(
                              '${selectedConducteur?.name} ${selectedConducteur?.prenom}'),
                          onPressed: widget.c != null ||
                                  loadingConducteur ||
                                  widget.dc?.chauffeur != null ||
                                  widget.cid != null
                              ? null
                              : () async {
                                  selectedConducteur =
                                      await showDialog<Conducteur>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) {
                                            return ContentDialog(
                                              constraints: BoxConstraints.tight(
                                                  Size(60.w, 60.h)),
                                              title: const Text('selectchauffeur')
                                                  .tr(),
                                              style: ContentDialogThemeData(
                                                  titleStyle: appTheme
                                                      .writingStyle
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                              content: Container(
                                                  color: appTheme.backGroundColor,
                                                  width: 60.w,
                                                  height: 60.h,
                                                  child: const ChauffeurTable(
                                                    selectD: true,
                                                  )),
                                            );
                                          });
                                  setState(() {});
                                  checkForChanges();
                                },
                        ),
                      ),
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  Flexible(
                    child: ZoneBox(
                      label: 'nom'.tr(),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextBox(
                          controller: nom,
                          style: appTheme.writingStyle,
                          decoration: BoxDecoration(color: appTheme.fillColor),
                          cursorColor: appTheme.color.darker,
                          placeholderStyle: placeStyle,
                          placeholder: 'nom'.tr(),
                          onChanged: (s) {
                            checkForChanges();
                          },
                        ),
                      ),
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  Flexible(
                    child: ZoneBox(
                      label: 'dateexp'.tr(),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: DatePicker(
                          selected: selectedDate,
                          onChanged: (d) {
                            setState(() {
                              selectedDate = d;
                            });
                            checkForChanges();
                          },
                        ),
                      ),
                    ),
                  )
                ],
              )),
          bigSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                  onPressed: changes ? () => confirm(appTheme) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 5),
                    child: uploading
                        ? const ProgressRing()
                        : const Text(
                            'confirmer',
                          ).tr(),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  bool changes = false;
  bool uploading = false;

  void checkForChanges() {
    if (widget.dc != null) {
      if (nom.text.isNotEmpty && nom.text != widget.dc!.nom) {
        if (!changes) {
          setState(() {
            changes = true;
          });
        }
        return;
      }
      if ((widget.cid != null &&
              selectedConducteur != null &&
              widget.cid != selectedConducteur!.id) ||
          (widget.cid == null && selectedConducteur != null)) {
        if (!changes) {
          setState(() {
            changes = true;
          });
        }
        return;
      }
      if (selectedDate != null &&
          (widget.dc!.dateExpiration == null ||
              widget.dc!.dateExpiration == selectedDate)) {
        if (!changes) {
          setState(() {
            changes = true;
          });
        }
        return;
      }
    } else {
      if (nom.text.isNotEmpty) {
        if (!changes) {
          setState(() {
            changes = true;
          });
          return;
        }
      }
    }
  }

  void confirm(AppTheme appTheme) async {
    checkForChanges();
    if (changes) {
      setState(() {
        uploading = true;
      });

      DocumentChauffeur dv = DocumentChauffeur(
          id: documentID!,
          nom: nom.text,
          chauffeur: selectedConducteur?.id,
          chauffeurNom:
              '${selectedConducteur?.name} ${selectedConducteur?.prenom}',
          dateExpiration: selectedDate,
          createdBy: ClientDatabase.me.value?.id);
      if (widget.dc != null) {
        await ClientDatabase.database!.updateDocument(
            databaseId: databaseId,
            collectionId: chaufDoc,
            documentId: documentID!,
            data: dv.toJson());
        ClientDatabase()
            .ajoutActivity(24, documentID!, docName: dv.chauffeurNom);
      } else {
        await ClientDatabase.database!.createDocument(
            databaseId: databaseId,
            collectionId: chaufDoc,
            documentId: documentID!,
            data: dv.toJson());
        ClientDatabase()
            .ajoutActivity(23, documentID!, docName: dv.chauffeurNom);
      }

      setState(() {
        changes = false;
        uploading = false;
      });

      Future.delayed(Duration.zero).whenComplete(() {
        displayInfoBar(context,
            builder: (BuildContext context, void Function() close) {
          return InfoBar(
              title: const Text('done').tr(),
              severity: InfoBarSeverity.success,
              style: InfoBarThemeData(iconColor: (c) {
                switch (c) {
                  case InfoBarSeverity.success:
                    return appTheme.color.lightest;
                  case InfoBarSeverity.error:
                    return appTheme.color.darkest;
                  case InfoBarSeverity.info:
                    return appTheme.color;
                  default:
                    return appTheme.color;
                }
              }));
        }, duration: snackbarShortDuration);
        Future.delayed(snackbarShortDuration).whenComplete(() {
          if (widget.cid != null) {
            Navigator.pop(context);
          } else {}
        });
      });
    }
  }
}
