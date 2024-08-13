import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../prestataire/prestataire_gestion.dart';
import 'client_form.dart';
import 'client_table.dart';
import 'client_tabs.dart';

class ClientGestion extends PrestataireGestion {
  const ClientGestion({super.key, super.archive = false});

  @override
  String getTitle() {
    return 'clients';
  }

  @override
  void addPrestataire() {
    final index = ClientTabsState.tabs.length + 1;
    final tab = generateTab(index);
    ClientTabsState.tabs.add(tab);
    ClientTabsState.currentIndex.value = index - 1;
  }

  @override
  Widget getTable() {
    return ClientTable(
      archive: archive,
    );
  }

  @override
  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvclient'.tr()),
      semanticLabel: 'nouvclient'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const ClientForm(),
      onClosed: () {
        ClientTabsState.tabs.remove(tab);

        if (ClientTabsState.currentIndex.value > 0) {
          ClientTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
