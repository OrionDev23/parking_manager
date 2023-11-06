import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/sidemenu/profil_form.dart';
import 'package:parc_oto/serializables/parc_user.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import 'futur_image.dart';

class ProfilNameTopBar extends StatelessWidget {
  const ProfilNameTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ValueListenableBuilder(
        valueListenable: ClientDatabase.me,
        builder: (context, me, _) {
          return Button(
              style: ButtonStyle(
                shape: ButtonState.all<OutlinedBorder>(
                    const RoundedRectangleBorder()),
                padding: ButtonState.all<EdgeInsets>(const EdgeInsets.all(4)),
              ),
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
                        child: me != null &&
                                me.avatar != null &&
                                me.avatar!.isNotEmpty
                            ? FutureImage(me.avatar!)
                            : Text(
                                ProfilUtilitis.getFirstLetters(me)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(me?.email ?? ''),
                ],
              ),
              onPressed: () {
                showProfilForm(context, me);
              });
        });
  }

  void showProfilForm(BuildContext context, ParcUser? me) async {
    await showDialog<String>(
        context: context, builder: (context) => ProfilForm(user: me));
  }
}