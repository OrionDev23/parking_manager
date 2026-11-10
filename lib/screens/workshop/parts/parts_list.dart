import 'package:fluent_ui/fluent_ui.dart';

import '../../../widgets/page_header.dart';
import 'parts_management/parts_table.dart';

/// Standalone catalogue listing retained for legacy navigation targets.
class PartsList extends StatelessWidget {
  const PartsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      header: const PageTitle(text: 'gpieces'),
      content: const PartsTable(),
    );
  }
}
