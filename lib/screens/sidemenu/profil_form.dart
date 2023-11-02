import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
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


  @override
  void initState() {
    initValues();
    super.initState();
  }


  void initValues(){
    email=TextEditingController(text:widget.user?.email);
    validEmail=FormValidators.isEmail(email.text);
    name=TextEditingController(text: widget.user?.name);
    countrySelected=Countries.getCountryCodeFromPhone(widget.user?.tel);
    phone=TextEditingController(text: widget.user?.tel?.substring(4,widget.user?.tel?.length));
  }

  bool somethingChanged=false;
  bool validEmail=false;

  void testIfSomethingChanged(){
    if(email.text!=widget.user?.email){
      setState(() {
        somethingChanged=true;
      });
      return;
    }
    else if(name.text!=widget.user?.name){
      setState(() {
        somethingChanged=true;
      });
      return;
    }
    else if(countrySelected!=Countries.getCountryCodeFromPhone(widget.user?.tel)){
      setState(() {
        somethingChanged=true;
      });
    }
    else if(widget.user?.tel?.substring(4,widget.user?.tel?.length)!=phone.text){
      setState(() {
        somethingChanged=true;
      });
    }
    else if(imageFile!=null){
      setState(() {
        somethingChanged=true;
      });
    }
    else if(somethingChanged){
      setState(() {
        somethingChanged=false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ContentDialog(
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
                  child:
                      imageFile==null?
                      widget.user!=null && widget.user!.avatar!=null && widget.user!.avatar!.isEmpty?
                      CachedNetworkImage(imageUrl: widget.user!.avatar!,fit: BoxFit.cover,)
                          :Text(
                        ProfilUtilitis.getFirstLetters(widget.user).toUpperCase(),
                        style:  TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18.sp
                        ),
                      )
                          :Image.file(imageFile!,fit: BoxFit.cover,),

                ),
              ),
              const SizedBox(width: 10,),
              IconButton(icon: Icon(FluentIcons.edit,size: 14.sp,color: appTheme.color,), onPressed: pickAvatar),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          InfoLabel(
            label: validEmail?'':'entervalidemail'.tr(),
            labelStyle: TextStyle(color: Colors.red,fontSize: 12.sp),
            child: Row(
              children: [
                Icon(FluentIcons.mail,color: Colors.grey[100],),
                const SizedBox(width: 10,),
                Expanded(
                  child: TextBox(
                    controller: email,
                    placeholder: 'email'.tr(),
                    onChanged: (s){
                      if(FormValidators.isEmail(s)){
                          validEmail=true;
                      }
                      else{
                        validEmail=false;
                      }
                      setState(() {
                      });
                      if(validEmail){
                        testIfSomethingChanged();
                      }
                    },
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
              Icon(FluentIcons.i_d_badge,color: Colors.grey[100],),
              const SizedBox(width: 10,),
              Expanded(
                child: TextBox(
                  controller: name,
                  placeholder: 'nom'.tr(),
                  onChanged: (s){
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
              Icon(FluentIcons.phone,color: Colors.grey[100],),
              const SizedBox(width: 10,),
              CountryCodePicker(
                  initialSelection: countrySelected,
                  onChanged: (c) {
                    setState(() {
                      countrySelected = c.code ?? 'DZ';
                    });
                    testIfSomethingChanged();
                  },
                  boxDecoration: BoxDecoration(
                    color: appTheme.mode == ThemeMode.dark
                        ? Colors.grey
                        : appTheme.mode == ThemeMode.light
                        ? Colors.white
                        : ThemeMode.system == ThemeMode.light
                        ? Colors.white
                        : Colors.grey,
                    backgroundBlendMode: BlendMode.difference,
                    boxShadow: kElevationToShadow[2]
                  ),
                  dialogSize: Size(40.w,45.h),

                  ),
              const SizedBox(
                width: 5,
              ),
              Expanded(child:
              TextBox(
                controller: phone,
                placeholder: 'telephone'.tr(),
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (s){
                  testIfSomethingChanged();
                },
              )),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('annuler').tr(),
          onPressed: () {
            Navigator.pop(context,);
            // Delete file here
          },
        ),
        FilledButton(
          onPressed: !validEmail||!somethingChanged?null:onConfirm,
          child: const Text('confirmer').tr()
        ),
      ],
    );
  }

  void onConfirm(){
    if(validEmail&&somethingChanged){

    }

  }

  File? imageFile;

  void pickAvatar()async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if(result!=null){
      imageFile=File(result.files.single.path!);
      testIfSomethingChanged();
    }
    else{

    }
  }
}
