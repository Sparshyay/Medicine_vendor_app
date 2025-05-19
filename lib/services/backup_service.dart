import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

// Conditionally import dart:io and dart:html
import 'web_stub.dart' if (dart.library.io) 'dart:io'
    if (dart.library.html) 'web_impl.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import 'hive_service.dart';

class BackupService {
  static const String _backupFolderName = 'MRship App Backups';
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  // Import backup from local file
  static Future<bool> importBackupFromFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String jsonString;
        
        if (kIsWeb) {
          // Web implementation
          final bytes = result.files.single.bytes;
          if (bytes == null) {
            return false;
          }
          jsonString = utf8.decode(bytes);
        } else {
          // Mobile/desktop implementation
          final file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        }
        
        // Show confirmation dialog
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Backup'),
            content: const Text(
              'Importing this backup will replace all existing data. Are you sure you want to proceed?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Import'),
              ),
            ],
          ),
        );
        
        if (shouldProceed == true) {
          // Import the data
          final success = await HiveService.importDataFromJson(jsonString);
          
          if (success) {
            // Update last backup date in settings
            final settings = HiveService.getSettings() ?? AppSettings();
            final updatedSettings = settings.copyWith(
              lastBackupDate: DateTime.now(),
            );
            await HiveService.saveSettings(updatedSettings);
          }
          
          return success;
        }
      }
      
      return false;
    } catch (e) {
      print('Error importing backup: $e');
      return false;
    }
  }
  
  // Export backup to local file
  static Future<void> exportBackupToFile(BuildContext context, {bool isExcel = false}) async {
    try {
      if (isExcel) {
        await HiveService.shareExcelBackup();
      } else {
        await HiveService.shareJsonBackup();
      }
      
      // Update last backup date in settings
      final settings = HiveService.getSettings() ?? AppSettings();
      final updatedSettings = settings.copyWith(
        lastBackupDate: DateTime.now(),
      );
      await HiveService.saveSettings(updatedSettings);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error exporting backup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Google Drive integration
  
  // Sign in to Google
  static Future<bool> signInToGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }
  
  // Get Google Drive client
  static Future<drive.DriveApi?> _getDriveApi() async {
    final googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) {
      return null;
    }
    
    final googleAuth = await googleUser.authentication;
    final authClient = GoogleAuthClient(googleAuth);
    
    return drive.DriveApi(authClient);
  }
  
  // Upload backup to Google Drive
  static Future<bool> uploadBackupToDrive(BuildContext context) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        final signedIn = await signInToGoogle();
        if (!signedIn) {
          return false;
        }
        return await uploadBackupToDrive(context);
      }
      
      // Get or create backup folder
      String? folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) {
        return false;
      }
      
      // Export data as JSON
      final data = await HiveService.exportDataAsJson();
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      
      // Create file metadata
      final fileName = 'mrship_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [folderId];
      
      // Create media
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: 'application/json',
      );
      
      // Upload file
      await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );
      
      // Update last backup date in settings
      final settings = HiveService.getSettings() ?? AppSettings();
      final updatedSettings = settings.copyWith(
        lastBackupDate: DateTime.now(),
        lastSyncDate: DateTime.now().toIso8601String(),
      );
      await HiveService.saveSettings(updatedSettings);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup uploaded to Google Drive successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      return true;
    } catch (e) {
      print('Error uploading backup to Google Drive: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload backup to Google Drive: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
  
  // Download backup from Google Drive
  static Future<bool> downloadBackupFromDrive(BuildContext context) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        final signedIn = await signInToGoogle();
        if (!signedIn) {
          return false;
        }
        return await downloadBackupFromDrive(context);
      }
      
      // Get backup folder
      String? folderId = await _getBackupFolderId(driveApi);
      if (folderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup folder found on Google Drive'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
      
      // List files in the backup folder
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and mimeType='application/json'",
        orderBy: 'createdTime desc',
      );
      
      final files = fileList.files;
      if (files == null || files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No backup files found on Google Drive'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
      
      // Show file selection dialog
      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Backup File'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final createdTime = file.createdTime ?? DateTime.now();
                return ListTile(
                  title: Text(file.name ?? 'Unnamed backup'),
                  subtitle: Text('Created: ${createdTime.toLocal()}'),
                  onTap: () => Navigator.of(context).pop(file),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (selectedFile == null) {
        return false;
      }
      
      // Show confirmation dialog
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Backup'),
          content: const Text(
            'Importing this backup will replace all existing data. Are you sure you want to proceed?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );
      
      if (shouldProceed != true) {
        return false;
      }
      
      // Download file
      final fileId = selectedFile.id;
      if (fileId == null) {
        return false;
      }
      
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;
      
      final List<int> dataBytes = [];
      await for (final chunk in media.stream) {
        dataBytes.addAll(chunk);
      }
      
      final jsonString = utf8.decode(dataBytes);
      
      // Import the data
      final success = await HiveService.importDataFromJson(jsonString);
      
      if (success) {
        // Update last backup date in settings
        final settings = HiveService.getSettings() ?? AppSettings();
        final updatedSettings = settings.copyWith(
          lastBackupDate: DateTime.now(),
          lastSyncDate: DateTime.now().toIso8601String(),
        );
        await HiveService.saveSettings(updatedSettings);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup imported successfully from Google Drive'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import backup from Google Drive'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return success;
    } catch (e) {
      print('Error downloading backup from Google Drive: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download backup from Google Drive: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
  
  // Helper methods for Google Drive
  
  // Get backup folder ID
  static Future<String?> _getBackupFolderId(drive.DriveApi driveApi) async {
    final folderList = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_backupFolderName'",
    );
    
    final folders = folderList.files;
    if (folders == null || folders.isEmpty) {
      return null;
    }
    
    return folders.first.id;
  }
  
  // Get or create backup folder
  static Future<String?> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    // Check if folder already exists
    String? folderId = await _getBackupFolderId(driveApi);
    if (folderId != null) {
      return folderId;
    }
    
    // Create folder
    final folderMetadata = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    
    final folder = await driveApi.files.create(folderMetadata);
    return folder.id;
  }
}

// Google Auth Client
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(GoogleSignInAuthentication auth)
      : _headers = {
          'Authorization': 'Bearer ${auth.accessToken ?? ''}',
          'Content-Type': 'application/json',
        };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
