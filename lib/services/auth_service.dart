import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'hive_service.dart';

class AuthService {
  static const String _pinKey = 'app_pin';
  static const String _isAuthEnabledKey = 'is_auth_enabled';
  static const String _isLoggedInKey = 'is_logged_in';
  
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Check if authentication is enabled
  static Future<bool> isAuthEnabled() async {
    try {
      final settings = HiveService.getSettings();
      if (settings != null) {
        return settings.isAuthEnabled;
      }
      
      // Fallback to shared preferences if Hive settings not available
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isAuthEnabledKey) ?? false;
    } catch (e) {
      print('Error checking if auth is enabled: $e');
      return false; // Default to no authentication if there's an error
    }
  }
  
  // Enable or disable authentication
  static Future<void> setAuthEnabled(bool enabled) async {
    final settings = HiveService.getSettings() ?? 
        AppSettings(isAuthEnabled: false);
    
    final updatedSettings = settings.copyWith(isAuthEnabled: enabled);
    await HiveService.saveSettings(updatedSettings);
    
    // Also update shared preferences as a backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthEnabledKey, enabled);
  }
  
  // Set a new PIN
  static Future<void> setPin(String pin) async {
    // Store PIN securely
    await _secureStorage.write(key: _pinKey, value: pin);
    
    // Update settings
    final settings = HiveService.getSettings() ?? 
        AppSettings(isAuthEnabled: true);
    
    final updatedSettings = settings.copyWith(
      pin: pin,
      isAuthEnabled: true,
    );
    await HiveService.saveSettings(updatedSettings);
  }
  
  // Verify PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      
      // If no PIN is stored yet, any PIN is valid (first-time setup)
      if (storedPin == null) {
        return true;
      }
      
      return storedPin == pin;
    } catch (e) {
      print('Error verifying PIN: $e');
      // In case of error, allow access (better UX than being locked out)
      return true;
    }
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking if user is logged in: $e');
      return false;
    }
  }
  
  // Set logged in status
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }
  
  // Log out user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }
  
  // Check if PIN exists
  static Future<bool> hasPinSet() async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    return storedPin != null && storedPin.isNotEmpty;
  }
  
  // Reset PIN (for forgotten PIN)
  static Future<void> resetPin() async {
    await _secureStorage.delete(key: _pinKey);
    
    final settings = HiveService.getSettings();
    if (settings != null) {
      final updatedSettings = settings.copyWith(
        pin: null,
        isAuthEnabled: false,
      );
      await HiveService.saveSettings(updatedSettings);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthEnabledKey, false);
    await prefs.setBool(_isLoggedInKey, false);
  }
}
