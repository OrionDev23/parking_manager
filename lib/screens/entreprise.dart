import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/entreprise.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../providers/client_database.dart';

class MyEntreprise extends StatefulWidget {
  const MyEntreprise({super.key});

  @override
  State<MyEntreprise> createState() => MyEntrepriseState();
}

class MyEntrepriseState extends State<MyEntreprise> {
  TextEditingController nom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController telephone = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController nif = TextEditingController();
  TextEditingController nis = TextEditingController();
  TextEditingController descr = TextEditingController();
  TextEditingController art = TextEditingController();
  TextEditingController rc = TextEditingController();

  static Entreprise? p;

  bool changes = false;

  static bool downloading = false;

  @override
  void initState() {
    if (downloading) {
      waitForDownload();
    } else {
      if (p == null) {
        downloadData();
      } else {
        initValues();
      }
    }
    super.initState();
  }

  void waitForDownload() async {
    while (downloading) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!downloading) {
        break;
      }
    }
    initValues();
    setState(() {});
  }

  void downloadData() async {
    downloading = true;
    if (mounted) {
      setState(() {});
    }
    try {
      await ClientDatabase.database!
          .getDocument(
              databaseId: databaseId,
              collectionId: entrepriseid,
              documentId: "1")
          .then((value) {
        p = value
            .convertTo((p0) => Entreprise.fromJson(p0 as Map<String, dynamic>));
        initValues();
      });
      setState(() {
        downloading = false;
      });
    } catch (e) {
      setState(() {
        downloading = false;
      });
    }
  }

  void initValues() {
    if (p != null) {
      nom.text = p!.nom;
      nif.text = p!.nif ?? '';
      nis.text = p!.nis ?? '';
      art.text = p!.art ?? '';
      rc.text = p!.rc ?? '';
      descr.text = p!.description ?? '';
      email.text = p!.email ?? '';
      telephone.text = p!.telephone ?? '';
      adresse.text = p!.adresse;
    }
  }

  void checkChanges() {
    if (p != null) {
      if (nom.text == p!.nom &&
          adresse.text == p!.adresse &&
          telephone.text == p!.telephone &&
          nif.text == p!.nif &&
          nis.text == p!.nis &&
          art.text == p!.art &&
          rc.text == p!.rc &&
          descr.text == p!.description &&
          email.text == p!.email) {
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

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();

    return Container(
      color: appTheme.backGroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(
                  height: 80.h,
                  width: 40.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 4,
                        child: ZoneBox(
                          label: 'logo'.tr(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                maxRadius: 50,
                                backgroundColor: appTheme.color.lighter,
                              ),
                              smallSpace,
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                      icon: const Icon(FluentIcons.file_image),
                                      onPressed: downloading ? null : () {}),
                                  smallSpace,
                                  IconButton(
                                      icon: const Icon(FluentIcons.refresh),
                                      onPressed: downloading ? null : () {}),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
                          label: 'descr'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextBox(
                              controller: descr,
                              placeholder: 'descr'.tr(),
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
                                        controller: nis,
                                        placeholder: 'NIS',
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
                                        controller: art,
                                        placeholder: 'ART',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bigSpace,
                SizedBox(
                  width: 40.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(
                          onPressed: downloading ? null : downloadData,
                          child: const Text('refresh').tr()),
                      smallSpace,
                      FilledButton(
                          onPressed: downloading ? null : () {},
                          child: const Text('save').tr()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (downloading)
            Positioned(top: 40.h, left: 35.w, child: const ProgressBar()),
        ],
      ),
    );
  }



  @override
  void dispose() {
    downloading=false;
    super.dispose();
  }
}
