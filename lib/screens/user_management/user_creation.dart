import 'package:country_code_picker/country_code_picker.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
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
          text: widget.user?.phone.substring(4, widget.user?.phone.length));
    } else {
      phone = TextEditingController();
    }
  }

  void testIfSomethingChanged() {
    if (email.text != widget.user?.email) {
      setState(() {
        somethingChanged = true;
      });
      return;
    } else if (name.text != widget.user?.name) {
      setState(() {
        somethingChanged = true;
      });
      return;
    } else if (password.text != widget.user?.password) {
      setState(() {
        somethingChanged = true;
      });
      return;
    } else if (countrySelected !=
        Countries.getCountryCodeFromPhone(widget.user?.phone)) {
      setState(() {
        somethingChanged = true;
      });
    } else if (widget.user?.phone.substring(4, widget.user?.phone.length) !=
        phone.text) {
      setState(() {
        somethingChanged = true;
      });
    } else if (somethingChanged) {
      setState(() {
        somethingChanged = false;
      });
    }
  }

  bool somethingChanged = false;
  bool validEmail = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ContentDialog(
      title: Text(widget.user != null
          ? widget.user!.name.isNotEmpty
              ? widget.user!.name
              : widget.user!.email
          : 'newuser'.tr()),
      content: Column(
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
                    width: 15.h,
                    height: 15.h,
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
                          ? ParcOtoUtilities.getFirstLetters(ParcUser(
                                  id: '',
                                  email: widget.user!.email,
                                  name: widget.user!.name))
                              .toUpperCase()
                          : '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18.sp),
                    )),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          InfoLabel(
            label: validEmail ? '' : 'entervalidemail'.tr(),
            labelStyle: TextStyle(color: Colors.red, fontSize: 12.sp),
            child: Row(
              children: [
                Icon(
                  FluentIcons.mail,
                  color: Colors.grey[100],
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: TextBox(
                    controller: email,
                    placeholder: 'email'.tr(),
                    enabled: widget.user == null,
                    onChanged: (s) {
                      if (FormValidators.isEmail(s)) {
                        validEmail = true;
                      } else {
                        validEmail = false;
                      }
                      setState(() {});
                      if (validEmail) {
                        testIfSomethingChanged();
                      }
                    },
                    placeholderStyle: placeStyle,
                    cursorColor: appTheme.color.darker,
                    style: appTheme.writingStyle,
                    decoration: BoxDecoration(
                      color: appTheme.fillColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              Icon(
                FluentIcons.i_d_badge,
                color: Colors.grey[100],
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextBox(
                  controller: name,
                  placeholder: 'nom'.tr(),
                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                  placeholderStyle: placeStyle,
                  cursorColor: appTheme.color.darker,
                  style: appTheme.writingStyle,
                  decoration: BoxDecoration(
                    color: appTheme.fillColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              Icon(
                FluentIcons.password_field,
                color: Colors.grey[100],
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextBox(
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
                  decoration: BoxDecoration(
                    color: appTheme.fillColor,
                  ),
                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              Icon(
                FluentIcons.password_field,
                color: Colors.grey[100],
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextBox(
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
                  decoration: BoxDecoration(
                    color: appTheme.fillColor,
                  ),
                  onChanged: (s) {
                    testIfSomethingChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              Icon(
                FluentIcons.phone,
                color: Colors.grey[100],
              ),
              const SizedBox(
                width: 10,
              ),
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
                    boxShadow: kElevationToShadow[2]),
                dialogSize: Size(40.w, 45.h),
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                  child: TextBox(
                controller: phone,
                placeholder: 'telephone'.tr(),
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (s) {
                  testIfSomethingChanged();
                },
                placeholderStyle: placeStyle,
                cursorColor: appTheme.color.darker,
                style: appTheme.writingStyle,
                decoration: BoxDecoration(
                  color: appTheme.fillColor,
                ),
              )),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('annuler').tr(),
          onPressed: () {
            Navigator.pop(
              context,
            );
            // Delete file here
          },
        ),
        FilledButton(
            onPressed: uploading || !validEmail || !somethingChanged
                ? null
                : onConfirm,
            child:
                uploading ? const ProgressBar() : const Text('confirmer').tr()),
      ],
    );
  }

  bool uploading = false;

  void onConfirm() async {

    if(password.text.length<8 || password.text!=passwordConfirm.text){
      if(password.text.length<8){
        displayInfoBar(context,
            builder: (BuildContext context, void Function() close) {
              return InfoBar(
                title: const Text('general_argument_invalid').tr(),
                severity: InfoBarSeverity.warning,
              );
            }, duration: snackbarShortDuration);
      }
      else{
        displayInfoBar(context,
            builder: (BuildContext context, void Function() close) {
              return InfoBar(
                title: const Text('passwordmatch').tr(),
                severity: InfoBarSeverity.warning,
              );
            }, duration: snackbarShortDuration);
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
      userID ??= widget.user?.$id ?? DateTime.now().difference(DatabaseGetter
          .ref)
          .inMilliseconds.abs().toString();
      client = Client()
        ..setEndpoint(endpoint)
        ..setProject(project)
        ..setKey(secretKey);
      await addUserToUsersList().then((value) async {
        ParcUser newme = ParcUser(
          email: email.text,
          name: name.text.isEmpty?null:name.text,
          id: userID!,
          tel: phone.text.trim().isEmpty?null:'$phoneDial${phone.text}',
          avatar: null,
        );
        await uploadUserInDB(newme).then((value) {}).then((value) {
          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('done').tr(),
              severity: InfoBarSeverity.success,
            );
          }, duration: snackbarShortDuration);
        }).onError(( AppwriteException error, stackTrace) {

          displayInfoBar(context,
              builder: (BuildContext context, void Function() close) {
            return InfoBar(
              title: const Text('echec').tr(),
              severity: InfoBarSeverity.error,
            );
          }, duration: snackbarShortDuration);
        });
      }).onError((AppwriteException error, stackTrace) {

        displayInfoBar(context,
            builder: (BuildContext context, void Function() close) {
          return InfoBar(
            title: const Text('echec').tr(),
            severity: InfoBarSeverity.error,
          );
        }, duration: snackbarShortDuration);
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
      await Databases(client!).createDocument(
              databaseId: databaseId,
              collectionId: userid,
              documentId: newme.id,
              permissions: [
                Permission.update(Role.user(newme.id)),
                Permission.delete(Role.user(newme.id)),
                Permission.write(Role.user(newme.id)),
              ],
              data: newme.toJson())
          .then((value) {
        Navigator.pop(
          context,
        );
      });
    } else {
      await Databases(client!)
          .updateDocument(
              databaseId: databaseId,
              collectionId: userid,
              documentId: userID!,
              data: newme.toJson())
          .then((value) {
        Navigator.pop(
          context,
        );
      });
    }
  }

  bool alreadyAdded = false;

  Client? client;
  Future<void> addUserToUsersList() async {

    if (widget.user == null) {
      await Users(client!).create(
          userId: userID!,
          name: name.text.isEmpty?null:name.text,
          email: email.text,
          password: password.text,
        phone: phone.text.trim().isEmpty?null:'$phoneDial${phone.text}',

      );
      DatabaseGetter().ajoutActivity(32, userID!, docName: name.text);
    } else {
      if (widget.user!.name != name.text) {
        await Users(client!)
            .updateName(userId: widget.user!.$id, name: name.text);
      }
      if (widget.user!.phone != '$phoneDial${phone.text}') {
        await Users(client!).updatePhone(
            userId: widget.user!.$id, number: '$phoneDial${phone.text}');
      }
      DatabaseGetter().ajoutActivity(33, userID!, docName: name.text);
    }
  }
}
