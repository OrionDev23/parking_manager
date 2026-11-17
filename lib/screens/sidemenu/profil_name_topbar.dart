import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/sidemenu/profil_form.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../widgets/on_tap_scale.dart';

class ProfilNameTopBar extends StatelessWidget {
  const ProfilNameTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final session = authService.session;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final avatarSize = screenWidth < 680 ? 36.0 : 40.0;
    final showEmail = screenWidth >= 900;

    return OnTapScaleAndFade(
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarSize / 2,
            child: Hero(
              tag: 'myprofil',
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: appTheme.color,
                  shape: BoxShape.circle,
                ),
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                child: Text(
                  _initials(session?.displayName ?? session?.email ?? ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          if (showEmail) const SizedBox(width: 10),
          if (showEmail)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                session?.email ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      onTap: () => _openProfile(context),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final values = parts.toList();
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first.substring(0, 1);
    return '${values.first.substring(0, 1)}${values.last.substring(0, 1)}';
  }

  Future<void> _openProfile(BuildContext context) async {
    final profile = await userProfileService.getCurrent();
    final legacy = profile == null
        ? null
        : ParcUser(
            id: profile.id,
            email: profile.email,
            name: profile.name,
            tel: profile.phone,
            avatar: profile.avatar,
          );

    if (!context.mounted) return;

    await showDialog<String>(
      context: context,
      builder: (context) => ProfilForm(user: legacy),
    );
  }
}
