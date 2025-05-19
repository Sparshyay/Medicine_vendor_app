import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;
  bool _isLoading = true;
  bool _isAuthEnabled = false;
  bool _isAutoBackupEnabled = false;
  int _autoBackupFrequency = 7;
  bool _isDarkModeEnabled = false;
  DateTime? _lastBackupDate;
  String? _lastSyncDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final settings = HiveService.getSettings();
    if (settings != null) {
      setState(() {
        _settings = settings;
        _isAuthEnabled = settings.isAuthEnabled;
        _isAutoBackupEnabled = settings.isAutoBackupEnabled;
        _autoBackupFrequency = settings.autoBackupFrequencyDays;
        _isDarkModeEnabled = settings.isDarkModeEnabled;
        _lastBackupDate = settings.lastBackupDate;
        _lastSyncDate = settings.lastSyncDate;
      });
    } else {
      // Create default settings
      final defaultSettings = AppSettings(
        isAuthEnabled: false,
        isAutoBackupEnabled: false,
        autoBackupFrequencyDays: 7,
        isDarkModeEnabled: false,
      );
      await HiveService.saveSettings(defaultSettings);
      setState(() {
        _settings = defaultSettings;
        _isAuthEnabled = defaultSettings.isAuthEnabled;
        _isAutoBackupEnabled = defaultSettings.isAutoBackupEnabled;
        _autoBackupFrequency = defaultSettings.autoBackupFrequencyDays;
        _isDarkModeEnabled = defaultSettings.isDarkModeEnabled;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    final updatedSettings = _settings!.copyWith(
      isAuthEnabled: _isAuthEnabled,
      isAutoBackupEnabled: _isAutoBackupEnabled,
      autoBackupFrequencyDays: _autoBackupFrequency,
      isDarkModeEnabled: _isDarkModeEnabled,
    );

    await HiveService.saveSettings(updatedSettings);
    await AuthService.setAuthEnabled(_isAuthEnabled);

    setState(() {
      _settings = updatedSettings;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportBackup({bool isExcel = false}) async {
    await BackupService.exportBackupToFile(context, isExcel: isExcel);
    _loadSettings(); // Refresh settings to update last backup date
  }

  Future<void> _importBackup() async {
    final success = await BackupService.importBackupFromFile(context);
    if (success) {
      _loadSettings(); // Refresh settings to update last backup date
    }
  }

  Future<void> _uploadToGoogleDrive() async {
    final success = await BackupService.uploadBackupToDrive(context);
    if (success) {
      _loadSettings(); // Refresh settings to update last sync date
    }
  }

  Future<void> _downloadFromGoogleDrive() async {
    final success = await BackupService.downloadBackupFromDrive(context);
    if (success) {
      _loadSettings(); // Refresh settings to update last sync date
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Security Section
                _buildSectionHeader(context, 'Security', Icons.security),
                SwitchListTile(
                  title: const Text('Enable PIN Authentication'),
                  subtitle: const Text('Require PIN to access the app'),
                  value: _isAuthEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isAuthEnabled = value;
                    });
                    if (value) {
                      // Show dialog to set up PIN
                      _showPinSetupDialog();
                    }
                  },
                ),
                const Divider(),

                // Backup & Restore Section
                _buildSectionHeader(context, 'Backup & Restore', Icons.backup),
                ListTile(
                  title: const Text('Last Backup'),
                  subtitle: Text(_formatDate(_lastBackupDate)),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                ),
                SwitchListTile(
                  title: const Text('Auto Backup'),
                  subtitle: const Text('Automatically backup your data'),
                  value: _isAutoBackupEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isAutoBackupEnabled = value;
                    });
                  },
                ),
                if (_isAutoBackupEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: Row(
                      children: [
                        const Text('Backup Frequency: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int>(
                            value: _autoBackupFrequency,
                            isExpanded: true,
                            items: [1, 3, 7, 14, 30].map((days) {
                              return DropdownMenuItem<int>(
                                value: days,
                                child: Text(days == 1 ? 'Daily' : '$days days'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _autoBackupFrequency = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),

                // Manual Backup Options
                _buildSectionHeader(context, 'Manual Backup', Icons.save_alt),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export as JSON'),
                  subtitle: const Text('Export all data as a JSON file'),
                  onTap: () => _exportBackup(isExcel: false),
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Export as Excel'),
                  subtitle: const Text('Export all data as an Excel file'),
                  onTap: () => _exportBackup(isExcel: true),
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Backup'),
                  subtitle: const Text('Restore data from a backup file'),
                  onTap: _importBackup,
                ),
                const Divider(),

                // Google Drive Integration
                _buildSectionHeader(context, 'Google Drive', Icons.cloud),
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text('Upload to Google Drive'),
                  subtitle: const Text('Save your backup to Google Drive'),
                  onTap: _uploadToGoogleDrive,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download),
                  title: const Text('Download from Google Drive'),
                  subtitle: const Text('Restore from Google Drive backup'),
                  onTap: _downloadFromGoogleDrive,
                ),
                if (_lastSyncDate != null)
                  ListTile(
                    title: const Text('Last Google Drive Sync'),
                    subtitle: Text(_lastSyncDate ?? 'Never'),
                    trailing: const Icon(Icons.sync, size: 20),
                  ),
                const Divider(),

                // Appearance
                _buildSectionHeader(context, 'Appearance', Icons.palette),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark mode theme'),
                  value: _isDarkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isDarkModeEnabled = value;
                    });
                  },
                ),
                const Divider(),

                // Danger Zone
                _buildSectionHeader(context, 'Danger Zone', Icons.warning, color: Colors.red),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red[700]),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all app data (cannot be undone)'),
                  onTap: _showClearDataConfirmation,
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPinSetupDialog() {
    final TextEditingController pinController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a PIN to secure your app (minimum 4 digits)'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '• • • • • •',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Reset the switch if user cancels
                this.setState(() {
                  _isAuthEnabled = false;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.length < 4) {
                  setState(() {
                    errorMessage = 'PIN must be at least 4 digits';
                  });
                  return;
                }

                await AuthService.setPin(pin);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN set successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Set PIN'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your data including medicines, doctors, and brochures. This action cannot be undone.\n\nAre you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await HiveService.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data has been cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
