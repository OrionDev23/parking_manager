import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/tutorials/video_player.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme.dart';
import '../widgets/button_container.dart';

class Tutorial extends StatelessWidget {
  const Tutorial({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    bool portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Column(
      children: [
        const PageTitle(text: 'tutorial',),
        SizedBox(height: 100.px,),
        Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10),
            children: [
              StaggeredGrid.count(
                crossAxisCount:
                portrait
                    ? 2
                    : 3,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                children: buttonList(appTheme,context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> buttonList(AppTheme appTheme,BuildContext context) {
    return [
      ButtonContainer(
        icon: FluentIcons.car,
        text: 'vehicules'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/voitures.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.people_external_share,
        text: 'chauffeurs'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/conducteurs.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.repair,
        text: 'reparations'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/reparations.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.user_optional,
        text: 'users'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/utilisateurs.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.external_build,
        text: 'monentreprise'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/entreprise.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.database_activity,
        text: 'journal'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/log.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.settings,
        text: 'parametres'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/parametres.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.plan_view,
        text: 'planifier'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/planning.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
      ButtonContainer(
        icon: FluentIcons.view_dashboard,
        text: 'home'.tr(),
        action: () {
          viewVideo('http://www.parcoto.com/tutorials/tableaudebord.mp4',context);
        },
        showCounter: false,
        showBothLN: false,
        showBottom: false,
      ),
    ];
  }

  void viewVideo(String link,BuildContext context){
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) {
          return ContentDialog(
            constraints: BoxConstraints.loose(Size(900.px, 800.px)),
            content: PaOVideoPlayer(link: link,),
            actions: [
              Button(child:const Text('fermer').tr(),onPressed:(){
                Navigator.of(context).pop();
              })
            ],
          );
        }));
  }
}
