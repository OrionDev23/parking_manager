import 'package:fluent_ui/fluent_ui.dart';

class ImportListElement extends StatefulWidget {
  final Function()? onRefresh;
  final bool? refreshing;
  final Function(bool?)? onChecked;
  final bool checked;
  final String title;
  final String? subTitle;
  const ImportListElement({super.key, this.onRefresh, required this.title, this.subTitle, this.onChecked, required this.checked, this.refreshing});

  @override
  State<ImportListElement> createState() => _ImportListElementState();
}

class _ImportListElementState extends State<ImportListElement> {

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: widget.subTitle!=null?Text(
        widget.subTitle!,
        style: TextStyle(color: Colors.grey[100]),
      ):null,
      leading: Checkbox(checked: widget.checked, onChanged: widget.onChecked,),
      trailing: widget.refreshing==true?
          const ProgressRing()
          :widget.refreshing==false?IconButton(icon: const Icon(FluentIcons
          .refresh)
    ,onPressed: widget.onRefresh,):null,
    );
  }
}
