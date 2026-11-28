import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../main.dart' show vehicleServices;
import '../../../providers/client_database.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../serializables/vehicle/document_vehicle.dart';
import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';
import '../manager/vehicles_table.dart';

const String _vehicleDocumentBucketId = 'images';
const int _maxVehicleDocumentBytes = 15000000;

const Map<String, String> _vehicleDocumentTypes = {
  'registration_card': 'vehicle_doc_type_registration_card',
  'insurance': 'vehicle_doc_type_insurance',
  'technical_inspection': 'vehicle_doc_type_technical_inspection',
  'invoice': 'vehicle_doc_type_invoice',
  'maintenance': 'vehicle_doc_type_maintenance',
  'authorization': 'vehicle_doc_type_authorization',
  'reception_sheet': 'vehicle_doc_type_reception_sheet',
  'other': 'vehicle_doc_type_other',
};

Size _responsiveDocumentSelectorSize(BuildContext context) {
  final screenSize = MediaQuery.sizeOf(context);
  return Size(
    (screenSize.width - 32).clamp(280.0, 700.0).toDouble(),
    (screenSize.height - 80).clamp(320.0, 550.0).toDouble(),
  );
}

class DocumentForm extends StatefulWidget {
  final DocumentVehicle? vd;
  final Vehicle? vehicle;

  const DocumentForm({super.key, this.vd, this.vehicle});

  @override
  DocumentFormState createState() => DocumentFormState();
}

class DocumentFormState extends State<DocumentForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  String _documentType = 'other';
  Vehicle? _selectedVehicle;
  PlatformFile? _pendingFile;
  Uint8List? _pendingFileBytes;
  String? _documentId;
  bool _removeExistingFile = false;
  bool _loadingVehicle = false;
  bool _pickingFile = false;
  bool _saving = false;
  bool _changes = false;

  String? get _existingFileId =>
      widget.vd?.fileId?.trim().isNotEmpty == true
          ? widget.vd!.fileId
          : null;

  String? get _currentVehicleId =>
      _selectedVehicle?.id ?? widget.vd?.vehicle ?? widget.vehicle?.id;

  String? get _currentVehicleRegistration =>
      _selectedVehicle?.matricule ??
      widget.vehicle?.matricule ??
      widget.vd?.vehiclemat;

  @override
  void initState() {
    super.initState();
    _documentId = widget.vd?.id ?? ID.unique();
    _selectedVehicle = widget.vehicle;
    if (widget.vd != null) {
      final document = widget.vd!;
      _nameController.text = document.nom;
      _notesController.text = document.notes ?? '';
      _documentType = _vehicleDocumentTypes.containsKey(document.documentType)
          ? document.documentType!
          : 'other';
      _issueDate = document.issueDate;
      _expiryDate = document.dateExpiration;
      if (document.vehicle != null) {
        _loadLinkedVehicle(document.vehicle!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLinkedVehicle(String vehicleId) async {
    setState(() => _loadingVehicle = true);
    try {
      final row = await DatabaseGetter().getDocument(vehiculeid, vehicleId);
      if (!mounted) return;
      if (row != null) {
        setState(() {
          _selectedVehicle = row.convertTo(
            (data) => Vehicle.fromJson(data),
          );
        });
      }
    } catch (error) {
      debugPrint('[Vehicle documents] linked vehicle lookup failed: $error');
    } finally {
      if (mounted) setState(() => _loadingVehicle = false);
    }
  }

  void _refreshChanges() {
    final original = widget.vd;
    final changed = original == null
        ? _nameController.text.trim().isNotEmpty ||
            _currentVehicleId != null ||
            _pendingFile != null ||
            _issueDate != null ||
            _expiryDate != null ||
            _notesController.text.trim().isNotEmpty ||
            _documentType != 'other'
        : _nameController.text.trim() != original.nom ||
            _currentVehicleId != original.vehicle ||
            _documentType != (original.documentType ?? 'other') ||
            _issueDate != original.issueDate ||
            _expiryDate != original.dateExpiration ||
            _notesController.text.trim() != (original.notes ?? '') ||
            _pendingFile != null ||
            _removeExistingFile;

    if (_changes != changed && mounted) {
      setState(() => _changes = changed);
    }
  }

  String _mimeTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return (bytes / 1024).toStringAsFixed(0) + ' Ko';
    }
    return (bytes / (1024 * 1024)).toStringAsFixed(1) + ' Mo';
  }

  List<String> _filePermissions(String teamId) => [
        'read("team:$teamId")',
        'update("team:$teamId/admin")',
        'update("team:$teamId/manager")',
        'delete("team:$teamId/admin")',
        'delete("team:$teamId/manager")',
      ];

  Future<void> _pickAttachment() async {
    if (_pickingFile || _saving) return;
    setState(() => _pickingFile = true);
    try {
      // Use the single-file API from file_picker 13.0+.
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (!mounted || file == null) return;

      final reportedSize = file.lengthSync() ?? await file.length();
      if (reportedSize != null && reportedSize > _maxVehicleDocumentBytes) {
        throw StateError('vehicle_doc_file_size_limit'.tr());
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('vehicle_doc_file_unreadable'.tr());
      }
      if (bytes.length > _maxVehicleDocumentBytes) {
        throw StateError('vehicle_doc_file_size_limit'.tr());
      }

      setState(() {
        _pendingFile = file;
        _pendingFileBytes = bytes;
        _removeExistingFile = false;
      });
      _refreshChanges();
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Bad state: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _removeAttachment() {
    if (_pendingFile != null) {
      setState(() {
        _pendingFile = null;
        _pendingFileBytes = null;
      });
    } else if (_existingFileId != null) {
      setState(() => _removeExistingFile = true);
    }
    _refreshChanges();
  }

  Future<Map<String, dynamic>> _uploadPendingFile() async {
    final selected = _pendingFile;
    if (selected == null) {
      throw StateError('vehicle_doc_file_missing'.tr());
    }
    final bytes = _pendingFileBytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('vehicle_doc_attachment_empty'.tr());
    }

    final client = DatabaseGetter.client;
    final teamId = vehicleServices.teamId;
    if (client == null) {
      throw StateError('vehicle_doc_client_uninitialized'.tr());
    }
    if (teamId == null || teamId.trim().isEmpty) {
      throw StateError(
        'vehicle_doc_team_context_missing'.tr(),
      );
    }

    final extension = selected.name.split('.').last.toLowerCase();
    if (!const ['pdf', 'jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw StateError('vehicle_doc_file_format_invalid'.tr());
    }

    final fileId = ID.unique();
    final safeName = _documentId! + '_' + fileId + '.' + extension;
    final uploaded = await Storage(client).createFile(
      bucketId: _vehicleDocumentBucketId,
      fileId: fileId,
      file: InputFile.fromBytes(
        bytes: bytes,
        filename: safeName,
        contentType: _mimeTypeFor(selected.name),
      ),
      permissions: _filePermissions(teamId),
    );

    return {
      'fileId': uploaded.$id,
      'fileName': selected.name,
      'mimeType': _mimeTypeFor(selected.name),
      'fileSize': bytes.length,
    };
  }

  Future<void> _deleteStoredFile(String? fileId) async {
    if (fileId == null || fileId.trim().isEmpty) return;
    final client = DatabaseGetter.client;
    if (client == null) return;
    try {
      await Storage(client).deleteFile(
        bucketId: _vehicleDocumentBucketId,
        fileId: fileId,
      );
    } catch (error) {
      debugPrint('[Vehicle documents] old attachment cleanup failed: $error');
    }
  }

  Future<void> _downloadExistingFile() async {
    final fileId = _existingFileId;
    final client = DatabaseGetter.client;
    if (fileId == null || client == null) return;

    try {
      final bytes = await Storage(client).getFileDownload(
        bucketId: _vehicleDocumentBucketId,
        fileId: fileId,
      );
      final fileName = widget.vd?.fileName ?? 'document-$fileId';
      await FilePicker.saveFile(
        dialogTitle: 'vehicle_doc_download_title'.tr(),
        fileName: fileName,
        bytes: bytes,
        mimeType: widget.vd?.mimeType ?? _mimeTypeFor(fileName),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('vehicle_doc_download_failed'.tr() + ': ${error.toString()}', isError: true);
      }
    }
  }

  Future<void> _selectVehicle() async {
    if (_loadingVehicle ||
        _saving ||
        widget.vehicle != null ||
        widget.vd?.vehicle != null) {
      return;
    }
    final selected = await showDialog<Vehicle>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ContentDialog(
        constraints: BoxConstraints.tight(
          _responsiveDocumentSelectorSize(dialogContext),
        ),
        title: Text('selectvehicle').tr(),
        content: const VehicleTable(selectV: true),
        actions: [
          Button(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('fermer').tr(),
          ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedVehicle = selected);
    _refreshChanges();
  }

  void _showMessage(String message, {bool isError = false}) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: isError ? InfoBarSeverity.error : InfoBarSeverity.success,
      ),
      duration: snackbarShortDuration,
    );
  }

  Future<void> _confirm() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final vehicleId = _currentVehicleId;
    if (name.isEmpty) {
      _showMessage('vehicle_doc_name_required'.tr(), isError: true);
      return;
    }
    if (vehicleId == null || vehicleId.isEmpty) {
      _showMessage('vehicle_doc_vehicle_required'.tr(), isError: true);
      return;
    }
    if (_issueDate != null &&
        _expiryDate != null &&
        _expiryDate!.isBefore(_issueDate!)) {
      _showMessage(
        'vehicle_doc_issue_expiry_order'.tr(),
        isError: true,
      );
      return;
    }
    if (!_changes && _pendingFile == null && !_removeExistingFile) return;

    final vehicleProvider = context.read<VehicleProvider>();
    setState(() => _saving = true);
    String? newlyUploadedFileId;
    try {
      final oldFileId = _existingFileId;
      Map<String, dynamic>? uploadedMetadata;
      if (_pendingFile != null) {
        uploadedMetadata = await _uploadPendingFile();
        newlyUploadedFileId = uploadedMetadata['fileId']?.toString();
      }

      final keepExisting = uploadedMetadata == null && !_removeExistingFile;
      final document = DocumentVehicle(
        id: _documentId!,
        nom: name,
        vehicle: vehicleId,
        vehiclemat: _currentVehicleRegistration,
        dateExpiration: _expiryDate,
        createdBy: widget.vd?.createdBy ?? DatabaseGetter.me.value?.id,
        documentType: _documentType,
        fileId: uploadedMetadata?['fileId']?.toString() ??
            (keepExisting ? oldFileId : null),
        fileName: uploadedMetadata?['fileName']?.toString() ??
            (keepExisting ? widget.vd?.fileName : null),
        mimeType: uploadedMetadata?['mimeType']?.toString() ??
            (keepExisting ? widget.vd?.mimeType : null),
        fileSize: uploadedMetadata?['fileSize'] as int? ??
            (keepExisting ? widget.vd?.fileSize : null),
        issueDate: _issueDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      try {
        if (widget.vd != null) {
          await DatabaseGetter().updateDocument(
            collectionId: vehicDoc,
            documentId: _documentId!,
            data: document.toJson(),
          );
        } else {
          await DatabaseGetter().addDocument(
            collectionId: vehicDoc,
            documentId: _documentId!,
            data: document.toJson(),
          );
        }
      } catch (_) {
        if (newlyUploadedFileId != null) {
          await _deleteStoredFile(newlyUploadedFileId);
        }
        rethrow;
      }

      final replaced = oldFileId != null &&
          oldFileId != document.fileId &&
          (uploadedMetadata != null || _removeExistingFile);
      if (replaced) await _deleteStoredFile(oldFileId);

      try {
        await DatabaseGetter().ajoutActivity(
          widget.vd != null ? 8 : 7,
          _documentId!,
          docName: document.nom,
        );
      } catch (error) {
        debugPrint('[Vehicle documents] activity write failed: $error');
      }

      try {
        await vehicleProvider.refreshDocuments();
      } catch (error) {
        debugPrint('[Vehicle documents] refresh after save failed: $error');
      }

      if (!mounted) return;
      setState(() {
        _pendingFile = null;
        _pendingFileBytes = null;
        _removeExistingFile = false;
        _changes = false;
      });
      _showMessage('vehicle_doc_saved'.tr());
      if (widget.vehicle != null) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Bad state: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _fieldLabel(String label, Widget child) {
    final appTheme = context.watch<AppTheme>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: appTheme.writingStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: appTheme.mutedTextColor,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _vehicleSelector(AppTheme appTheme) {
    final registration = _currentVehicleRegistration;
    return Button(
      onPressed: widget.vehicle != null || widget.vd?.vehicle != null
          ? null
          : _selectVehicle,
      child: Row(
        children: [
          const Icon(FluentIcons.car, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _loadingVehicle
                  ? 'vehicle_doc_loading_vehicle'.tr()
                  : (registration?.isNotEmpty == true
                      ? registration!
                      : 'vehicle_doc_select_vehicle'.tr()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.vehicle == null && widget.vd?.vehicle == null)
            const Icon(FluentIcons.chevron_down, size: 12),
        ],
      ),
    );
  }

  Widget _attachmentField(AppTheme appTheme) {
    final selected = _pendingFile;
    final currentFileName = widget.vd?.fileName;
    final hasExisting = _existingFileId != null && !_removeExistingFile;

    if (selected == null && !hasExisting) {
      return Button(
        onPressed: _pickingFile || _saving ? null : _pickAttachment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pickingFile)
              const ProgressRing(strokeWidth: 2)
            else
              const Icon(FluentIcons.attach, size: 15),
            const SizedBox(width: 8),
            Text(
              _pickingFile
                  ? 'vehicle_doc_reading_file'.tr()
                  : 'vehicle_doc_pick_attachment'.tr(),
            ),
          ],
        ),
      );
    }

    final fileName = selected?.name ?? currentFileName ?? 'Document attaché';
    final size = _pendingFileBytes?.length ?? widget.vd?.fileSize;
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appTheme.fillColor,
        border: Border.all(color: appTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isPdf ? FluentIcons.pdf : FluentIcons.picture, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appTheme.writingStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (size != null) _formatFileSize(size),
                    if (selected != null) 'vehicle_doc_file_pending'.tr(),
                    if (selected == null) 'vehicle_doc_file_saved'.tr(),
                  ].join(' • '),
                  style: appTheme.writingStyle.copyWith(
                    fontSize: 10,
                    color: appTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (selected == null && hasExisting)
            IconButton(
              icon: const Icon(FluentIcons.download, size: 15),
              onPressed: _saving ? null : _downloadExistingFile,
            ),
          IconButton(
            icon: const Icon(FluentIcons.delete, size: 15),
            onPressed: _saving ? null : _removeAttachment,
          ),
          if (selected == null && hasExisting)
            IconButton(
              icon: const Icon(FluentIcons.refresh, size: 15),
              onPressed: _saving ? null : _pickAttachment,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 640;
    final width = screenWidth < 720
        ? (screenWidth - 32).clamp(260.0, 520.0).toDouble()
        : 520.0;

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel('vehicle_doc_field_vehicle'.tr(), _vehicleSelector(appTheme)),
            const SizedBox(height: 14),
            _fieldLabel(
              'vehicle_doc_field_type'.tr(),
              ComboBox<String>(
                value: _documentType,
                isExpanded: true,
                items: _vehicleDocumentTypes.entries
                    .map(
                      (entry) => ComboBoxItem<String>(
                        value: entry.key,
                        child: Text(entry.value.tr()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _documentType = value);
                        _refreshChanges();
                      },
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel(
              'vehicle_doc_field_name'.tr(),
              TextBox(
                controller: _nameController,
                enabled: !_saving,
                placeholder: 'Ex. : Assurance 2026, carte grise…',
                onChanged: (_) => _refreshChanges(),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel(
              'vehicle_doc_field_issue_date'.tr(),
              DatePicker(
                selected: _issueDate,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() => _issueDate = value);
                        _refreshChanges();
                      },
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel(
              'vehicle_doc_field_expiry_date'.tr(),
              DatePicker(
                selected: _expiryDate,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() => _expiryDate = value);
                        _refreshChanges();
                      },
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('vehicle_doc_field_attachment'.tr(), _attachmentField(appTheme)),
            const SizedBox(height: 14),
            _fieldLabel(
              'vehicle_doc_field_notes'.tr(),
              TextBox(
                controller: _notesController,
                enabled: !_saving,
                placeholder: 'vehicle_doc_field_notes'.tr(),
                maxLines: 3,
                onChanged: (_) => _refreshChanges(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: _changes && !_saving && !_pickingFile
                      ? _confirm
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 7,
                    ),
                    child: _saving
                        ? const ProgressRing(strokeWidth: 2)
                        : Text('confirmer'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: content,
    );
  }
}
