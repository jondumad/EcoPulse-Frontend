import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../widgets/eco_app_bar.dart';
import '../widgets/auth_error_message.dart';
import '../theme/app_theme.dart';
import '../utils/validation_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Added

  String _selectedRole = 'Volunteer';
  bool _tosAccepted = false; // Added
  String? _errorMessage;
  PasswordStrength _passwordStrength = PasswordStrength.weak; // Added
  Timer? _throttleTimer;
  bool _isThrottled = false;

  final List<Map<String, dynamic>> _roles = [
    {
      'name': 'Volunteer',
      'icon': Icons.volunteer_activism,
      'description': 'Participate in missions',
      'detail': 'Join cleanup drives and earn eco-points.',
    },
    {
      'name': 'Coordinator',
      'icon': Icons.group_work,
      'description': 'Organize missions',
      'detail': 'Create and manage your own environmental missions.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _throttleTimer?.cancel();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = ValidationUtils.calculatePasswordStrength(
        _passwordController.text,
      );
    });
  }

  void _throttledSubmit() {
    if (_isThrottled) return;
    _isThrottled = true;
    _submit();
    _throttleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isThrottled = false);
    });
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_tosAccepted) {
      setState(
        () =>
            _errorMessage = 'You must accept the Terms of Service to continue.',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        final result = await authProvider.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          _selectedRole,
        );

        if (mounted) {
          if (!result['success']) {
            setState(() => _errorMessage = result['message']);
          } else {
            // Check if verification is needed (future-proof) or go to login/dashboard
            // For now, redirect to login with a success message or directly to dashboard if auto-logged in
            // Assuming auto-login:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'An unexpected error occurred.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      appBar: EcoAppBar(
        height: 100,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECOVERY & AUTH',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create Account',
              style: AppTheme.lightTheme.textTheme.displayLarge,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join the Movement', style: EcoText.displayLG(context)),
            const SizedBox(height: 8),
            Text(
              'Select your role to get started.',
              style: EcoText.bodyMD(context),
            ),
            const SizedBox(height: 24),

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

                    // Role Selection
                    Row(
                      children: _roles.map((role) {
                        final isSelected = _selectedRole == role['name'];
                        return Expanded(
                          child: Tooltip(
                            message: role['detail'],
                            triggerMode: TooltipTriggerMode.tap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _selectedRole = role['name'],
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? EcoColors.forest.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? EcoColors.forest
                                          : EcoColors.paperShadow,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        role['icon'],
                                        color: isSelected
                                            ? EcoColors.forest
                                            : EcoColors.ink,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        role['name'],
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? EcoColors.forest
                                              : EcoColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        role['description'],
                                        textAlign: TextAlign.center,
                                        style: EcoText.bodySM(
                                          context,
                                        ).copyWith(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    EcoTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'John Doe',
                      keyboardType: TextInputType.name,
                      autofillHints: const [AutofillHints.name],
                      validator: ValidationUtils.validateName,
                    ),
                    const SizedBox(height: 16),

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
                      hint: 'Min 8 chars, 1 uppercase, 1 number',
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: ValidationUtils.validatePassword,
                    ),

                    // Password Strength Indicator
                    if (_passwordController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 80,
                              height: 4,
                              decoration: BoxDecoration(
                                color: ValidationUtils.getStrengthColor(
                                  _passwordStrength,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ValidationUtils.getStrengthLabel(
                                _passwordStrength,
                              ),
                              style: TextStyle(
                                color: ValidationUtils.getStrengthColor(
                                  _passwordStrength,
                                ),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    EcoTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      obscureText: true,
                      validator: (val) =>
                          ValidationUtils.validateConfirmPassword(
                            val,
                            _passwordController.text,
                          ),
                    ),

                    const SizedBox(height: 24),

                    // TOS Checkbox
                    InkWell(
                      onTap: () => setState(() => _tosAccepted = !_tosAccepted),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _tosAccepted,
                            activeColor: EcoColors.forest,
                            onChanged: (val) =>
                                setState(() => _tosAccepted = val ?? false),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: EcoText.bodySM(context),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(
                                      color: EcoColors.forest,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    // In a real app, add recognizer to open webview
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: EcoColors.forest,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    // In a real app, add recognizer to open webview
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    EcoPulseButton(
                      label: 'Create Account',
                      onPressed: _isThrottled ? null : _throttledSubmit,
                      isLoading: Provider.of<AuthProvider>(context).isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
