import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/sidemenu/profil_form.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../widgets/on_tap_scale.dart';

class ProfilNameTopBar extends StatelessWidget {
  const ProfilNameTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ValueListenableBuilder(
        valueListenable: DatabaseGetter.me,
        builder: (context, me, _) {
          return OnTapScaleAndFade(
              child: Row(
                children: [
                  CircleAvatar(
                    child: Hero(
                      tag: 'myprofil',
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: appTheme.color,
                          shape: BoxShape.circle,
                        ),
                        width: 4.w,
                        height: 4.w,
                        alignment: Alignment.center,
                        child: Text(
                          ParcOtoUtilities.getFirstLetters(me).toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  if(Device.orientation==Orientation.landscape)
                  const SizedBox(
                    width: 10,
                  ),
                  if(Device.orientation==Orientation.landscape)
                    Text(me?.email ?? ''),
                ],
              ),
              onTap: () {
                showProfilForm(context, me);
              });
        });
  }

  void showProfilForm(BuildContext context, ParcUser? me) async {
    await showDialog<String>(
        context: context, builder: (context) => ProfilForm(user: me));
  }
}
