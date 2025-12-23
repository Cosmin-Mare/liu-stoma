import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:liu_stoma/services/patient_service.dart';

class PatientFile {
  final String id;
  final String name;
  final String downloadUrl;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;

  PatientFile({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory PatientFile.fromMap(String id, Map<String, dynamic> map) {
    return PatientFile(
      id: id,
      name: map['name'] as String,
      downloadUrl: map['downloadUrl'] as String,
      sizeBytes: map['sizeBytes'] as int,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'downloadUrl': downloadUrl,
      'sizeBytes': sizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }
}

class FileServiceResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  FileServiceResult.success(this.data)
      : success = true,
        errorMessage = null;

  FileServiceResult.error(this.errorMessage)
      : success = false,
        data = null;
}

class FileService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload a file for a patient
  static Future<FileServiceResult<PatientFile>> uploadFile({
    required String patientId,
    required File file,
    String? uploadedBy,
  }) async {
    print('[FileService] Starting upload for patient: $patientId');
    try {
      final fileName = file.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'patients/$patientId/files/$timestamp-$fileName';
      print('[FileService] Storage path: $storagePath');

      // Upload file to Firebase Storage
      print('[FileService] Uploading to Firebase Storage...');
      final uploadTask = _storage.ref(storagePath).putFile(file);
      final snapshot = await uploadTask;
      print('[FileService] Upload complete, getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('[FileService] Download URL: $downloadUrl');

      // Get file size
      final metadata = await snapshot.ref.getMetadata();
      final sizeBytes = metadata.size ?? 0;
      print('[FileService] File size: $sizeBytes bytes');

      // Create file document in Firestore
      final fileData = {
        'name': fileName,
        'downloadUrl': downloadUrl,
        'sizeBytes': sizeBytes,
        'uploadedAt': Timestamp.now(),
        'uploadedBy': uploadedBy ?? 'User',
        'storagePath': storagePath,
      };
      print('[FileService] Saving file metadata to Firestore...');

      final fileDocRef = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('files')
          .add(fileData);
      print('[FileService] File saved with ID: ${fileDocRef.id}');

      final patientFile = PatientFile(
        id: fileDocRef.id,
        name: fileName,
        downloadUrl: downloadUrl,
        sizeBytes: sizeBytes,
        uploadedAt: DateTime.now(),
        uploadedBy: uploadedBy ?? 'User',
      );

      print('[FileService] Upload successful');
      return FileServiceResult.success(patientFile);
    } catch (e, stackTrace) {
      print('[FileService] Upload error: $e');
      print('[FileService] Stack trace: $stackTrace');
      return FileServiceResult.error('Eroare la încărcare: $e');
    }
  }

  /// Get all files for a patient
  static Stream<List<PatientFile>> getPatientFiles(String patientId) {
    print('[FileService] Getting files for patient: $patientId');
    
    final controller = StreamController<List<PatientFile>>.broadcast();
    
    // Emit empty list immediately so StreamBuilder doesn't stay in waiting state
    controller.add(<PatientFile>[]);
    
    try {
      // Get files without orderBy to avoid index requirement, then sort in memory
      final firestoreStream = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('files')
          .snapshots()
          .map((snapshot) {
        // Reduced logging frequency - only log when data actually changes
        if (snapshot.docs.isNotEmpty) {
          print('[FileService] Received snapshot with ${snapshot.docs.length} files');
        }
        
        try {
          if (snapshot.docs.isEmpty) {
            print('[FileService] No files found in collection');
            return <PatientFile>[];
          }
          
          final files = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  print('[FileService] Parsing file ${doc.id}: ${data.keys}');
                  return PatientFile.fromMap(doc.id, data);
                } catch (e, stackTrace) {
                  print('[FileService] Error parsing file ${doc.id}: $e');
                  print('[FileService] Stack trace: $stackTrace');
                  return null;
                }
              })
              .where((file) => file != null)
              .cast<PatientFile>()
              .toList();
          
          // Sort manually by uploadedAt descending (newest first)
          files.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          
          print('[FileService] Successfully parsed and sorted ${files.length} files');
          return files;
        } catch (e, stackTrace) {
          print('[FileService] Error mapping files: $e');
          print('[FileService] Stack trace: $stackTrace');
          return <PatientFile>[];
        }
      }).handleError((error, stackTrace) {
        print('[FileService] Stream error: $error');
        print('[FileService] Stack trace: $stackTrace');
        // Return empty list on error
        return <PatientFile>[];
      });
      
      // Forward Firestore stream events to controller
      firestoreStream.listen(
        (files) {
          print('[FileService] Forwarding ${files.length} files to stream');
          if (!controller.isClosed) {
            controller.add(files);
          }
        },
        onError: (error) {
          print('[FileService] Firestore stream error: $error');
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
        cancelOnError: false,
      );
      
      return controller.stream;
    } catch (e, stackTrace) {
      print('[FileService] Error creating stream: $e');
      print('[FileService] Stack trace: $stackTrace');
      controller.add(<PatientFile>[]);
      return controller.stream;
    }
  }

  /// Delete a file
  static Future<FileServiceResult<void>> deleteFile({
    required String patientId,
    required String fileId,
    String? storagePath,
  }) async {
    print('[FileService] Deleting file: $fileId for patient: $patientId');
    try {
      final fileDocRef = _firestore
          .collection('patients')
          .doc(patientId)
          .collection('files')
          .doc(fileId);

      // Get storage path from document if not provided
      String? pathToDelete = storagePath;
      if (pathToDelete == null) {
        print('[FileService] Getting storage path from Firestore...');
        final fileDoc = await fileDocRef.get();
        if (fileDoc.exists) {
          final data = fileDoc.data();
          pathToDelete = data?['storagePath'] as String?;
          print('[FileService] Storage path: $pathToDelete');
        } else {
          print('[FileService] File document does not exist');
        }
      }

      // Delete from Firestore
      print('[FileService] Deleting from Firestore...');
      await fileDocRef.delete();

      // Delete from Storage if path is available
      if (pathToDelete != null) {
        try {
          print('[FileService] Deleting from Storage...');
          await _storage.ref(pathToDelete).delete();
          print('[FileService] Storage deletion successful');
        } catch (e) {
          // Log but don't fail if storage delete fails
          print('[FileService] Warning: Could not delete file from storage: $e');
        }
      }

      print('[FileService] Delete successful');
      return FileServiceResult.success(null);
    } catch (e, stackTrace) {
      print('[FileService] Delete error: $e');
      print('[FileService] Stack trace: $stackTrace');
      return FileServiceResult.error('Eroare la ștergere: $e');
    }
  }

  /// Download a file (returns the download URL)
  static Future<FileServiceResult<String>> getDownloadUrl(String downloadUrl) async {
    try {
      // The downloadUrl is already provided, just return it
      return FileServiceResult.success(downloadUrl);
    } catch (e) {
      return FileServiceResult.error('Eroare la descărcare: $e');
    }
  }
}

