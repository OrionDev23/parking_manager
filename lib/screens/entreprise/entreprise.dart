import 'dart:io' as io;
import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';

import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/batch_import/import_appartenance.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../domain/entities/company.dart';
import '../../main.dart';
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
    final projectId = DatabaseGetter.activeProjectId;
    if (projectId == null) return;

    downloading = true;
    if (mounted) setState(() {});
    try {
      final company = await companyService.getCurrent();
      if (!DatabaseGetter.isCurrentTenant(projectId)) return;

      if (company != null) {
        p = Entreprise(
          id: company.id,
          nom: company.name,
          adresse: company.address,
          telephone: company.phone,
          email: company.email,
          description: company.description,
          nif: company.nif,
          nis: company.nis,
          rc: company.rc,
          art: company.art,
          logo: company.logo,
          filiales: List<String>.from(company.subsidiaries),
          directions: List<String>.from(company.directions),
          departments: List<String>.from(company.departments),
        );
        initValues();
        await downloadLogo();
      }
    } catch (e) {
      debugPrint('[ParcOto Company] load failed: $e');
    } finally {
      if (DatabaseGetter.isCurrentTenant(projectId)) {
        downloading = false;
        if (mounted) setState(() {});
      }
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
      directions = p!.directions ?? [];
      filliales = p!.filiales ?? [];
      departments = p!.departments ?? [];
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
          email.text == p!.email &&
          p!.filiales == filliales &&
          p!.directions == directions &&
          p!.departments == departments) {
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
    await FilePicker.pickFile(
          dialogTitle: 'picklogo'.tr(),
          type: FileType.image,
        )
        .then((value) {
          if (value?.path != null) imageFile = io.File(value!.path!);
          setState(() {});
        })
        .onError((error, stackTrace) {});
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
    final projectId = DatabaseGetter.activeProjectId;
    final activeStorage = DatabaseGetter.storage;
    if (projectId == null || activeStorage == null) return;

    downloadingLogo = true;
    if (mounted) setState(() {});
    final link = !kIsWeb && p?.logo != null && p!.logo!.isNotEmpty
        ? p!.logo!
        : logoid;

    try {
      if (!kIsWeb) {
        try {
          await FileImage(io.File(logoid)).evict();
        } catch (_) {
          // Cache eviction is best-effort.
        }
      }

      final bytes = await activeStorage.getFileDownload(
        bucketId: buckedId,
        fileId: link,
      );
      if (!DatabaseGetter.isCurrentTenant(projectId)) return;

      if (!kIsWeb) {
        await io.File(logoid).writeAsBytes(bytes);
        if (!DatabaseGetter.isCurrentTenant(projectId)) return;
        await prefs.setString('company_logo_project', projectId);
      }
      logo = bytes;
      MyEntrepriseState.logo = bytes;
    } catch (error) {
      if (DatabaseGetter.isCurrentTenant(projectId)) {
        debugPrint('[ParcOto Company] logo download failed: $error');
        logo = null;
      }
    } finally {
      if (DatabaseGetter.isCurrentTenant(projectId)) {
        downloadingLogo = false;
        if (mounted) setState(() {});
      }
    }
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
      final projectId = DatabaseGetter.activeProjectId;
      final cachedProject = prefs.getString('company_logo_project');
      logoExists = projectId != null &&
          cachedProject == projectId &&
          await io.File(logoid).exists();
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
                                                    fit: BoxFit.fitWidth,
                                                  )
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
                                            FluentIcons.file_image,
                                          ),
                                          onPressed:
                                              checkingFile ||
                                                  downloadingLogo ||
                                                  downloading ||
                                                  pickingFile
                                              ? null
                                              : pickImage,
                                        ),
                                        smallSpace,
                                        IconButton(
                                          icon: const Icon(FluentIcons.refresh),
                                          onPressed:
                                              checkingFile ||
                                                  downloadingLogo ||
                                                  downloading ||
                                                  pickingFile
                                              ? null
                                              : downloadLogo,
                                        ),
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
                                  child: ParcotoTextBox(
                                    controller: nom,
                                    placeholder: 'fullname'.tr(),
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    cursorColor: appTheme.color.darker,

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
                                  child: ParcotoTextBox(
                                    controller: descr,
                                    placeholder: 'descr'.tr(),
                                    style: appTheme.writingStyle,
                                    placeholderStyle: placeStyle,
                                    cursorColor: appTheme.color.darker,

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
                                            child: ParcotoTextBox(
                                              controller: email,
                                              placeholder: 'email'.tr(),
                                              style: appTheme.writingStyle,
                                              placeholderStyle: placeStyle,
                                              cursorColor:
                                                  appTheme.color.darker,

                                              onChanged: (s) {
                                                checkChanges();
                                              },
                                            ),
                                          ),
                                          smallSpace,
                                          SizedBox(
                                            width: 187,
                                            child: ParcotoTextBox(
                                              controller: telephone,
                                              placeholder: 'telephone'.tr(),
                                              style: appTheme.writingStyle,
                                              placeholderStyle: placeStyle,
                                              cursorColor:
                                                  appTheme.color.darker,

                                              onChanged: (s) {
                                                checkChanges();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      smallSpace,
                                      Flexible(
                                        child: ParcotoTextBox(
                                          controller: adresse,
                                          placeholder: 'adresse'.tr(),
                                          maxLines: 3,
                                          style: appTheme.writingStyle,
                                          placeholderStyle: placeStyle,
                                          cursorColor: appTheme.color.darker,

                                          onChanged: (s) {
                                            checkChanges();
                                          },
                                        ),
                                      ),
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
                                              child: ParcotoTextBox(
                                                controller: nif,
                                                placeholder: 'NIF',
                                                style: appTheme.writingStyle,
                                                placeholderStyle: placeStyle,
                                                cursorColor:
                                                    appTheme.color.darker,

                                                onChanged: (s) {
                                                  checkChanges();
                                                },
                                              ),
                                            ),
                                            smallSpace,
                                            Flexible(
                                              child: ParcotoTextBox(
                                                controller: nis,
                                                placeholder: 'NIS',
                                                style: appTheme.writingStyle,
                                                placeholderStyle: placeStyle,
                                                cursorColor:
                                                    appTheme.color.darker,

                                                onChanged: (s) {
                                                  checkChanges();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      smallSpace,
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: ParcotoTextBox(
                                                controller: rc,
                                                placeholder: 'RC',
                                                style: appTheme.writingStyle,
                                                placeholderStyle: placeStyle,
                                                cursorColor:
                                                    appTheme.color.darker,

                                                onChanged: (s) {
                                                  checkChanges();
                                                },
                                              ),
                                            ),
                                            smallSpace,
                                            Flexible(
                                              child: ParcotoTextBox(
                                                controller: art,
                                                placeholder: 'ART',
                                                style: appTheme.writingStyle,
                                                placeholderStyle: placeStyle,
                                                cursorColor:
                                                    appTheme.color.darker,

                                                onChanged: (s) {
                                                  checkChanges();
                                                },
                                              ),
                                            ),
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
                        onPressed: uploading || downloading
                            ? null
                            : downloadData,
                        child: const Text('refresh').tr(),
                      ),
                      smallSpace,
                      FilledButton(
                        onPressed: uploading || downloading ? null : upload,
                        child: uploading
                            ? ProgressBar(value: progress)
                            : const Text('save').tr(),
                      ),
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
              child: const ProgressBar(strokeWidth: 10),
            ),
        ],
      ),
    );
  }

  TextEditingController fillialeToAdd = TextEditingController();
  TextEditingController directionToAdd = TextEditingController();

  TextEditingController departmentToAdd = TextEditingController();

  double tilesHeight = 50.px;
  Widget fillialeWidget(AppTheme appTheme) {
    return SizedBox(
      height: filliales.isEmpty
          ? 100.px
          : filliales.length * tilesHeight + 80.px,
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
                      child: ParcotoTextBox(
                        controller: fillialeToAdd,
                        placeholder: 'writefiliale'.tr(),
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,

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
                      child: const Text('add').tr(),
                    ),
                    smallSpace,
                    FilledButton(
                      onPressed: () => importFiliales(),
                      child: const Text('importlist').tr(),
                    ),
                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: filliales.isEmpty ? 1 : filliales.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if (filliales.isEmpty) {
                    return Center(
                      child: SizedBox(
                        height: 20.px,
                        child: Text(
                          'fillialesempty',
                          style: TextStyle(
                            color: Colors.grey[100],
                            fontStyle: FontStyle.italic,
                          ),
                        ).tr(),
                      ),
                    );
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor: WidgetStateColor.resolveWith(
                        (states) => appTheme.fillColor,
                      ),
                      title: Text(
                        filliales[index],
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(FluentIcons.cancel, size: 15),
                        onPressed: () {
                          setState(() {
                            filliales.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget directionsWidget(AppTheme appTheme) {
    return SizedBox(
      height: departments.isEmpty
          ? 100.px
          : departments.length * tilesHeight + 80.px,
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
                      child: ParcotoTextBox(
                        controller: directionToAdd,
                        placeholder: 'writedirection'.tr(),
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,

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
                      child: const Text('add').tr(),
                    ),
                    smallSpace,
                    FilledButton(
                      onPressed: () => importDirections(),
                      child: const Text('importlist').tr(),
                    ),
                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: directions.isEmpty ? 1 : directions.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if (directions.isEmpty) {
                    return Center(
                      child: SizedBox(
                        height: 20.px,
                        child: Text(
                          'directionssempty',
                          style: TextStyle(
                            color: Colors.grey[100],
                            fontStyle: FontStyle.italic,
                          ),
                        ).tr(),
                      ),
                    );
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor: WidgetStateColor.resolveWith(
                        (states) => appTheme.fillColor,
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget departmentsWidget(AppTheme appTheme) {
    return SizedBox(
      height: directions.isEmpty
          ? 100.px
          : directions.length * tilesHeight + 80.px,
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
                      child: ParcotoTextBox(
                        controller: departmentToAdd,
                        placeholder: 'writedepartment'.tr(),
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,

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
                      child: const Text('add').tr(),
                    ),
                    smallSpace,
                    FilledButton(
                      onPressed: () => importDepartments(),
                      child: const Text('importlist').tr(),
                    ),
                  ],
                ),
              ),
              smallSpace,
              ListView.builder(
                itemCount: departments.isEmpty ? 1 : departments.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  if (departments.isEmpty) {
                    return Center(
                      child: SizedBox(
                        height: 20.px,
                        child: Text(
                          'departmentsempty',
                          style: TextStyle(
                            color: Colors.grey[100],
                            fontStyle: FontStyle.italic,
                          ),
                        ).tr(),
                      ),
                    );
                  }
                  return SizedBox(
                    height: tilesHeight,
                    child: ListTile(
                      tileColor: WidgetStateColor.resolveWith(
                        (states) => appTheme.fillColor,
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void importDepartments() async {
    PlatformFile? pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (pickedFile != null) {
      departments.addAll(
        await ImportAppartenance(file: pickedFile, type: 2).loadFile(),
      );
      setState(() {});
    }
  }

  void importDirections() async {
    PlatformFile? pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (pickedFile != null) {
      directions.addAll(
        await ImportAppartenance(file: pickedFile, type: 1).loadFile(),
      );
      setState(() {});
    }
  }

  void importFiliales() async {
    PlatformFile? pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (pickedFile != null) {
      filliales.addAll(
        await ImportAppartenance(file: pickedFile, type: 0).loadFile(),
      );
      setState(() {});
    }
  }

  void upload() async {
    if (nom.value.text.isEmpty || adresse.text.isEmpty) {
      showMessage('nomadresreq', 'erreur');
      return;
    }
    if (uploading) return;

    final projectId = DatabaseGetter.activeProjectId;
    if (projectId == null) {
      showMessage('errupld', 'erreur');
      return;
    }

    setState(() {
      uploading = true;
      progress = 0;
    });

    try {
      setState(() => progress = 10);
      await uploadLogo();
      if (!mounted) return;
      if (!DatabaseGetter.isCurrentTenant(projectId)) {
        setState(() => uploading = false);
        return;
      }

      setState(() => progress = 50);
      await uploadEntreprise();
      if (!mounted) return;
      if (!DatabaseGetter.isCurrentTenant(projectId)) {
        setState(() => uploading = false);
        return;
      }

      setState(() => progress = 90);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      if (!DatabaseGetter.isCurrentTenant(projectId)) {
        setState(() => uploading = false);
        return;
      }

      setState(() {
        progress = 100;
        changes = false;
        uploading = false;
      });
      showMessage(p == null ? 'entrepsuccess' : 'entrepupdate', 'ok');
    } catch (error) {
      debugPrint('[ParcOto Company] save failed: $error');
      if (mounted) {
        setState(() {
          uploading = false;
        });
        showMessage('errupld', 'erreur');
      }
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
      search:
          '${nom.text} ${nif.text} ${nis.text} ${rc.text} ${email.text} '
          '${telephone.text} ${adresse.text} ${descr.text} 1 $logoid ${art.text}',
    );
    final projectId = DatabaseGetter.activeProjectId;
    if (projectId == null) {
      throw StateError('No active Appwrite tenant.');
    }
    final updated = await companyService.update(
      Company(
        id: prest.id,
        name: prest.nom,
        address: prest.adresse,
        phone: prest.telephone,
        email: prest.email,
        description: prest.description,
        nif: prest.nif,
        nis: prest.nis,
        rc: prest.rc,
        art: prest.art,
        logo: prest.logo,
        subsidiaries: List<String>.from(prest.filiales ?? const []),
        directions: List<String>.from(prest.directions ?? const []),
        departments: List<String>.from(prest.departments ?? const []),
      ),
    );
    if (!DatabaseGetter.isCurrentTenant(projectId)) {
      throw StateError('Tenant changed while saving company information.');
    }

    p = Entreprise(
      id: updated.id,
      nom: updated.name,
      adresse: updated.address,
      telephone: updated.phone,
      email: updated.email,
      description: updated.description,
      nif: updated.nif,
      nis: updated.nis,
      rc: updated.rc,
      art: updated.art,
      logo: updated.logo,
      filiales: List<String>.from(updated.subsidiaries),
      directions: List<String>.from(updated.directions),
      departments: List<String>.from(updated.departments),
    );
  }

  Future<void> uploadLogo() async {
    final selectedImage = imageFile;
    if (selectedImage == null) return;

    final projectId = DatabaseGetter.activeProjectId;
    final activeStorage = DatabaseGetter.storage;
    if (projectId == null || activeStorage == null) {
      throw StateError('No active Appwrite tenant.');
    }

    final bytes = await selectedImage.readAsBytes();
    if (!DatabaseGetter.isCurrentTenant(projectId)) {
      throw StateError('Tenant changed while reading the company logo.');
    }

    try {
      await activeStorage.deleteFile(
        bucketId: buckedId,
        fileId: logoid,
      );
    } on AppwriteException {
      // The logo may not exist yet.
    }
    if (!DatabaseGetter.isCurrentTenant(projectId)) {
      throw StateError('Tenant changed while replacing the company logo.');
    }

    try {
      await FileImage(io.File(logoid)).evict();
    } catch (_) {
      // Cache eviction is best-effort.
    }

    await activeStorage.createFile(
      bucketId: buckedId,
      fileId: logoid,
      file: InputFile.fromBytes(bytes: bytes, filename: logoid),
    );
    if (!DatabaseGetter.isCurrentTenant(projectId)) {
      throw StateError('Tenant changed while uploading the company logo.');
    }

    if (!kIsWeb) {
      await io.File(logoid).writeAsBytes(bytes, mode: io.FileMode.write);
    }
    logo = bytes;
    MyEntrepriseState.logo = bytes;
  }

  void showMessage(String message, String title) {
    showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title).tr(),
        content: Text(message).tr(),
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
    nom.dispose();
    email.dispose();
    telephone.dispose();
    adresse.dispose();
    nif.dispose();
    nis.dispose();
    descr.dispose();
    art.dispose();
    rc.dispose();
    imageFile = null;
    super.dispose();
  }
}
