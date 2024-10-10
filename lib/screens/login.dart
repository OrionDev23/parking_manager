import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
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

import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key,});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with AutomaticKeepAliveClientMixin{
  TextEditingController projectName = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool showPassword = false;

  bool signedIn = false;

  bool checking = false;

  bool validEmail = false;
  bool validPassword = false;

  @override
  void initState() {
    projectName.text=prefs.getString('project')??'';
    waitForFirstLoading();
    super.initState();
  }

  void waitForFirstLoading() async {
    while (PanesListState.firstLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if(DatabaseGetter.user == null){
      checkUser();
    }

  }

  void checkUser() async {
    checking = true;
    await DatabaseGetter().getUser();
    if (DatabaseGetter.user != null) {
      PanesListState.signedIn.value = true;
    }
    checking = false;
    if (mounted) {
      setState(() {});
    }
  }

  double pwidth = 300.px;
  double pheight = 250.px;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (PanesListState.firstLoading) {
      return const Center(child: ProgressRing());
    }    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'connexion'.tr(),
      ),
      content: Center(
        child: PanesListState.firstLoading
            ? const ProgressRing()
            : Column(
                children: [
                  bigSpace,
                  bigSpace,
                  Image.asset(
                    'assets/images/logo.webp',
                    width: 300.px,
                  ),
                  bigSpace,
                  bigSpace,
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          width: pwidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: appTheme.backGroundColor,
                            boxShadow: kElevationToShadow[3],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: pwidth,
                                child: TextBox(
                                  prefix: Padding(
                                    padding: const EdgeInsets.fromLTRB(8,5,
                                        5,5),
                                    child: Icon(FluentIcons.external_build,size:14.px,
                                      color:
                                      Colors.grey[100],),
                                  ),
                                  controller: projectName,
                                  placeholder: 'entreprise'.tr(),
                                ),
                              ),
                              bigSpace,
                              const Divider(),
                              SizedBox(
                                width: pwidth,
                                child: InfoLabel(
                                  label: validEmail || email.text.isEmpty
                                      ? ''
                                      : 'entervalidemail'.tr(),
                                  labelStyle: TextStyle(color: Colors.red),
                                  child: TextBox(
                                    prefix: Padding(
                                      padding: const EdgeInsets.fromLTRB(8,5,
                                        5,5),
                                      child: Icon(FluentIcons.mail,size:14.px,
                                        color:
                                      Colors.grey[100],),
                                    ),
                                    controller: email,
                                    placeholder: 'email'.tr(),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (s) {
                                      if (!FormValidators.isEmail(s)) {
                                        setState(() {
                                          validEmail = false;
                                        });
                                      } else {
                                        setState(() {
                                          validEmail = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              bigSpace,
                              SizedBox(
                                width: pwidth,
                                child: TextBox(
                                  prefix: Padding(
                                    padding: const EdgeInsets.fromLTRB(8,5,
                                        5,5),
                                    child: Icon(FluentIcons.lock,size:14.px,
                                      color:
                                    Colors.grey[100],),
                                  ),
                                  controller: password,
                                  placeholder: 'motdepasse'.tr(),
                                  suffix: IconButton(
                                    icon: Icon(
                                      showPassword
                                          ? FluentIcons.hide
                                          : FluentIcons.red_eye,
                                      color: !showPassword
                                          ? appTheme.color
                                          : Colors.grey[100],
                                      size: 13.px,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                  ),
                                  obscureText: !showPassword,
                                  onSubmitted: (s) {
                                    signIn();
                                  },
                                ),
                              ),
                              bigSpace,
                              smallSpace,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OnTapScaleAndFade(
                                      onTap: forgotPassword,
                                      child: Text(
                                        'forgot',
                                        style: TextStyle(color: appTheme.color),
                                      ).tr()),
                                ],
                              ),
                              bigSpace,
                              smallSpace,

                              FilledButton(
                                  onPressed: checking ? null : signIn,
                                  child: checking
                                      ? const ProgressRing(strokeWidth: 2.0)
                                      : const Text('seconnecter').tr()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 2.h,
                  ),
                  if (!signedIn && error.isNotEmpty)
                    Text(
                      error,
                      style: TextStyle(color: Colors.red),
                    )
                ],
              ),
      ),
    );
  }

  String error = "";

  void signIn() async {
    if (validEmail && password.text.isNotEmpty && projectName.text
      .trim().isNotEmpty) {
      setState(() {
        checking = true;
      });
      project=projectName.text;
      DatabaseGetter();
      Future.delayed(const Duration(milliseconds: 300)).then((value) async{
        await DatabaseGetter.account!.createEmailPasswordSession(
            email: email.text,
            password: password.text)
            .then((value) async {
          prefs.setString('project', projectName.text);
          DatabaseGetter();

          await DatabaseGetter().getUser();
          PanesListState.signedIn.value = true;
          setState(() {
            signedIn = true;
          });
        }).onError<AppwriteException>((e, s) {
          error = e.type!.tr();
          setState(() {
            checking = false;
            signedIn = false;
          });
        });
      });

    } else if (password.text.isEmpty) {
      setState(() {
        error = "emptypassword".tr();
        signedIn = false;
        checking = false;
      });
    }
  }

  void forgotPassword() async {
    if (email.text.isEmpty) {
      setState(() {
        signedIn = false;
        error = "emailempty".tr();
      });
    } else if (validEmail) {
      /*dap.Client client=dap.Client()
      ..setEndpoint(endpoint)
      ..setKey(secretKey)
      ..setProject(project);*/
      await DatabaseGetter.account!
          .createRecovery(
              email: email.text,
              url:
                  'https://app.parcoto.com/recoverpassword?projectid=$project&endpoint=$endpoint')
          .then((e) {
        return e;
      }).onError((AppwriteException error, stackTrace) {
        if (kDebugMode) {
          print('message: ${error.message}');
          print('code: ${error.code}');
          print('response: ${error.response}');
          print('type: ${error.type}');
          print('stacktrace: $stackTrace');
        }

        return Token(
            $id: '', $createdAt: '', userId: '', secret: '', expire: '', phrase: '', );
      });
      setState(() {
        error = "";
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
