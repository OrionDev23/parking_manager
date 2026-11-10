import 'package:fluent_ui/fluent_ui.dart';

import '../../widgets/page_header.dart';
import '../reparation/reparation/manager/reparation_table.dart';

/// Workshop-facing repair register.
///
/// The dedicated "my repairs" route previously rendered Flutter's debug
/// Placeholder. Reuse the existing repair data source/table so this screen
/// displays real Appwrite/cache-backed repair records instead of mock data.
class SelfRepair extends StatelessWidget {
  const SelfRepair({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      header: const PageTitle(text: 'localrepair'),
      content: const ReparationTable(),
    );
  }
}
