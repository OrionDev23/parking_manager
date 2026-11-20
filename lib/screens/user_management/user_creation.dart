import 'package:country_code_picker/country_code_picker.dart';
import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart' hide Row;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../serializables/parc_user.dart';
import '../../theme.dart';
import '../../utilities/country_list.dart';
import '../../utilities/form_validators.dart';
import '../../utilities/profil_beautifier.dart';

class UserForm extends StatefulWidget {
  final User? user;

  const UserForm({super.key, this.user});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  late TextEditingController email;

  late TextEditingController password;
  late TextEditingController passwordConfirm;
  late TextEditingController name;
  late TextEditingController phone;

  String countrySelected = 'DZ';
  String phoneDial = "+213";
  String? userID;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  bool showPassword = false;
  bool showPasswordConfirm = false;

  void initValues() {
    email = TextEditingController(text: widget.user?.email);
    password = TextEditingController(text: widget.user?.password);
    passwordConfirm = TextEditingController(text: widget.user?.password);
    validEmail = FormValidators.isEmail(email.text);
    name = TextEditingController(text: widget.user?.name);
    countrySelected = Countries.getCountryCodeFromPhone(widget.user?.phone);
    if (widget.user != null && widget.user!.phone.length > 3) {
      phone = TextEditingController(
        text: widget.user?.phone.substring(4, widget.user?.phone.length),
      );
    } else {
      phone = TextEditingController();
    }
  }

  void testIfSomethingChanged() {
    final originalPhone = widget.user?.phone;
    final originalLocalPhone =
        originalPhone != null && originalPhone.length > 3
        ? originalPhone.substring(4)
        : '';

    final hasChanges =
        email.text != widget.user?.email ||
        name.text != widget.user?.name ||
        password.text != widget.user?.password ||
        countrySelected != Countries.getCountryCodeFromPhone(originalPhone) ||
        phone.text != originalLocalPhone;

    if (hasChanges != somethingChanged && mounted) {
      setState(() => somethingChanged = hasChanges);
    }
  }

  bool somethingChanged = false;
  bool validEmail = false;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final screenSize = MediaQuery.sizeOf(context);
    final avatarSize = screenSize.width < 640 ? 72.0 : 96.0;
    final countryDialogSize = Size(
      (screenSize.width - 32).clamp(280.0, 480.0).toDouble(),
      (screenSize.height - 80).clamp(320.0, 600.0).toDouble(),
    );
    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: (screenSize.width - 32).clamp(280.0, 480.0).toDouble(),
        maxHeight: (screenSize.height - 48).clamp(320.0, 720.0).toDouble(),
      ),
      title: Text(
        widget.user != null
            ? widget.user!.name.isNotEmpty
                  ? widget.user!.name
                  : widget.user!.email
            : 'newuser'.tr(),
      ),
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'myprofil',
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: appTheme.color,
                    shape: BoxShape.circle,
                    boxShadow: kElevationToShadow[2],
                  ),
                  padding: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: Text(
                    widget.user != null
                        ? ParcOtoUtilities.getFirstLetters(
                            ParcUser(
                              id: '',
                              email: widget.user!.email,
                              name: widget.user!.name,
                            ),
                          ).toUpperCase()
                        : '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InfoLabel(
            label: validEmail ? '' : 'entervalidemail'.tr(),
            labelStyle: TextStyle(color: Colors.red, fontSize: 12.sp),
            child: Row(
              children: [
                Icon(FluentIcons.mail, color: Colors.grey[100]),
                const SizedBox(width: 10),
                Expanded(
                  child: ParcotoTextBox(
                    controller: email,
                    placeholder: 'email'.tr(),
                    enabled: widget.user == null,
                    onChanged: (s) {
                      final nextValid = FormValidators.isEmail(s);
                      if (nextValid != validEmail) {
                        setState(() => validEmail = nextValid);
                      }
                      if (nextValid) {
                        testIfSomethingChanged();
                      }
                    },
                    placeholderStyle: placeStyle,
                    cursorColor: appTheme.color.darker,
                    style: appTheme.writingStyle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(FluentIcons.i_d_badge, color: Colors.grey[100]),
              const SizedBox(width: 10),
              Expanded(
                child: ParcotoTextBox(
                  controller: name,
                  placeholder: 'nom'.tr(),
                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(FluentIcons.password_field, color: Colors.grey[100]),
              const SizedBox(width: 10),
              Expanded(
                child: ParcotoTextBox(
                  controller: password,
                  placeholder: 'motdepasse'.tr(),
                  enabled: widget.user == null,
                  suffix: IconButton(
                    icon: Icon(
                      showPassword ? FluentIcons.hide : FluentIcons.red_eye,
                      color: !showPassword ? appTheme.color : Colors.grey[100],
                      size: 12.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                  obscureText: !showPassword,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,

                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(FluentIcons.password_field, color: Colors.grey[100]),
              const SizedBox(width: 10),
              Expanded(
                child: ParcotoTextBox(
                  controller: passwordConfirm,
                  placeholder: 'confirmation'.tr(),
                  enabled: widget.user == null,
                  suffix: IconButton(
                    icon: Icon(
                      showPasswordConfirm
                          ? FluentIcons.hide
                          : FluentIcons.red_eye,
                      color: !showPasswordConfirm
                          ? appTheme.color
                          : Colors.grey[100],
                      size: 12.sp,
                    ),
                    onPressed: () {
                      setState(() {
                        showPasswordConfirm = !showPasswordConfirm;
                      });
                    },
                  ),
                  obscureText: !showPasswordConfirm,
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,

                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(FluentIcons.phone, color: Colors.grey[100]),
              const SizedBox(width: 10),
              CountryCodePicker(
                initialSelection: countrySelected,
                onChanged: (c) {
                  setState(() {
                    countrySelected = c.code ?? 'DZ';
                    phoneDial = c.dialCode ?? '+213';
                  });
                  testIfSomethingChanged();
                },
                boxDecoration: BoxDecoration(
                  color: appTheme.backGroundColor,
                  boxShadow: kElevationToShadow[2],
                ),
                dialogSize: countryDialogSize,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: ParcotoTextBox(
                  controller: phone,
                  placeholder: 'telephone'.tr(),
                  maxLength: 9,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
      actions: [
        Button(
          child: const Text('annuler').tr(),
          onPressed: () {
            Navigator.pop(context);
            // Delete file here
          },
        ),
        FilledButton(
          onPressed: uploading || !validEmail || !somethingChanged
              ? null
              : onConfirm,
          child: uploading ? const ProgressBar() : const Text('confirmer').tr(),
        ),
      ],
    );
  }

  bool uploading = false;

  void onConfirm() async {
    if (password.text.length < 8 || password.text != passwordConfirm.text) {
      if (password.text.length < 8) {
        displayInfoBar(
          context,
          builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('general_argument_invalid').tr(),
              severity: InfoBarSeverity.warning,
            );
          },
          duration: snackbarShortDuration,
        );
      } else {
        displayInfoBar(
          context,
          builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('passwordmatch').tr(),
              severity: InfoBarSeverity.warning,
            );
          },
          duration: snackbarShortDuration,
        );
      }
    }

    if (email.text.isNotEmpty &&
        validEmail &&
        somethingChanged &&
        password.text.length >= 8 &&
        passwordConfirm.text == password.text) {
      setState(() {
        uploading = true;
      });
      userID ??=
          widget.user?.$id ??
          DateTime.now()
              .difference(DatabaseGetter.ref)
              .inMilliseconds
              .abs()
              .toString();
      client = Client()
        ..setEndpoint(endpoint)
        ..setProject(project!)
        ..setKey(secretKey!);
      await addUserToUsersList()
          .then((value) async {
            ParcUser newme = ParcUser(
              email: email.text,
              name: name.text.isEmpty ? null : name.text,
              id: userID!,
              tel: phone.text.trim().isEmpty ? null : '$phoneDial${phone.text}',
              avatar: null,
            );
            await uploadUserInDB(newme)
                .then((value) {})
                .then((value) {
                  if (mounted) {
                    displayInfoBar(
                      context,
                      builder: (BuildContext context, void Function() close) {
                        return InfoBar(
                          title: const Text('done').tr(),
                          severity: InfoBarSeverity.success,
                        );
                      },
                      duration: snackbarShortDuration,
                    );
                  }
                })
                .onError((AppwriteException error, stackTrace) {
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
          })
          .onError((AppwriteException error, stackTrace) {
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
            setState(() {
              uploading = false;
            });
          });

      setState(() {
        uploading = false;
      });
    }
  }

  Future<void> uploadUserInDB(ParcUser newme) async {
    if (widget.user == null) {
      await TablesDB(client!)
          .createRow(
            databaseId: databaseId,
            tableId: userid,
            rowId: newme.id,
            permissions: [
              Permission.read(Role.user(newme.id)),
              Permission.update(Role.user(newme.id)),
              Permission.delete(Role.user(newme.id)),
            ],
            data: newme.toJson(),
          )
          .then((value) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
    } else {
      await TablesDB(client!)
          .updateRow(
            databaseId: databaseId,
            tableId: userid,
            rowId: userID!,
            data: newme.toJson(),
          )
          .then((value) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
    }
  }

  bool alreadyAdded = false;

  Client? client;
  Future<void> addUserToUsersList() async {
    if (widget.user == null) {
      await Users(client!).create(
        userId: userID!,
        name: name.text.isEmpty ? null : name.text,
        email: email.text,
        password: password.text,
        phone: phone.text.trim().isEmpty ? null : '$phoneDial${phone.text}',
      );
      DatabaseGetter().ajoutActivity(32, userID!, docName: name.text);
    } else {
      if (widget.user!.name != name.text) {
        await Users(client!)
            .updateName(userId: widget.user!.$id, name: name.text);
      }
      if (widget.user!.phone != '$phoneDial${phone.text}') {
        await Users(client!).updatePhone(
          userId: widget.user!.$id,
          number: '$phoneDial${phone.text}',
        );
      }
      DatabaseGetter().ajoutActivity(33, userID!, docName: name.text);
    }
  }
}
