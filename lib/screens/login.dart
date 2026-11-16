import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';
import 'package:appwrite/models.dart' hide Row;
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
  bool validPassword = false;

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

  double pwidth = 300.px;
  double pheight = 250.px;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (PanesListState.firstLoading) {
      return const Center(child: ProgressRing());
    }

    final appTheme = context.watch<AppTheme>();
    final fluent = FluentTheme.of(context);
    final isDark = fluent.brightness == Brightness.dark;
    final accent = appTheme.color;
    final foreground = appTheme.textColor;
    final muted = appTheme.mutedTextColor;
    final surface = appTheme.surfaceColor;
    final background = appTheme.backGroundColor;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final compact = constraints.maxWidth < 560;
          final panel = Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 24 : 42,
              vertical: compact ? 28 : 40,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: fluent.inactiveColor.withValues(alpha: .14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? .22 : .07),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!wide) ...[
                  Center(
                    child: Image.asset(
                      'assets/images/logo.webp',
                      width: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
                Text(
                  'Bienvenue sur Parcoto',
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 25 : 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous pour accéder à votre espace de gestion.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                _loginFieldLabel('Adresse e-mail'),
                ParcotoTextBox(
                  controller: email,
                  placeholder: 'nom@entreprise.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      validEmail = FormValidators.isEmail(value);
                      if (error.isNotEmpty) error = '';
                    });
                  },
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      FluentIcons.mail,
                      size: 16,
                      color: muted,
                    ),
                  ),
                  style: TextStyle(color: foreground, fontSize: 13),
                ),
                if (email.text.isNotEmpty && !validEmail) ...[
                  const SizedBox(height: 6),
                  Text(
                    'entervalidemail'.tr(),
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 20),
                _loginFieldLabel('Mot de passe'),
                ParcotoTextBox(
                  controller: password,
                  placeholder: 'Saisissez votre mot de passe',
                  obscureText: !showPassword,
                  onSubmitted: (_) => signIn(),
                  onChanged: (_) {
                    if (error.isNotEmpty) setState(() => error = '');
                  },
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      FluentIcons.lock,
                      size: 16,
                      color: muted,
                    ),
                  ),
                  suffix: IconButton(
                    icon: Icon(
                      showPassword ? FluentIcons.hide : FluentIcons.red_eye,
                      size: 15,
                      color: muted,
                    ),
                    onPressed: () => setState(() {
                      showPassword = !showPassword;
                    }),
                  ),
                  style: TextStyle(color: foreground, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: HyperlinkButton(
                    onPressed: forgotPassword,
                    child: Text(
                      'forgot'.tr(),
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: .22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(FluentIcons.error, color: Colors.red, size: 15),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: checking ? null : signIn,
                    child: checking
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: ProgressRing(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(FluentIcons.arrow_right, size: 14),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.shield, size: 13, color: muted),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Connexion sécurisée à votre espace professionnel',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final content = Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 36,
                vertical: 28,
              ),
              child: wide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 54),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.webp',
                                    width: 230,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 54),
                                  Text(
                                    'Pilotez votre activité.\nGardez le contrôle.',
                                    style: TextStyle(
                                      color: foreground,
                                      fontSize: 38,
                                      height: 1.16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'La gestion de votre parking, de vos véhicules et de vos opérations réunie dans un seul espace.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 15,
                                      height: 1.65,
                                    ),
                                  ),
                                  const SizedBox(height: 34),
                                  _loginFeature(FluentIcons.car, 'Gestion des véhicules et des conducteurs', accent, foreground, muted),
                                  const SizedBox(height: 16),
                                  _loginFeature(FluentIcons.chart, 'Suivi de l’activité et des performances', accent, foreground, muted),
                                  const SizedBox(height: 16),
                                  _loginFeature(FluentIcons.sync, 'Vos données synchronisées en toute sécurité', accent, foreground, muted),
                                ],
                              ),
                            ),
                          ),
                        ),
                        panel,
                      ],
                    )
                  : panel,
            ),
          );

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        background,
                        Color.lerp(background, accent, .075)!,
                        background,
                      ]
                    : [
                        background,
                        Color.lerp(background, accent, .035)!,
                        background,
                      ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -150,
                  right: -110,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: isDark ? .055 : .045),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -210,
                  left: -120,
                  child: Container(
                    width: 480,
                    height: 480,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: isDark ? .04 : .03),
                    ),
                  ),
                ),
                content,
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 12,
                  child: Text(
                    'PARCOTO  •  © ${DateTime.now().year}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted.withValues(alpha: .7),
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _loginFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _loginFeature(
    IconData icon,
    String label,
    Color accent,
    Color foreground,
    Color muted,
  ) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: accent),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: foreground.withValues(alpha: .9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
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
    } else if (password.text.isEmpty) {
      setState(() {
        error = "emptypassword".tr();
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
  bool get wantKeepAlive => true;
}
