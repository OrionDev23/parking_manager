import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as dap;
import 'package:dart_appwrite/models.dart' as dam;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/utilities/form_validators.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool showPassword=false;

  bool signedIn=false;

  bool checking=false;

  bool validEmail=false;
  bool validPassword=false;

  @override
  void initState() {
    adjustSize();
    checkUser();
    super.initState();
  }

  void checkUser() async{
    checking=true;
    await ClientDatabase().getUser();
    if(ClientDatabase.user!=null){
      PanesListState.signedIn.value=true;
    }
    setState(() {
      checking=false;
    });
  }

  void adjustSize(){
    if(kIsWeb){
      pheight=50.h;
    }
    else{
      if(Platform.isAndroid || Platform.isIOS){
        pwidth=60.w;
        pheight=50.h;
      }
      else{
        pwidth=20.w;
        pheight=35.h;
      }
    }
  }

  double pwidth=20.w;
  double pheight=35.h;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(text: 'connexion'.tr(),),
      content: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 5.h,),
              Image.asset('assets/images/logo.webp',width: 30.w,),
              SizedBox(height: 5.h,),
              Container(
                padding: const EdgeInsets.all(10),
                alignment: Alignment.center,
                width: pwidth,
                height: pheight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: appTheme.mode == ThemeMode.dark
                      ? Colors.grey
                      : appTheme.mode == ThemeMode.light
                      ? Colors.white
                      : ThemeMode.system == ThemeMode.light
                      ? Colors.white
                      : Colors.grey,
                  boxShadow: kElevationToShadow[2],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: pwidth,
                      child: InfoLabel(

                        label: validEmail||email.text.isEmpty?'':'entervalidemail'.tr(),
                        labelStyle: TextStyle(color:Colors.red),
                        child: TextBox(
                          controller: email,
                          placeholder: 'email'.tr(),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (s){
                           if(!FormValidators.isEmail(s)){
                             setState(() {
                               validEmail=false;
                             });
                           }
                           else{
                             setState(() {
                               validEmail=true;

                             });
                           }
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    SizedBox(
                      width: pwidth,
                      child: TextBox(
                        controller: password,
                        placeholder: 'motdepasse'.tr(),
                        suffix: IconButton(
                          icon: Icon(
                            showPassword?FluentIcons.hide
                            :FluentIcons.red_eye,
                            color: !showPassword?
                            appTheme.color
                            :Colors.grey[100]
                            ,size: 12.sp,), onPressed: (){
                                setState(() {
                                  showPassword=!showPassword;
                                });
                        },),
                        obscureText: !showPassword,
                        onSubmitted: (s){
                          signIn();
                        },
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OnTapScaleAndFade(

                            onTap: forgotPassword,
                            child: Text('forgot',style: TextStyle(color: Colors.blue),).tr()),
                      ],
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    FilledButton(onPressed:checking?null:signIn,
                        child:
                        checking?const ProgressRing(strokeWidth:2.0):
                        const Text('seconnecter').tr()),

                  ],
                ),
              ),
              SizedBox(height: 2.h,),
              if(!signedIn && error.isNotEmpty)
              Text(
                error,
                style: TextStyle(color: Colors.red),
              )
            ],
          ),
      ),
    );
  }

  String error="";
  void signIn() async{
    if(validEmail && password.text.isNotEmpty){
      await ClientDatabase.account!.createEmailSession(
          email: email.text,
          password: password.text).then((value) async{
        await ClientDatabase().getUser();
        PanesListState.signedIn.value=true;
        setState(() {
          signedIn=true;
        });
      }).onError<AppwriteException>((e,s){

        error=e.type!.tr();
        setState(() {
          signedIn=false;
        });
      });
    }
    else if(password.text.isEmpty){
        setState(() {
          error="emptypassword".tr();
          signedIn=false;
        });
    }

}


  void forgotPassword() async{
    if(email.text.isEmpty) {
      setState(() {
        signedIn=false;
        error="emailempty".tr();
      });
    }
    else if(validEmail){
      dap.Client client=dap.Client()
      ..setEndpoint(endpoint)
      ..setKey(readKey)
        ..setSelfSigned(status: true)
      ..setProject(project);
      await dap.Account(client).createRecovery(email: email.text,
          url:'https://app.parcoto.com/recoverpassword?projectid=$project&endpoint=$endpoint').onError((AppwriteException error, stackTrace) {
            print(error.message);
            print(error.response);
            print(stackTrace);
            return dam.Token($id: '', $createdAt: '', userId: '', secret: '', expire: '');
      });
      setState(() {
        error="";
      });
    }

  }
}
