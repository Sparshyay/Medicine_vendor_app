import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../widgets/olamic_logo.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final bool isNewUser;

  const LoginScreen({
    Key? key,
    required this.onLoginSuccess,
    this.isNewUser = false,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPinSetup = false;
  bool _isConfirmingPin = false;
  String _setupPin = '';

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await AuthService.hasPinSet();
    setState(() {
      _isPinSetup = hasPin;
      // If widget says this is a new user, override the pin setup status
      if (widget.isNewUser) {
        _isPinSetup = false;
      }
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final pin = _pinController.text.trim();
      if (pin.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your PIN';
          _isLoading = false;
        });
        return;
      }

      final isValid = await AuthService.verifyPin(pin);
      if (isValid) {
        await AuthService.setLoggedIn(true);
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupNewPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final pin = _pinController.text.trim();
      if (pin.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a PIN';
          _isLoading = false;
        });
        return;
      }

      if (pin.length < 4) {
        setState(() {
          _errorMessage = 'PIN must be at least 4 digits';
          _isLoading = false;
        });
        return;
      }

      if (!_isConfirmingPin) {
        // First time entering PIN
        setState(() {
          _setupPin = pin;
          _isConfirmingPin = true;
          _pinController.clear();
        });
      } else {
        // Confirming PIN
        if (pin == _setupPin) {
          // PINs match, save it
          await AuthService.setPin(pin);
          await AuthService.setAuthEnabled(true);
          await AuthService.setLoggedIn(true);
          widget.onLoginSuccess();
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Please try again.';
            _isConfirmingPin = false;
            _setupPin = '';
            _pinController.clear();
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isConfirmingPin = false;
        _setupPin = '';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo and animation
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Company logo
                const OlamicLogo(
                  width: 250,
                  height: 120,
                ),
                const SizedBox(height: 24),
                
                // App title
                Text(
                  'MRship App',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // App subtitle
                Text(
                  _isPinSetup 
                      ? 'Enter your PIN to continue' 
                      : _isConfirmingPin 
                          ? 'Confirm your PIN' 
                          : 'Create a PIN to secure your data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Additional instruction text
                Text(
                  _isPinSetup 
                      ? 'Welcome back! Please enter your PIN to access the app.' 
                      : _isConfirmingPin 
                          ? 'Please re-enter your PIN to confirm' 
                          : 'Welcome to MRship App! Please create a PIN to secure your data.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // PIN input
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) {
                    _isPinSetup ? _verifyPin() : _setupNewPin();
                  },
                ),
                const SizedBox(height: 16),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : () => _isPinSetup ? _verifyPin() : _setupNewPin(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isPinSetup 
                                ? 'Login' 
                                : _isConfirmingPin 
                                    ? 'Confirm PIN' 
                                    : 'Create PIN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                // Reset PIN option (only if PIN is already set up)
                if (_isPinSetup)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset PIN?'),
                            content: const Text(
                              'This will reset your PIN and you will need to create a new one. Continue?'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await AuthService.resetPin();
                                  setState(() {
                                    _isPinSetup = false;
                                    _isConfirmingPin = false;
                                    _setupPin = '';
                                    _pinController.clear();
                                    _errorMessage = '';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Forgot PIN?'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
