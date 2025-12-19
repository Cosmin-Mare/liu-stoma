import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liu_stoma/services/file_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FisiereTab extends StatefulWidget {
  final String patientId;
  final double scale;
  final Function(String?, bool?) onNotification;
  final Function(PatientFile?) onFileToDeleteChanged;
  final Function(bool) onUploadingChanged;

  const FisiereTab({
    super.key,
    required this.patientId,
    required this.scale,
    required this.onNotification,
    required this.onFileToDeleteChanged,
    required this.onUploadingChanged,
  });

  @override
  State<FisiereTab> createState() => FisiereTabState();
}

class FisiereTabState extends State<FisiereTab> {
  Stream<List<PatientFile>>? _filesStream;
  List<PatientFile> _files = [];
  bool _isLoadingFiles = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _filesStream = null;
    super.dispose();
  }

  void _loadFiles() {
    setState(() {
      _isLoadingFiles = true;
    });
    _filesStream = FileService.getPatientFiles(widget.patientId);
    _filesStream!.listen(
      (files) {
        if (mounted) {
          setState(() {
            _files = files;
            _isLoadingFiles = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoadingFiles = false;
            widget.onNotification('Eroare la încărcare: $error', false);
          });
        }
      },
    );
  }

  Future<void> _uploadFile() async {
    try {
      setState(() {
        _isUploading = true;
      });
      widget.onUploadingChanged(true);

      await Future.delayed(const Duration(milliseconds: 100));
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
        dialogTitle: 'Selectează un fișier',
      );

      if (result == null) {
        setState(() {
          _isUploading = false;
        });
        widget.onUploadingChanged(false);
        return;
      }

      final pickedFile = result.files.single;
      if (pickedFile.path == null && pickedFile.bytes == null) {
        setState(() {
          _isUploading = false;
        });
        widget.onUploadingChanged(false);
        widget.onNotification('Nu s-a putut accesa fișierul selectat', false);
        return;
      }

      File? file;
      if (pickedFile.path != null) {
        file = File(pickedFile.path!);
        if (!await file.exists()) {
          setState(() {
            _isUploading = false;
          });
          widget.onUploadingChanged(false);
          widget.onNotification('Fișierul nu există la calea specificată', false);
          return;
        }
      } else if (pickedFile.bytes != null) {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${pickedFile.name}');
        await tempFile.writeAsBytes(pickedFile.bytes!);
        file = tempFile;
      }

      if (file == null) {
        setState(() {
          _isUploading = false;
        });
        widget.onUploadingChanged(false);
        widget.onNotification('Nu s-a putut crea obiectul fișier', false);
        return;
      }

      final uploadResult = await FileService.uploadFile(
        patientId: widget.patientId,
        file: file,
      );

      setState(() {
        _isUploading = false;
      });
      widget.onUploadingChanged(false);
      if (uploadResult.success) {
        widget.onNotification('Fișier încărcat cu succes!', true);
      } else {
        widget.onNotification(uploadResult.errorMessage ?? 'Eroare la încărcare', false);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      widget.onUploadingChanged(false);
      widget.onNotification('Eroare la încărcare: $e', false);
    }
  }

  Future<void> deleteFile(PatientFile file) async {
    final result = await FileService.deleteFile(
      patientId: widget.patientId,
      fileId: file.id,
    );

    widget.onFileToDeleteChanged(null);
    if (result.success) {
      widget.onNotification('Fișier șters cu succes!', true);
    } else {
      widget.onNotification(result.errorMessage ?? 'Eroare la ștergere', false);
    }
  }

  Future<void> _downloadFile(PatientFile file) async {
    try {
      final url = Uri.parse(file.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        widget.onNotification('Nu s-a putut deschide fișierul', false);
      }
    } catch (e) {
      widget.onNotification('Eroare la deschidere: $e', false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _setFileToDelete(PatientFile? file) {
    widget.onFileToDeleteChanged(file);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(24 * widget.scale),
            child: _isLoadingFiles
                ? Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? Center(
                        child: Text(
                          'Nu există fișiere încărcate',
                          style: TextStyle(
                            fontSize: 51 * widget.scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 16 * widget.scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28 * widget.scale),
                              border: Border.all(
                                color: Colors.black,
                                width: 3 * widget.scale,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16 * widget.scale,
                                vertical: 12 * widget.scale,
                              ),
                              leading: Icon(
                                Icons.insert_drive_file,
                                size: 75 * widget.scale,
                                color: Colors.blue[600],
                              ),
                              title: Text(
                                file.name,
                                style: TextStyle(
                                  fontSize: 48 * widget.scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4 * widget.scale),
                                  Text(
                                    'Mărime: ${_formatFileSize(file.sizeBytes)}',
                                    style: TextStyle(
                                      fontSize: 42 * widget.scale,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    'Încărcat: ${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                                    style: TextStyle(
                                      fontSize: 42 * widget.scale,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _downloadFile(file),
                                    icon: Icon(Icons.download, size: 66 * widget.scale),
                                    color: Colors.blue[600],
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _setFileToDelete(file);
                                    },
                                    icon: Icon(Icons.delete, size: 66 * widget.scale),
                                    color: Colors.red[600],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(24 * widget.scale),
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadFile,
            icon: _isUploading
                ? SizedBox(
                    width: 51 * widget.scale,
                    height: 51 * widget.scale,
                    child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
                  )
                : Icon(Icons.upload_file, size: 72 * widget.scale),
            label: Text(
              _isUploading ? 'Se încarcă...' : 'Încarcă fișier',
              style: TextStyle(
                fontSize: 54 * widget.scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUploading ? Colors.grey[400] : Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 60 * widget.scale,
                vertical: 36 * widget.scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36 * widget.scale),
                side: BorderSide(color: Colors.black, width: 7 * widget.scale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

