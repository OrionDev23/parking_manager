import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../widgets/page_header.dart';
import '../main.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool loginOut = false;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(text: 'deconnexion'.tr()),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth =
              (constraints.maxWidth - 32).clamp(280.0, 440.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32)
                    .clamp(0.0, double.infinity),
              ),
              child: Center(
                child: SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: appTheme.surfaceColor,
                      border: Border.all(color: appTheme.borderColor),
                      boxShadow: [appTheme.surfaceShadow],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FluentIcons.sign_out,
                          size: 34,
                          color: appTheme.color,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'disconnectconfirm',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ).tr(),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            Button(
                              onPressed: loginOut ? null : cancel,
                              child: const Text('non').tr(),
                            ),
                            FilledButton(
                              onPressed: loginOut ? null : logout,
                              child: loginOut
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: ProgressRing(strokeWidth: 2),
                                    )
                                  : const Text('oui').tr(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> logout() async {
    setState(() {
      loginOut = true;
    });
    try {
      // Centralize logout so the sync engine is stopped before the Appwrite
      // session and tenant profile are cleared.
      await authService.signOut();
      PanesListState.signedIn.value = false;
      PanesListState.index.value = 0;
    } catch (error) {
      if (mounted) {
        setState(() {
          loginOut = false;
        });
        displayMessage(context, error.toString(), InfoBarSeverity.error);
      }
    }
  }

  void cancel() {
    PanesListState.index.value = PanesListState.previousValue;
  }
}
