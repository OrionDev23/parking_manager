import 'package:fluent_ui/fluent_ui.dart';

import '../../../../core/services/vehicle_make_service.dart';

class VehicleMakePickerDialog extends StatefulWidget {
  final String? selectedMakeId;

  const VehicleMakePickerDialog({super.key, this.selectedMakeId});

  @override
  State<VehicleMakePickerDialog> createState() =>
      _VehicleMakePickerDialogState();
}

class _VehicleMakePickerDialogState
    extends State<VehicleMakePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final makes = VehicleMakeService.search(_query);
    return ContentDialog(
      title: const Text('vehicle_make_picker_title').tr(),
      content: SizedBox(
        width: 520,
        height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextBox(
              controller: _searchController,
              placeholder: 'vehicle_make_picker_search'.tr(),
              prefix: const Padding(
                padding: EdgeInsetsDirectional.only(start: 8),
                child: Icon(FluentIcons.search, size: 14),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: makes.isEmpty
                  ? Center(
                      child: Text('vehicle_make_picker_empty'.tr()),
                    )
                  : ListView.separated(
                      itemCount: makes.length,
                      separatorBuilder: (_, _) => Container(
                        height: 1,
                        color: Colors.grey[30],
                      ),
                      itemBuilder: (context, index) {
                        final make = makes[index];
                        final selected = make.id == widget.selectedMakeId;
                        return Button(
                          onPressed: () => Navigator.of(context).pop(make.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                VehicleMakeLogo(makeId: make.id, size: 34),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        make.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        VehicleMakeService.categoryLabel(
                                          make.category,
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[100],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    FluentIcons.check_mark,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('annuler'.tr()),
        ),
      ],
    );
  }
}
