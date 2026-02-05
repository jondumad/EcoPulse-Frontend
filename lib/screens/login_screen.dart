import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../widgets/auth_error_message.dart';
import '../utils/validation_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  String? _errorMessage;
  Timer? _throttleTimer;
  bool _isThrottled = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _throttledSubmit() {
    if (_isThrottled) return;

    _isThrottled = true;
    _submit();

    // Prevent re-submission for 2 seconds
    _throttleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isThrottled = false);
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        final result = await authProvider.login(
          _emailController.text,
          _passwordController.text,
          rememberMe: _rememberMe,
        );

        if (mounted) {
          if (!result['success']) {
            setState(() {
              _errorMessage = result['message'];
            });
            // Also announce for accessibility if needed via logic in AuthErrorMessage
          } else {
            // Success - Navigation handled via Main or direct pushReplacement
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "An unexpected error occurred. Please try again.";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, size: 60, color: EcoColors.forest),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: EcoText.displayLG(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your impact.',
                style: EcoText.bodyMD(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              EcoPulseCard(
                variant: CardVariant.paper,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthErrorMessage(
                        errorMessage: _errorMessage,
                        isVisible: _errorMessage != null,
                      ),

                      EcoTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: ValidationUtils.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      EcoTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        validator: (val) => val == null || val.isEmpty
                            ? 'Password is required'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Remember Me & Forgot Password Row
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: EcoColors.forest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: EcoText.bodySM(context)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // TODO: Implement Forgot Password Flow
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Forgot Password flow coming soon!',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: EcoText.bodySM(context).copyWith(
                                color: EcoColors.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      EcoPulseButton(
                        label: 'Login',
                        onPressed: _isThrottled ? null : _throttledSubmit,
                        isLoading: Provider.of<AuthProvider>(context).isLoading,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New to Eco-Pulse? ', style: EcoText.bodyMD(context)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: EcoColors.forest,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
