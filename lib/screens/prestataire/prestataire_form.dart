import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';

import '../../serializables/client.dart';
import '../../theme.dart';
import '../../utilities/form_validators.dart';
import '../../widgets/zone_box.dart';

class PrestataireForm extends StatefulWidget {
  final Client? prest;

  const PrestataireForm({super.key, this.prest});

  @override
  State<PrestataireForm> createState() => PrestataireFormState();
}

class PrestataireFormState extends State<PrestataireForm> {
  bool uploading = false;
  double progress = 0;
  String? prestID;

  TextEditingController nom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController telephone = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController nif = TextEditingController();
  TextEditingController nis = TextEditingController();
  TextEditingController descr = TextEditingController();
  TextEditingController art = TextEditingController();
  TextEditingController rc = TextEditingController();

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    if (widget.prest != null) {
      prestID = widget.prest!.id;
      nom.text = widget.prest!.nom;
      nif.text = widget.prest!.nif ?? '';
      nis.text = widget.prest!.nis ?? '';
      art.text = widget.prest!.art ?? '';
      rc.text = widget.prest!.rc ?? '';
      descr.text = widget.prest!.description ?? '';
      email.text = widget.prest!.email ?? '';
      telephone.text = widget.prest!.telephone ?? '';
      adresse.text = widget.prest!.adresse;
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
    return Container(
      color: appTheme.backGroundColor,
      child: Column(
        children: [
          Container(
            color: appTheme.backGroundColor,
            child: Column(
              children: [
                SizedBox(
                  height: 63.h,
                  width: 40.w,
                  child: Column(
                    children: [
                      Flexible(
                        flex: 2,
                        child: ZoneBox(
                          label: 'fullname'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextBox(
                              controller: nom,
                              placeholder: 'fullname'.tr(),
                              style: appTheme.writingStyle,
                              placeholderStyle: placeStyle,
                              cursorColor: appTheme.color.darker,
                              decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

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
                          label: 'descr'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextBox(
                              controller: descr,
                              placeholder: 'descr'.tr(),
                              style: appTheme.writingStyle,
                              placeholderStyle: placeStyle,
                              cursorColor: appTheme.color.darker,
                              decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                              onChanged: (s) {
                                checkChanges();
                              },
                            ),
                          ),
                        ),
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
                                        decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

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
                                          decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

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
                                      decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

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
                        flex: 3,
                        child: ZoneBox(
                          label: 'legalinfo'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Flexible(
                                          child: TextBox(
                                            controller: nif,
                                            placeholder: 'NIF',
                                            style: appTheme.writingStyle,
                                            placeholderStyle: placeStyle,
                                            cursorColor: appTheme.color.darker,
                                            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                                            onChanged: (s) {
                                              checkChanges();
                                            },
                                          )),
                                      smallSpace,
                                      Flexible(
                                          child: TextBox(
                                            controller: nis,
                                            placeholder: 'NIS',
                                            style: appTheme.writingStyle,
                                            placeholderStyle: placeStyle,
                                            cursorColor: appTheme.color.darker,
                                            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                                            onChanged: (s) {
                                              checkChanges();
                                            },
                                          )),
                                    ],
                                  ),
                                ),
                                smallSpace,
                                Flexible(
                                  child: Row(
                                    children: [
                                      Flexible(
                                          child: TextBox(
                                            controller: rc,
                                            placeholder: 'RC',
                                            style: appTheme.writingStyle,
                                            placeholderStyle: placeStyle,
                                            cursorColor: appTheme.color.darker,
                                            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                                            onChanged: (s) {
                                              checkChanges();
                                            },
                                          )),
                                      smallSpace,
                                      Flexible(
                                          child: TextBox(
                                            controller: art,
                                            placeholder: 'ART',
                                            style: appTheme.writingStyle,
                                            placeholderStyle: placeStyle,
                                            cursorColor: appTheme.color.darker,
                                            decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                                            onChanged: (s) {
                                              checkChanges();
                                            },
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: 40.w,
            child: Row(
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
          ),
        ],
      ),
    );
  }

  bool changes = false;

  void checkChanges() {
    if (widget.prest != null) {
      if (nom.text == widget.prest!.nom &&
          adresse.text == widget.prest!.adresse &&
          telephone.text == widget.prest!.telephone &&
          nif.text == widget.prest!.nif &&
          nis.text == widget.prest!.nis &&
          art.text == widget.prest!.art &&
          rc.text == widget.prest!.rc &&
          descr.text == widget.prest!.description &&
          email.text == widget.prest!.email) {
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
    if (nom.value.text.isEmpty || adresse.text.isEmpty) {
      showMessage('nomadresreq', 'erreur');
      return;
    }
    if (!uploading) {
      setState(() {
        uploading = true;
        progress = 0;
      });
      prestID ??= DateTime.now()
          .difference(DatabaseGetter.ref)
          .inMilliseconds
          .toString();
      try {
        setState(() {
          progress = 50;
        });
        await uploadPrestataire();

        setState(() {
          progress = 90;
          changes = false;
        });
        showDoneMessages();
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

  void showDoneMessages() {
    if (widget.prest == null) {
      showMessage('prestsuccess', "ok");
    } else {
      showMessage('prestupdate', "ok");
    }
  }

  Future<void> uploadPrestataire() async {
    Client prest = Client(
      id: prestID!,
      nom: nom.text,
      email: FormValidators.isEmail(email.text) ? email.text : null,
      telephone: telephone.text,
      adresse: adresse.text,
      art: art.text,
      rc: rc.text,
      nif: nif.text,
      nis: nis.text,
      description: descr.text,
      search: '${nom.text} ${nif.text} ${nis.text} ${rc.text} ${email.text} '
          '${telephone.text} ${adresse.text} ${descr.text} $prestID ${art.text}',
    );
    if (widget.prest != null) {
      return await DatabaseGetter()
          .updateDocument(
          collectionId: prestataireId,
          documentId: prestID!,
          data: prest.toJson())
          .then((value) {
        DatabaseGetter().ajoutActivity(14, prestID!, docName: prest.nom);

        return value;
      });
    } else {
      return await DatabaseGetter()
          .addDocument(
          collectionId: prestataireId,
          documentId: prestID!,
          data: prest.toJson())
          .then((value) {
        DatabaseGetter().ajoutActivity(13, prestID!, docName: prest.nom);

        return value;
      });
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
