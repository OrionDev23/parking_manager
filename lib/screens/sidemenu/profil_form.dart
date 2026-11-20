import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/utilities/country_list.dart';
import 'package:parc_oto/utilities/form_validators.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';
import '../../utilities/profil_beautifier.dart';

class ProfilForm extends StatefulWidget {
  final ParcUser? user;

  const ProfilForm({super.key, this.user});

  @override
  State<ProfilForm> createState() => _ProfilFormState();
}

class _ProfilFormState extends State<ProfilForm> {
  late TextEditingController email;
  late TextEditingController name;
  late TextEditingController phone;

  String countrySelected = 'DZ';
  String phoneDial = "+213";

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    userID = widget.user?.id ?? ID.unique();
    email = TextEditingController(text: widget.user?.email);
    validEmail = FormValidators.isEmail(email.text);
    name = TextEditingController(text: widget.user?.name);
    countrySelected = Countries.getCountryCodeFromPhone(widget.user?.tel);
    if (widget.user != null &&
        widget.user!.tel != null &&
        widget.user!.tel!.length > 3) {
      phone = TextEditingController(
        text: widget.user?.tel?.substring(4, widget.user?.tel?.length),
      );
    } else {
      phone = TextEditingController();
    }
  }

  bool somethingChanged = false;
  bool validEmail = false;

  void testIfSomethingChanged() {
    final originalPhone = widget.user?.tel;
    final originalLocalPhone =
        originalPhone != null && originalPhone.length > 3
        ? originalPhone.substring(4)
        : '';

    final hasChanges =
        email.text != widget.user?.email ||
        name.text != widget.user?.name ||
        countrySelected != Countries.getCountryCodeFromPhone(originalPhone) ||
        phone.text != originalLocalPhone;

    if (hasChanges != somethingChanged && mounted) {
      setState(() => somethingChanged = hasChanges);
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    final screenSize = MediaQuery.sizeOf(context);
    final avatarSize = screenSize.width < 640 ? 72.0 : 96.0;
    final countryDialogSize = Size(
      (screenSize.width - 32).clamp(280.0, 520.0).toDouble(),
      (screenSize.height - 80).clamp(320.0, 600.0).toDouble(),
    );
    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: (screenSize.width - 32).clamp(280.0, 520.0).toDouble(),
        maxHeight: (screenSize.height - 48).clamp(320.0, 720.0).toDouble(),
      ),
      title: const Text('Profil'),
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
                    ParcOtoUtilities.getFirstLetters(widget.user).toUpperCase(),
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
    if (email.text.isNotEmpty && validEmail && somethingChanged) {
      setState(() {
        uploading = true;
      });
      ParcUser newme = ParcUser(
        email: email.text,
        name: name.text,
        id: userID,
        tel: '$phoneDial${phone.text}',
        avatar: null,
      );
      if (widget.user == null) {
        await DatabaseGetter.database!
            .createRow(
              databaseId: databaseId,
              tableId: userid,
              rowId: userID,
              data: newme.toJson(),
              permissions: [
                Permission.read(Role.user(userID)),
                Permission.update(Role.user(userID)),
                Permission.delete(Role.user(userID)),
              ],
            )
            .then((value) {
              DatabaseGetter.me.value = newme;
              if (mounted) {
                Navigator.pop(context);
              }
            });
      } else {
        await DatabaseGetter.database!
            .updateRow(
              databaseId: databaseId,
              tableId: userid,
              rowId: userID,
              data: newme.toJson(),
            )
            .then((value) {
              DatabaseGetter.me.value = newme;
              if (mounted) {
                Navigator.pop(context);
              }
            });
      }

      setState(() {
        uploading = false;
      });
    }
  }

  late String userID;
}
