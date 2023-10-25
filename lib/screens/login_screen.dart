import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
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
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: const PageTitle(text: 'Connexion',),
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
                width: 25.w,
                height: 30.h,
                decoration: BoxDecoration(
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
                      width: 20.w,
                      child: TextBox(
                        controller: email,
                        placeholder: 'email'.tr(),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    SizedBox(
                      width: 20.w,
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
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Button(
                            style:ButtonStyle(
                              border: ButtonState.all<BorderSide>(BorderSide.none),
                                backgroundColor: ButtonState.all<Color>(Colors.transparent)

                            ),
                            onPressed: (){},
                            child: Text('Mot de passe oublié ?',style: TextStyle(color: Colors.blue),)),
                      ],
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    FilledButton(onPressed: () {}, child: const Text('Se connecter')),

                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}
