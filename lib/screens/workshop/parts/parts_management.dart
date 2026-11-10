import 'package:fluent_ui/fluent_ui.dart';

import 'parts_management/parts_manager.dart';

/// Compatibility entry point for the workshop parts manager.
class PartsManagement extends StatelessWidget {
  const PartsManagement({super.key});

  @override
  Widget build(BuildContext context) => const PartsManager();
}
