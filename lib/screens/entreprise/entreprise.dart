import 'dart:io' as io;

import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/batch_import/import_appartenance.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../serializables/entreprise.dart';
import '../../theme.dart';
import '../../widgets/zone_box.dart';

const logoid = "mylogo.png";

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

  static io.File? imageFile;

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
        checkLogoOrDownload();
        initValues();
      }
    }
    super.initState();
  }

  void checkLogoOrDownload() async {
    await checkIfLogoExists();
    if (!logoExists) {
      downloadLogo();
    }
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
      await DatabaseGetter.database!
          .getDocument(
              databaseId: databaseId,
              collectionId: entrepriseid,
              documentId: "1")
          .then((value) {
        p = value
            .convertTo((p0) => Entreprise.fromJson(p0 as Map<String, dynamic>));
        downloadLogo();
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
      directions=p!.directions??[];
      filliales=p!.filiales??[];
      departments=p!.departments??[];
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
          email.text == p!.email && p!.filiales==filliales && p!
          .directions==directions && p!.departments==departments) {
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
    } else if (imageFile != null) {
      setState(() {
        changes = true;
      });
    } else {
      if (!changes) {
        setState(() {
          changes = true;
        });
      }
    }
  }

  bool pickingFile = false;

  void pickImage() async {
    setState(() {
      pickingFile = true;
    });
    await FilePicker.platform
        .pickFiles(
      dialogTitle: 'picklogo'.tr(),
      type: FileType.image,
    )
        .then((value) {
      imageFile = io.File(value!.files.first.path!);
      setState(() {});
    }).onError((error, stackTrace) {});
    setState(() {
      pickingFile = false;
    });
  }

  bool downloadingLogo = false;

  static Uint8List? logo;
  bool uploading = false;
  double progress = 0;

  List<String> directions = [];
  List<String> departments = [];
  List<String> filliales = [];

  Future<void> downloadLogo() async {
    downloadingLogo = true;
    if (mounted) {
      setState(() {});
    }
    String link = "";

    if (kIsWeb) {
    } else {
      if (p != null && p!.logo != null && p!.logo!.isNotEmpty) {
        link = p!.logo!;
      } else {
        link = logoid;
      }
      try {
        await FileImage(io.File('mylogo.png')).evict();
      } catch (e) {
        //
      }
    }

    await DatabaseGetter.storage!
        .getFileDownload(bucketId: buckedId, fileId: link)
        .then((value) async {
      logo = value;
      if (!kIsWeb) {
        io.File file = io.File(logoid);

        await file.writeAsBytes(value).then((value) {
          downloadingLogo = false;
          if (mounted) {
            setState(() {});
          }
        }).onError((error, stackTrace) {});
      } else {
        MyEntrepriseState.logo = value;
      }
      downloadingLogo = false;
      if (mounted) {
        setState(() {});
      }
    }).onError((error, stackTrace) {
      logo = null;
      downloadingLogo = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  static bool checkingFile = false;
  static bool logoExists = false;

  Future<void> checkIfLogoExists() async {
    if (kIsWeb) {
      checkingFile = true;
      if (MyEntrepriseState.logo != null) {
        logoExists = true;
      } else {
        logoExists = false;
      }
    } else {
      checkingFile = true;
      if (mounted) {
        setState(() {});
      }
      if (await io.File(logoid).exists()) {
        logoExists = true;
      } else {
        logoExists = false;
      }
    }
    checkingFile = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();

    return Container(
      color: appTheme.backGroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 600.px,
            height: 90.h,
            child: Column(
              children: [
                Flexible(
                  child: ListView(
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      SizedBox(
                        height: 550.px,
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
                                    Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: appTheme.color.lighter,
                                        boxShadow: kElevationToShadow[2],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: imageFile != null
                                          ? Image.memory(
                                              imageFile!.readAsBytesSync(),
                                              fit: BoxFit.fitWidth,
                                            )
                                          : kIsWeb
                                              ? MyEntrepriseState.logo != null
                                                  ? Image.memory(
                                                      logo!,
                                                      fit: BoxFit.fitWidth)
                                                  : Image.asset(
                                                      'assets/images/logo.webp',
                                                      fit: BoxFit.fitWidth,
                                                    )
                                              : logoExists
                                                  ? Image.file(
                                                      io.File(logoid),
                                                      fit: BoxFit.fitWidth,
                                                    )
                                                  : Image.asset(
                                                      'assets/images/logo.webp',
                                                      fit: BoxFit.fitWidth,
                                                    ),
                                    ),
                                    smallSpace,
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                            icon: const Icon(
                                                FluentIcons.file_image),
                                            onPressed: checkingFile ||
                                                    downloadingLogo ||
                                                    downloading ||
                                                    pickingFile
                                                ? null
                                                : pickImage),
                                        smallSpace,
                                        IconButton(
                                            icon:
                                                const Icon(FluentIcons.refresh),
                                            onPressed: checkingFile ||
                                                    downloadingLogo ||
                                                    downloading ||
                                                    pickingFile
                                                ? null
                                                : downloadLogo),
                                      ],
                                    ),
                                  ],
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
                                              cursorColor:
                                                  appTheme.color.darker,
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
                                                cursorColor:
                                                    appTheme.color.darker,
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
                                              cursorColor:
                                                  appTheme.color.darker,
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
                                              cursorColor:
                                                  appTheme.color.darker,
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
                                              cursorColor:
                                                  appTheme.color.darker,
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
                                              cursorColor:
                                                  appTheme.color.darker,
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
                      smallSpace,
                      fillialeWidget(appTheme),
                      smallSpace,
                      directionsWidget(appTheme),
                      smallSpace,
                      departmentsWidget(appTheme),
                    ],
                  ),
                ),
                smallSpace,
                SizedBox(
                  height: 60.px,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(
                          onPressed:
                              uploading || downloading ? null : downloadData,
                          child: const Text('refresh').tr()),
                      smallSpace,
                      FilledButton(
                          onPressed: uploading || downloading ? null : upload,
                          child: uploading
                              ? ProgressBar(
                                  value: progress,
                                )
                              : const Text('save').tr()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (downloading)
            Positioned(
                top: 40.h,
                left: 35.w,
                child: const ProgressBar(
                  strokeWidth: 10,
                )),
        ],
      ),
    );
  }

  TextEditingController fillialeToAdd = TextEditingController();
  TextEditingController directionToAdd = TextEditingController();

  TextEditingController departmentToAdd = TextEditingController();

  double tilesHeight=50.px;
  Widget fillialeWidget(AppTheme appTheme) {
    return SizedBox(
      height: filliales.isEmpty?100.px:filliales.length * tilesHeight + 80.px,
      child: ZoneBox(
        label: 'filiales'.tr(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 35.px,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextBox(
                        controller: fillialeToAdd,
                        placeholder: 'writefiliale'.tr(),
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,
                        decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                        onChanged: (s) {
                          setState(() {});
                        },
                        onSubmitted: (s) {
                          if (s.isNotEmpty) {
                            filliales.add(s.trim());
                            setState(() {
                              fillialeToAdd.clear();
                            });
                          }
                          checkChanges();
                        },
                      ),
                    ),
                    smallSpace,
                    FilledButton(
                        onPressed: fillialeToAdd.text.trim().isEmpty
                            ? null
                            : () {
                                if (fillialeToAdd.text.trim().isNotEmpty) {
                                  filliales.add(fillialeToAdd.text.trim());
                                  setState(() {
                                    fillialeToAdd.clear();
                                  });
                                }
                                checkChanges();
                              },
                        child: const Text('add').tr()),
                    smallSpace,
                    FilledButton(
                        onPressed: ()=>importFiliales(),
                        child: const Text('importlist').tr()),

                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: filliales.isEmpty?1:filliales.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if(filliales.isEmpty){
                    return Center(
                        child: SizedBox(
                          height: 20.px,
                          child: Text('fillialesempty',
                              style:TextStyle(color:Colors.grey[100],
                                  fontStyle: FontStyle.italic))
                              .tr(),
                        )
                    );
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor:
                      WidgetStatePropertyAll<Color>(appTheme.fillColor),
                      title: Text(
                        filliales[index],
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(FluentIcons.cancel,size: 15,),
                        onPressed: () {
                          setState(() {
                            filliales.removeAt(index);
                          });
                        },
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

  Widget directionsWidget(AppTheme appTheme) {
    return SizedBox(
      height: directions.isEmpty?100.px:directions.length * tilesHeight + 80.px,
      child: ZoneBox(
        label: 'directions'.tr(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 35.px,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextBox(
                        controller: directionToAdd,
                        placeholder: 'writedirection'.tr(),
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,
                        decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                        onChanged: (s) {
                          setState(() {});
                        },
                        onSubmitted: (s) {
                          if (s.isNotEmpty) {
                            directions.add(s.trim());
                            setState(() {
                              directionToAdd.clear();
                            });
                          }
                          checkChanges();
                        },
                      ),
                    ),
                    smallSpace,
                    FilledButton(
                        onPressed: directionToAdd.text.trim().isEmpty
                            ? null
                            : () {
                                if (directionToAdd.text.trim().isNotEmpty) {
                                  directions.add(directionToAdd.text.trim());
                                  setState(() {
                                    directionToAdd.clear();
                                  });
                                }
                                checkChanges();
                              },
                        child: const Text('add').tr()),
                    smallSpace,
                    FilledButton(
                        onPressed: ()=>importDirections(),
                        child: const Text('importlist').tr()),
                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: directions.isEmpty?1:directions.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if(directions.isEmpty){
                    return Center(
                      child: SizedBox(
                        height: 20.px,
                        child: Text('directionssempty',
                            style:TextStyle(color:Colors.grey[100],
                            fontStyle: FontStyle.italic))
                            .tr(),
                      )
                    );
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor:
                      WidgetStatePropertyAll<Color>(appTheme.fillColor),
                      title: Text(
                        directions[index],
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(FluentIcons.cancel),
                        onPressed: () {
                          setState(() {
                            directions.removeAt(index);
                          });
                        },
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

  Widget departmentsWidget(AppTheme appTheme) {
    return SizedBox(
      height: directions.isEmpty?100.px:directions.length * tilesHeight + 80.px,
      child: ZoneBox(
        label: 'departements'.tr(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 35.px,
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextBox(
                        controller: departmentToAdd,
                        placeholder: 'writedepartment'.tr(),
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,
                        decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                        onChanged: (s) {
                          setState(() {});
                        },
                        onSubmitted: (s) {
                          if (s.isNotEmpty) {
                            departments.add(s.trim());
                            setState(() {
                              departmentToAdd.clear();
                            });
                          }
                          checkChanges();
                        },
                      ),
                    ),
                    smallSpace,
                    FilledButton(
                        onPressed: departmentToAdd.text.trim().isEmpty
                            ? null
                            : () {
                          if (departmentToAdd.text.trim().isNotEmpty) {
                            departments.add(departmentToAdd.text.trim());
                            setState(() {
                              departmentToAdd.clear();
                            });
                          }
                          checkChanges();
                        },
                        child: const Text('add').tr()),
                    smallSpace,
                    FilledButton(
                        onPressed: ()=>importDepartments(),
                        child: const Text('importlist').tr()),
                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: departments.isEmpty?1:directions.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if(departments.isEmpty){
                    return Center(
                        child: SizedBox(
                          height: 20.px,
                          child: Text('departmentsempty',
                              style:TextStyle(color:Colors.grey[100],
                                  fontStyle: FontStyle.italic))
                              .tr(),
                        )
                    );
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor:
                      WidgetStatePropertyAll<Color>(appTheme.fillColor),
                      title: Text(
                        departments[index],
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(FluentIcons.cancel),
                        onPressed: () {
                          setState(() {
                            departments.removeAt(index);
                          });
                        },
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

  void importDepartments() async{
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (pickedFile != null) {
      departments.addAll(await ImportAppartenance(file: pickedFile,type:2)
          .loadFile());
      setState(() {

      });
    }
  }

  void importDirections() async{
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (pickedFile != null) {
      directions.addAll(await ImportAppartenance(file: pickedFile,type:1)
          .loadFile());
      setState(() {

      });
    }
  }

  void importFiliales() async{
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (pickedFile != null) {
      filliales.addAll(await ImportAppartenance(file: pickedFile,type:0)
          .loadFile());
      setState(() {

      });
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
      try {
        setState(() {
          progress = 10;
        });
        await uploadLogo();
        setState(() {
          progress = 50;
        });
        await uploadEntreprise();

        setState(() {
          progress = 90;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          progress = 100;
          changes = false;
        });
        if (p == null) {
          showMessage('entrepsuccess', "ok");
        } else {
          showMessage('entrepupdate', "ok");
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


  Future<void> uploadEntreprise() async {
    Entreprise prest = Entreprise(
      id: p?.id ?? '1',
      nom: nom.text,
      email: email.text.isEmpty ? null : email.text,
      telephone: telephone.text,
      adresse: adresse.text,
      art: art.text,
      rc: rc.text,
      nif: nif.text,
      nis: nis.text,
      logo: logoid,
      filiales: filliales,
      directions: directions,
      departments: departments,
      description: descr.text,
      search: '${nom.text} ${nif.text} ${nis.text} ${rc.text} ${email.text} '
          '${telephone.text} ${adresse.text} ${descr.text} 1 $logoid ${art.text}',
    );
    if (p != null) {
      await DatabaseGetter.database!
          .updateDocument(
              databaseId: databaseId,
              collectionId: entrepriseid,
              documentId: p!.id,
              data: prest.toJson())
          .then((value) {
        p = prest;
          }).onError((AppwriteException error, stackTrace) {
       // print(error.message);
      });
    }
    else {
      await DatabaseGetter.database!
          .createDocument(
              databaseId: databaseId,
              collectionId: entrepriseid,
              documentId: '1',
              data: prest.toJson())
          .then((value) {
        p = prest;
      });
    }
  }

  Future<void> uploadLogo() async {
    if (imageFile != null) {
      var bytes = await imageFile!.readAsBytes();
      try {
        await DatabaseGetter.storage!
            .deleteFile(bucketId: buckedId, fileId: logoid);
      } catch (e) {
        //
      }
      try {
        await FileImage(io.File('mylogo.png')).evict();
      } catch (e) {
        //
      }
      await DatabaseGetter.storage!
          .createFile(
              bucketId: buckedId,
              fileId: logoid,
              file: InputFile.fromBytes(
                bytes: bytes,
                filename: logoid,
              ))
          .then((value) async {
        io.File file = io.File(logoid);
        await file.writeAsBytes(bytes, mode: io.FileMode.write);
      }).onError((AppwriteException error, stackTrace) {});
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

  @override
  void dispose() {
    downloading = false;
    imageFile = null;
    super.dispose();
  }
}
