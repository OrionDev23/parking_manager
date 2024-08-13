import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../prestataire/prestataire_gestion.dart';
import 'fournisseur_form.dart';
import 'fournisseur_table.dart';
import 'fournisseur_tabs.dart';

class FournisseurGestion extends PrestataireGestion {
  const FournisseurGestion({super.key, super.archive = false});

  @override
  String getTitle() {
    return 'fournisseurs';
  }

  @override
  void addPrestataire() {
    final index = FournisseurTabsState.tabs.length + 1;
    final tab = generateTab(index);
    FournisseurTabsState.tabs.add(tab);
    FournisseurTabsState.currentIndex.value = index - 1;
  }

  @override
  Widget getTable() {
    return FournisseurTable(
      archive: archive,
    );
  }

  @override
  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvfournisseur'.tr()),
      semanticLabel: 'nouvfournisseur'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const FournisseurForm(),
      onClosed: () {
        FournisseurTabsState.tabs.remove(tab);

        if (FournisseurTabsState.currentIndex.value > 0) {
          FournisseurTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
