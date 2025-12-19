import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liu_stoma/services/file_service.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/common/modal_wrapper.dart';
import 'package:liu_stoma/widgets/common/animated_close_button.dart';
import 'package:url_launcher/url_launcher.dart';

// Enable logging
void log(String message) {
  print('[PatientFilesModal] $message');
}

class PatientFilesModal extends StatefulWidget {
  final String patientId;
  final double scale;
  final VoidCallback onClose;

  const PatientFilesModal({
    super.key,
    required this.patientId,
    required this.scale,
    required this.onClose,
  });

  @override
  State<PatientFilesModal> createState() => _PatientFilesModalState();
}

class _PatientFilesModalState extends State<PatientFilesModal> {
  bool _uploadButtonHovering = false;
  bool _uploadButtonPressed = false;
  bool _isUploading = false;
  String? _notificationMessage;
  bool? _notificationIsSuccess;
  PatientFile? _fileToDelete;
  Stream<List<PatientFile>>? _filesStream;
  StreamSubscription<List<PatientFile>>? _filesSubscription;
  List<PatientFile> _files = [];
  bool _isLoading = true;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _uploadFile() async {
    log('Starting file upload');
    try {
      setState(() {
        _isUploading = true;
      });

      log('Opening file picker...');
      FilePickerResult? result;
      try {
        // Use a small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 100));
        
        log('Calling FilePicker.platform.pickFiles...');
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: false,
          withReadStream: false,
          dialogTitle: 'Selectează un fișier',
        );
        
        log('File picker call completed. Result: ${result != null}');
        if (result != null) {
          log('Result files count: ${result.files.length}');
          if (result.files.isNotEmpty) {
            final pickedFile = result.files.single;
            log('Selected file - name: ${pickedFile.name}, path: ${pickedFile.path}, size: ${pickedFile.size}');
          } else {
            log('Result is not null but files list is empty');
          }
        } else {
          log('File picker returned null (user cancelled or error)');
        }
      } catch (e, stackTrace) {
        log('File picker exception: $e');
        log('Exception type: ${e.runtimeType}');
        log('Stack trace: $stackTrace');
        setState(() {
          _isUploading = false;
          _notificationMessage = 'Eroare la deschiderea selectorului de fișiere:\n$e\n\nAsigură-te că aplicația are permisiuni pentru accesul la fișiere și că ai reconstruit aplicația după adăugarea permisiunilor.';
          _notificationIsSuccess = false;
        });
        return;
      }

      if (result == null) {
        log('File picker cancelled by user');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final pickedFile = result.files.single;
      if (pickedFile.path == null && pickedFile.bytes == null) {
        log('No file path or bytes available');
        setState(() {
          _isUploading = false;
          _notificationMessage = 'Nu s-a putut accesa fișierul selectat';
          _notificationIsSuccess = false;
        });
        return;
      }

      File? file;
      if (pickedFile.path != null) {
        log('Using file path: ${pickedFile.path}');
        file = File(pickedFile.path!);
        if (!await file.exists()) {
          log('File does not exist at path: ${pickedFile.path}');
          setState(() {
            _isUploading = false;
            _notificationMessage = 'Fișierul nu există la calea specificată';
            _notificationIsSuccess = false;
          });
          return;
        }
      } else if (pickedFile.bytes != null) {
        log('File has bytes, saving to temp file');
        // For web or when path is not available, save bytes to temp file
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${pickedFile.name}');
        await tempFile.writeAsBytes(pickedFile.bytes!);
        file = tempFile;
      }

      if (file == null) {
        log('Could not create file object');
        setState(() {
          _isUploading = false;
          _notificationMessage = 'Nu s-a putut crea obiectul fișier';
          _notificationIsSuccess = false;
        });
        return;
      }

      log('Starting upload to Firebase...');
      final uploadResult = await FileService.uploadFile(
        patientId: widget.patientId,
        file: file,
      );

      log('Upload result: success=${uploadResult.success}, error=${uploadResult.errorMessage}');
      setState(() {
        _isUploading = false;
        if (uploadResult.success) {
          _notificationMessage = 'Fișier încărcat cu succes!';
          _notificationIsSuccess = true;
          // Stream will automatically update _files, no need to manually refresh
        } else {
          _notificationMessage = uploadResult.errorMessage ?? 'Eroare la încărcare';
          _notificationIsSuccess = false;
        }
      });
    } catch (e, stackTrace) {
      log('Upload exception: $e');
      log('Stack trace: $stackTrace');
      setState(() {
        _isUploading = false;
        _notificationMessage = 'Eroare la încărcare: $e';
        _notificationIsSuccess = false;
      });
    }
  }

  Future<void> _deleteFile(PatientFile file) async {
    log('Deleting file: ${file.id}');
    final result = await FileService.deleteFile(
      patientId: widget.patientId,
      fileId: file.id,
    );

    log('Delete result: success=${result.success}, error=${result.errorMessage}');
    setState(() {
      _fileToDelete = null;
      if (result.success) {
        _notificationMessage = 'Fișier șters cu succes!';
        _notificationIsSuccess = true;
      } else {
        _notificationMessage = result.errorMessage ?? 'Eroare la ștergere';
        _notificationIsSuccess = false;
      }
    });
  }

  Future<void> _downloadFile(PatientFile file) async {
    try {
      final url = Uri.parse(file.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _notificationMessage = 'Nu s-a putut deschide fișierul';
          _notificationIsSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _notificationMessage = 'Eroare la deschidere: $e';
        _notificationIsSuccess = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    log('Initializing PatientFilesModal for patient: ${widget.patientId}');
    _loadFiles();
  }

  void _loadFiles() {
    setState(() {
      _isLoading = true;
    });
    
    // Subscribe to stream and update state when data changes
    _filesStream = FileService.getPatientFiles(widget.patientId);
    _filesSubscription = _filesStream!.listen(
      (files) {
        log('Received ${files.length} files');
        if (mounted) {
          setState(() {
            _files = files;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        log('Stream error: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _notificationMessage = 'Eroare la încărcare: $error';
            _notificationIsSuccess = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    log('Disposing PatientFilesModal');
    _filesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed logging from build to prevent spam - only log on init/dispose
    return PopScope(
      canPop: !_isUploading,
      onPopInvoked: (didPop) {
        if (_isUploading && !didPop) {
          // Show message that upload is in progress
          setState(() {
            _notificationMessage = 'Nu poți închide modalul în timpul încărcării fișierului';
            _notificationIsSuccess = false;
          });
        }
      },
      child: Stack(
      children: [
        ModalWrapper(
          onClose: _isUploading ? () {} : widget.onClose,
          scale: widget.scale,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          preventCloseOnTap: _isUploading,
          child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(40 * widget.scale),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fișiere pacient',
                                style: TextStyle(
                                  fontSize: 48 * widget.scale,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                                    Opacity(
                                      opacity: _isUploading ? 0.5 : 1.0,
                                      child: AnimatedCloseButton(
                                        onTap: _isUploading ? () {} : widget.onClose,
                                        scale: widget.scale,
                                        iconSize: 48,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40 * widget.scale),
                            child: _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _files.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Nu există fișiere încărcate',
                                          style: TextStyle(
                                            fontSize: 32 * widget.scale,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
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
                                        borderRadius: BorderRadius.circular(16 * widget.scale),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 3 * widget.scale,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 24 * widget.scale,
                                          vertical: 16 * widget.scale,
                                        ),
                                        leading: Icon(
                                          Icons.insert_drive_file,
                                          size: 48 * widget.scale,
                                          color: Colors.blue[600],
                                        ),
                                        title: Text(
                                          file.name,
                                          style: TextStyle(
                                            fontSize: 28 * widget.scale,
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
                                                fontSize: 22 * widget.scale,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              'Încărcat: ${file.uploadedAt.day}/${file.uploadedAt.month}/${file.uploadedAt.year}',
                                              style: TextStyle(
                                                fontSize: 22 * widget.scale,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () => _downloadFile(file),
                                                child: Container(
                                                  padding: EdgeInsets.all(12 * widget.scale),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[600],
                                                    borderRadius: BorderRadius.circular(8 * widget.scale),
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 2 * widget.scale,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.download,
                                                    size: 32 * widget.scale,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12 * widget.scale),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _fileToDelete = file;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(12 * widget.scale),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[600],
                                                    borderRadius: BorderRadius.circular(8 * widget.scale),
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 2 * widget.scale,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.delete,
                                                    size: 32 * widget.scale,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
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
                          padding: EdgeInsets.all(40 * widget.scale),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: MouseRegion(
                              onEnter: (_) {
                                if (!_uploadButtonHovering) {
                                  setState(() => _uploadButtonHovering = true);
                                }
                              },
                              onExit: (_) {
                                if (_uploadButtonHovering) {
                                  setState(() => _uploadButtonHovering = false);
                                }
                              },
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTapDown: (_) {
                                  if (!_uploadButtonPressed) {
                                    setState(() => _uploadButtonPressed = true);
                                  }
                                },
                                onTapUp: (_) {
                                  if (_uploadButtonPressed) {
                                    setState(() => _uploadButtonPressed = false);
                                  }
                                  if (!_isUploading) {
                                    _uploadFile();
                                  }
                                },
                                onTapCancel: () {
                                  if (_uploadButtonPressed) {
                                    setState(() => _uploadButtonPressed = false);
                                  }
                                },
                                child: AnimatedScale(
                                  scale: _uploadButtonPressed ? 0.97 : (_uploadButtonHovering ? 1.02 : 1.0),
                                  alignment: Alignment.center,
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      color: _isUploading ? Colors.grey[400] : Colors.green[600],
                                      borderRadius: BorderRadius.circular(20 * widget.scale),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 6 * widget.scale,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(_uploadButtonPressed ? 0.5 : (_uploadButtonHovering ? 0.6 : 0.4)),
                                          blurRadius: _uploadButtonPressed ? 6 * widget.scale : (_uploadButtonHovering ? 12 * widget.scale : 8 * widget.scale),
                                          offset: Offset(0, _uploadButtonPressed ? 4 * widget.scale : (_uploadButtonHovering ? 8 * widget.scale : 6 * widget.scale)),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 40 * widget.scale,
                                      vertical: 20 * widget.scale,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isUploading)
                                          SizedBox(
                                            width: 32 * widget.scale,
                                            height: 32 * widget.scale,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.upload_file,
                                            size: 48 * widget.scale,
                                            color: Colors.white,
                                            weight: 900,
                                          ),
                                        SizedBox(width: 16 * widget.scale),
                                        Text(
                                          _isUploading ? 'Se încarcă...' : 'Încarcă fișier',
                                          style: TextStyle(
                                            fontSize: 32 * widget.scale,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
          ],
        ),
        ),
        // Delete confirmation dialog
        if (_fileToDelete != null)
          ConfirmDialog(
            title: 'Confirmă ștergerea',
            message: 'Ești sigură că vrei să ștergi fișierul "${_fileToDelete!.name}"?',
            confirmText: 'Șterge',
            cancelText: 'Anulează',
            scale: widget.scale,
            onConfirm: () {
              _deleteFile(_fileToDelete!);
            },
            onCancel: () {
              setState(() {
                _fileToDelete = null;
              });
            },
          ),
        // Custom notification
        if (_notificationMessage != null && _notificationIsSuccess != null)
          CustomNotification(
            message: _notificationMessage!,
            isSuccess: _notificationIsSuccess!,
            scale: widget.scale,
            onDismiss: () {
              setState(() {
                _notificationMessage = null;
                _notificationIsSuccess = null;
              });
            },
          ),
        // Loading overlay - more apparent
        if (_isUploading)
          GestureDetector(
            onTap: () {}, // Prevent closing during upload
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(40 * widget.scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32 * widget.scale),
                        border: Border.all(
                          color: Colors.black,
                          width: 7 * widget.scale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20 * widget.scale,
                            offset: Offset(0, 10 * widget.scale),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 120 * widget.scale,
                            height: 120 * widget.scale,
                            child: CircularProgressIndicator(
                              strokeWidth: 12 * widget.scale,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                            ),
                          ),
                          SizedBox(height: 40 * widget.scale),
                          Text(
                            'Se încarcă fișierul...',
                            style: TextStyle(
                              fontSize: 48 * widget.scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 20 * widget.scale),
                          Text(
                            'Te rugăm să aștepți',
                            style: TextStyle(
                              fontSize: 32 * widget.scale,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 30 * widget.scale),
                          Text(
                            'Nu închide aplicația!',
                            style: TextStyle(
                              fontSize: 28 * widget.scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }
}

