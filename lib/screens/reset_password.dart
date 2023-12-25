import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../widgets/empty_table_widget.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  TextEditingController passwordConfirmation = TextEditingController();
  TextEditingController password = TextEditingController();

  bool showPassword=false;

  bool done=false;

  bool signedIn=false;

  bool checking=false;

  bool validPassword=false;

  @override
  void initState() {
    adjustSize();
    super.initState();
  }

  void adjustSize(){
    if(kIsWeb){
      pheight=80.h;
    }
    else{
      if(Platform.isAndroid || Platform.isIOS){
        pwidth=80.w;
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


  String get userId => Uri.base.queryParameters['userId'] ?? '';
  String get projectId => Uri.base.queryParameters['projectid'] ?? '';
  String get endpointU => Uri.base.queryParameters['endpoint'] ?? '';

  String get secret => Uri.base.queryParameters['secret'] ?? '';

  @override
  Widget build(BuildContext context) {
    if(MediaQuery.of(context).orientation==Orientation.portrait){
      pwidth=60.w;
    }
    else{
      pwidth=30.w;
    }
    var appTheme = context.watch<AppTheme>();
    if(done){
      return NoDataWidget(
        icon:linknotvalid?FluentIcons.error:FluentIcons.check_mark,
        text:linknotvalid?'linknotvalid':'donepassword',);
    }
    return ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 5.h,),
            Image.asset('assets/images/favIcon.webp',width: 30.w,),
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
                        if(password.text.length<8 || passwordConfirmation.text.length<8 || passwordConfirmation.text!=password.text){
                          setState(() {
                            validPassword=false;
                          });
                        }
                        else{
                          setState(() {
                            validPassword=true;
                          });
                        }
                        confirm();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  SizedBox(
                    width: pwidth,
                    child: TextBox(
                      controller: passwordConfirmation,
                      placeholder: 'confirmation'.tr(),
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
                        if(password.text.length<8 || passwordConfirmation.text.length<8 || passwordConfirmation.text!=password.text){
                          setState(() {
                            validPassword=false;
                          });
                        }
                        else{
                          setState(() {
                            validPassword=true;
                          });
                        }
                        confirm();
                      },
                    ),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  FilledButton(onPressed:checking?null:confirm,
                      child:
                      checking?const ProgressRing(strokeWidth:2.0):
                      const Text('confirmer').tr()),
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
  void confirm() async{
    if(validPassword && endpointU.isNotEmpty && projectId.isNotEmpty && userId.isNotEmpty && secret.isNotEmpty){
      setState(() {
        checking=true;
      });
      Client client=Client()
        ..setEndpoint(endpointU)
        ..setProject(projectId);
      await Account(client).updateRecovery(userId: userId, secret: secret, password: password.text, passwordAgain: passwordConfirmation.text).then((value) async{
        setState(() {
          done=true;
        });
      }).onError<AppwriteException>((e,s){

        error=e.type!.tr();
        setState(() {
          done=false;
        });
      });
    }
    else if(password.text.length<8|| passwordConfirmation.text.length<8){
      setState(() {
        error="general_argument_invalid".tr();
        checking=false;

      });
    }
    else if(passwordConfirmation.text!=password.text){
      setState(() {
        error="passwordmatch".tr();
        checking=false;
      });
    }
    else if(endpointU.isNotEmpty || projectId.isNotEmpty || userId.isNotEmpty || secret.isNotEmpty){
      done=true;
      linknotvalid=true;

      setState(() {

      });
    }

  }

  bool linknotvalid=false;

}
