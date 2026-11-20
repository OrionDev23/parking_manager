import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' hide Row;
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/utilities/form_validators.dart';

import '../main.dart';
import '../core/tenancy/company_membership_resolver.dart';
import '../core/auth/auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AutomaticKeepAliveClientMixin {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool showPassword = false;

  bool signedIn = false;

  bool checking = false;

  bool validEmail = false;
  bool _emailHasContent = false;

  @override
  void initState() {
    waitForFirstLoading();
    super.initState();
  }

  void waitForFirstLoading() async {
    while (PanesListState.firstLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (authService.session == null) {
      checkUser();
    }
  }

  Future<void> checkUser() async {
    if (checking) return;
    checking = true;
    if (mounted) setState(() {});

    try {
      final session = await authService.restoreSession();
      if (session != null) {
        _activateSession(session);
      }
    } on CompanySelectionRequired catch (selection) {
      final selected = await _promptCompanySelection(selection.memberships);
      if (selected != null) _activateSession(selected);
    } catch (_) {
      PanesListState.signedIn.value = false;
      signedIn = false;
    } finally {
      checking = false;
      if (mounted) setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (PanesListState.firstLoading) return const Center(child: ProgressRing());

    final dark = FluentTheme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF081625);
    const navy2 = Color(0xFF10283A);
    const mint = Color(0xFF55E6C1);
    const teal = Color(0xFF159F83);
    final page = dark ? const Color(0xFF091522) : const Color(0xFFF0F4F5);
    final surface = dark ? const Color(0xFF142438) : Colors.white;
    final foreground = dark ? const Color(0xFFF3F7FA) : const Color(0xFF102235);
    final muted = dark ? const Color(0xFF9BAFBE) : const Color(0xFF71818D);
    final field = dark ? const Color(0xFF0C1B2B) : const Color(0xFFF2F6F6);

    Widget feature(IconData icon, String title, String subtitle) => Row(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withValues(alpha: .12))),
          child: Icon(icon, color: mint, size: 19),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 10)),
        ])),
      ],
    );

    final loginPanel = Container(
      width: MediaQuery.sizeOf(context).width < 560
          ? MediaQuery.sizeOf(context).width - 36
          : 460,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 560 ? 24 : 38,
        MediaQuery.sizeOf(context).width < 560 ? 26 : 38,
        MediaQuery.sizeOf(context).width < 560 ? 24 : 38,
        MediaQuery.sizeOf(context).width < 560 ? 22 : 30,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: .08) : const Color(0xFFE4EAEC)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .28 : .10), blurRadius: 50, offset: const Offset(0, 24))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: mint.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)), child: Icon(FluentIcons.lock, color: teal, size: 17)),
          const SizedBox(width: 11),
          Text('ESPACE SÉCURISÉ', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.7)),
        ]),
        const SizedBox(height: 27),
        Text('Heureux de vous revoir.', style: TextStyle(color: foreground, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.8)),
        const SizedBox(height: 8),
        Text('Connectez-vous pour reprendre le pilotage de votre activité.', style: TextStyle(color: muted, fontSize: 12, height: 1.5)),
        const SizedBox(height: 29),
        _loginFieldLabel('ADRESSE E-MAIL'),
        Container(
          decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.white.withValues(alpha: .08) : const Color(0xFFE2E9EB))),
          child: TextBox(
            controller: email, placeholder: 'vous@entreprise.com', keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              final nextValid = FormValidators.isEmail(value);
              final hasContent = value.isNotEmpty;
              final shouldClearError = error.isNotEmpty;
              if (nextValid != validEmail ||
                  hasContent != _emailHasContent ||
                  shouldClearError) {
                setState(() {
                  validEmail = nextValid;
                  _emailHasContent = hasContent;
                  if (shouldClearError) error = '';
                });
              }
            },
            prefix: Padding(padding: const EdgeInsets.symmetric(horizontal: 13), child: Icon(FluentIcons.mail, size: 15, color: muted)),
            style: TextStyle(color: foreground, fontSize: 13),
          ),
        ),
        if (email.text.isNotEmpty && !validEmail) ...[
           SizedBox(height: 6), Text('entervalidemail'.tr(), style:  TextStyle(color: Colors.red, fontSize: 11)),
        ],
        const SizedBox(height: 19),
        _loginFieldLabel('MOT DE PASSE'),
        Container(
          decoration: BoxDecoration(color: field, borderRadius: BorderRadius.circular(12), border: Border.all(color: dark ? Colors.white.withValues(alpha: .08) : const Color(0xFFE2E9EB))),
          child: TextBox(
            controller: password, placeholder: 'Votre mot de passe', obscureText: !showPassword,
            onSubmitted: (_) => signIn(),
            onChanged: (_) { if (error.isNotEmpty) setState(() => error = ''); },
            prefix: Padding(padding: const EdgeInsets.symmetric(horizontal: 13), child: Icon(FluentIcons.lock, size: 15, color: muted)),
            suffix: IconButton(icon: Icon(showPassword ? FluentIcons.hide : FluentIcons.red_eye, size: 15, color: muted), onPressed: () => setState(() => showPassword = !showPassword)),
            style: TextStyle(color: foreground, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: HyperlinkButton(onPressed: forgotPassword, child: Text('Mot de passe oublié ?', style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.w700)))),
        if (error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withValues(alpha: .2))), child: Row(children: [ Icon(FluentIcons.error, color: Colors.red, size: 15), const SizedBox(width: 9), Expanded(child: Text(error, style:  TextStyle(color: Colors.red, fontSize: 11)))])),
        ],
        const SizedBox(height: 20),
        SizedBox(height: 52, child: FilledButton(
          onPressed: checking ? null : signIn,
          child: checking
              ? const SizedBox(width: 19, height: 19, child: ProgressRing(strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('Accéder à mon espace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), SizedBox(width: 10), Icon(FluentIcons.chevron_right, size: 14)]),
        )),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(FluentIcons.shield, size: 12, color: muted), const SizedBox(width: 7), Text('Vos accès sont protégés', style: TextStyle(color: muted, fontSize: 10))]),
      ]),
    );

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.webp',
          width: 190,
          height: 54,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 8),
        Text(
          'login_brand_tagline'.tr(),
          style: const TextStyle(
            color: Color(0xFF8CA3B6),
            fontSize: 10,
            letterSpacing: .6,
            fontWeight: FontWeight.w700,
          ),
        ),
      const SizedBox(height: 62),
      Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: mint.withValues(alpha: .12), borderRadius: BorderRadius.circular(30), border: Border.all(color: mint.withValues(alpha: .25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(FluentIcons.sync, color: mint, size: 9), const SizedBox(width: 8), Text('login_hero_badge'.tr().toUpperCase(), style: TextStyle(color: mint, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .7))])),
      const SizedBox(height: 23),
      Text('login_hero_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 48, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -2.0)),
      const SizedBox(height: 20),
      Text('login_hero_subtitle'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: .66), fontSize: 14, height: 1.65)),
      const SizedBox(height: 42),
      feature(FluentIcons.car, 'login_feature_fleet'.tr(), 'login_feature_fleet_desc'.tr()),
      const SizedBox(height: 19),
      feature(FluentIcons.chart, 'login_feature_analytics'.tr(), 'login_feature_analytics_desc'.tr()),
      const SizedBox(height: 19),
      feature(FluentIcons.sync, 'login_feature_operations'.tr(), 'login_feature_operations_desc'.tr()),
      const SizedBox(height: 48),
      Row(children: [Container(width: 28, height: 2, color: const Color(0xFFFFB36B)), const SizedBox(width: 10), Text('login_hero_footer'.tr().toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: .48), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8))]),
    ]);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final desktop = constraints.maxWidth >= 1000;

        if (desktop) {
          final content = Row(children: [
            Expanded(
              flex: 11,
              child: Container(
                height: availableHeight,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [navy, Color(0xFF102D3C), Color(0xFF0B1B2B)],
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    right: -150,
                    top: -160,
                    child: Container(
                      width: 570,
                      height: 570,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: mint.withValues(alpha: .10)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -85,
                    top: -95,
                    child: Container(
                      width: 440,
                      height: 440,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: mint.withValues(alpha: .07)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -190,
                    child: Icon(
                      FluentIcons.car,
                      size: 390,
                      color: Colors.white.withValues(alpha: .025),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 570),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: brand,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              flex: 9,
              child: Center(child: loginPanel),
            ),
          ]);

          return Container(
            width: double.infinity,
            height: availableHeight,
            color: page,
            child: content,
          );
        }

        final mobileContent = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.webp',
              width: 158,
              height: 46,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            Text(
              'login_brand_tagline'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8CA3B6),
                fontSize: 9,
                letterSpacing: .3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            loginPanel,
          ],
        );

        return Container(
          width: double.infinity,
          height: availableHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [navy, navy2, page],
              stops: const [0, .38, .38],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: availableHeight,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (availableHeight - 24).clamp(0.0, double.infinity).toDouble(),
                  ),
                  child: mobileContent,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _loginFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  String error = "";

  Future<void> signIn() async {
    if (validEmail && password.text.isNotEmpty) {
      setState(() {
        checking = true;
        error = '';
      });

      try {
        final session = await authService.signIn(
          email: email.text,
          password: password.text,
        );
        _activateSession(session);
      } on CompanySelectionRequired catch (selection) {
        final selected = await _promptCompanySelection(selection.memberships);
        if (selected != null) _activateSession(selected);
      } on AppwriteException catch (e) {
        error = e.type?.tr() ?? e.message ?? 'connexionerror'.tr();
        signedIn = false;
      } catch (e) {
        error = e.toString();
        signedIn = false;
      } finally {
        checking = false;
        if (mounted) setState(() {});
      }
    } else {
      setState(() {
        error = password.text.isEmpty
            ? "emptypassword".tr()
            : 'entervalidemail'.tr();
        signedIn = false;
        checking = false;
      });
    }
  }


  void _activateSession(AuthSession session) {
    PanesListState.signedIn.value = true;
    signedIn = true;
    if (!session.isPlatformSuperAdmin) {
      startBackgroundInitialization(session.company.companyId);
    }
    if (mounted) setState(() {});
  }

  Future<AuthSession?> _promptCompanySelection(
    List<CompanyMembership> memberships,
  ) async {
    if (!mounted || memberships.isEmpty) return null;
    final selected = await showDialog<CompanyMembership>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Choisir une entreprise'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ce compte a accès à plusieurs entreprises. Sélectionnez celle à ouvrir.'),
              const SizedBox(height: 12),
              ...memberships.map((membership) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Button(
                  onPressed: () => Navigator.of(dialogContext).pop(membership),
                  child: Row(children: [
                    const Icon(FluentIcons.company_directory),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(membership.companyName),
                        Text(
                          '${membership.companySlug} • ${membership.role}',
                          style: FluentTheme.of(dialogContext).typography.caption,
                        ),
                      ],
                    )),
                    const Icon(FluentIcons.chevron_right),
                  ]),
                ),
              )),
            ],
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (selected == null) {
      await authService.signOut();
      return null;
    }
    return authService.selectCompany(selected.companyId);
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
                'https://app.parcoto.com/recoverpassword?projectid=$project&endpoint=$endpoint',
          )
          .then((e) {
            return e;
          })
          .onError((AppwriteException error, stackTrace) {
            if (kDebugMode) {
              print('message: ${error.message}');
              print('code: ${error.code}');
              print('response: ${error.response}');
              print('type: ${error.type}');
              print('stacktrace: $stackTrace');
            }

            return Token(
              $id: '',
              $createdAt: '',
              userId: '',
              secret: '',
              expire: '',
              phrase: '',
            );
          });
      setState(() {
        error = "";
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
