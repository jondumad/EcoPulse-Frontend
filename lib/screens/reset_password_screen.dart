import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../widgets/auth_error_message.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.token);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _errorMessage = "Passwords do not match");
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        final result = await authProvider.resetPassword(
          _tokenController.text,
          _passwordController.text,
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Password reset successfully! Please login.')),
            );
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            setState(() {
              _errorMessage = result['message'];
            });
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: EcoColors.forest),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.vpn_key, size: 60, color: EcoColors.forest),
                const SizedBox(height: 24),
                Text(
                  'Reset Password',
                  style: EcoText.displayLG(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the reset token and your new password.',
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
                          controller: _tokenController,
                          label: 'Reset Token',
                          hint: 'Enter token from email',
                          validator: (val) => val == null || val.isEmpty
                              ? 'Token is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        EcoTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hint: 'Enter new password',
                          obscureText: true,
                          validator: (val) => val == null || val.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        EcoTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Confirm new password',
                          obscureText: true,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please confirm your password'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        EcoPulseButton(
                          label: 'Reset Password',
                          onPressed: _submit,
                          isLoading:
                              Provider.of<AuthProvider>(context).isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
