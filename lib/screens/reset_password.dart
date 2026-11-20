import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';

import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
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

  bool showPassword = false;

  bool done = false;

  bool signedIn = false;

  bool checking = false;

  bool validPassword = false;

  String get userId => Uri.base.queryParameters['userId'] ?? '';

  String get projectId => Uri.base.queryParameters['projectid'] ?? '';

  String get endpointU => Uri.base.queryParameters['endpoint'] ?? '';

  String get secret => Uri.base.queryParameters['secret'] ?? '';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final compact = screenSize.width < 640;
    final formWidth = (screenSize.width - 32).clamp(0.0, 460.0).toDouble();
    final appTheme = context.watch<AppTheme>();

    if (done) {
      return NoDataWidget(
        icon: linknotvalid ? FluentIcons.error : FluentIcons.check_mark,
        text: linknotvalid ? 'linknotvalid' : 'donepassword',
      );
    }

    return ScaffoldPage(
      content: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 20 : 36,
            ),
            child: Center(
              child: SizedBox(
                width: formWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/favIcon.webp',
                      width: compact ? 112 : 144,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: appTheme.mode == ThemeMode.dark
                            ? Colors.grey
                            : Colors.white,
                        boxShadow: kElevationToShadow[2],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ParcotoTextBox(
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
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                              obscureText: !showPassword,
                              onSubmitted: (_) {
                                _validatePassword();
                                confirm();
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ParcotoTextBox(
                              controller: passwordConfirmation,
                              placeholder: 'confirmation'.tr(),
                              suffix: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? FluentIcons.hide
                                      : FluentIcons.red_eye,
                                  color: !showPassword
                                      ? appTheme.color
                                      : Colors.grey[100],
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showPassword = !showPassword;
                                  });
                                },
                              ),
                              obscureText: !showPassword,
                              onSubmitted: (_) {
                                _validatePassword();
                                confirm();
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: FilledButton(
                              onPressed: checking ? null : confirm,
                              child: checking
                                  ? const ProgressRing(strokeWidth: 2)
                                  : const Text('confirmer').tr(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!signedIn && error.isNotEmpty)
                      Text(error, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _validatePassword() {
    validPassword = password.text.length >= 8 &&
        passwordConfirmation.text.length >= 8 &&
        passwordConfirmation.text == password.text;
    if (mounted) setState(() {});
  }

  String error = "";

  void confirm() async {
    if (validPassword &&
        endpointU.isNotEmpty &&
        projectId.isNotEmpty &&
        userId.isNotEmpty &&
        secret.isNotEmpty) {
      setState(() {
        checking = true;
      });
      Client client = Client()
        ..setEndpoint(endpointU)
        ..setProject(projectId);
      await Account(client)
          .updateRecovery(
            userId: userId,
            secret: secret,
            password: password.text,
          )
          .then((value) async {
            setState(() {
              done = true;
            });
          })
          .onError<AppwriteException>((e, s) {
            error = e.type!.tr();
            setState(() {
              done = false;
            });
          });
    } else if (password.text.length < 8 ||
        passwordConfirmation.text.length < 8) {
      setState(() {
        error = "general_argument_invalid".tr();
        checking = false;
      });
    } else if (passwordConfirmation.text != password.text) {
      setState(() {
        error = "passwordmatch".tr();
        checking = false;
      });
    } else if (endpointU.isNotEmpty ||
        projectId.isNotEmpty ||
        userId.isNotEmpty ||
        secret.isNotEmpty) {
      done = true;
      linknotvalid = true;

      setState(() {});
    }
  }

  bool linknotvalid = false;
}
