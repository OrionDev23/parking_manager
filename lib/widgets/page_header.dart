import 'package:fluent_ui/fluent_ui.dart';

/// Legacy page-header adapter.
///
/// Screen titles are rendered by the global application topbar. Existing
/// screen-specific actions are retained as a compact action row so removing
/// the heading never removes business actions such as Add, Import or Save.
class PageTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const PageTitle({
    super.key,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (trailing == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: trailing!,
      ),
    );
  }
}
