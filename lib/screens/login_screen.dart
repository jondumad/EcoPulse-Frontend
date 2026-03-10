import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/eco_pulse_widgets.dart';
import '../widgets/auth_error_message.dart';
import '../utils/validation_utils.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ── State ───────────────────────────────────────────────────
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isThrottled = false;
  String? _errorMessage;
  Timer? _throttleTimer;

  // ── [PLACEHOLDER] Biometric auth flag ──────────────────────
  // TODO: wire up local_auth package; check availability on init
  final bool _biometricAvailable = true;

  // ── [PLACEHOLDER] Social login loading states ───────────────
  // TODO: wire up google_sign_in / Sign in with Apple packages
  bool _googleLoading = false;
  bool _appleLoading = false;

  // ── Entrance animation ──────────────────────────────────────
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _throttleTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────
  void _throttledSubmit() {
    if (_isThrottled) return;
    _isThrottled = true;
    _submit();
    _throttleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isThrottled = false);
    });
  }

  Future<void> _submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _errorMessage = result['message']);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  // ── [PLACEHOLDER] Biometric login ──────────────────────────
  // TODO: replace body with local_auth authenticate() call
  Future<void> _biometricLogin() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_buildSnackBar('Biometric login coming soon.'));
  }

  // ── [PLACEHOLDER] Google login ──────────────────────────────
  Future<void> _googleLogin() async {
    setState(() => _googleLoading = true);
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // remove when wired
    if (mounted) setState(() => _googleLoading = false);
    // TODO: GoogleSignIn().signIn() → send token to backend
  }

  // ── [PLACEHOLDER] Apple login ───────────────────────────────
  Future<void> _appleLogin() async {
    setState(() => _appleLoading = true);
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // remove when wired
    if (mounted) setState(() => _appleLoading = false);
    // TODO: SignInWithApple.getAppleIDCredential() → send to backend
  }

  // ── Helpers ─────────────────────────────────────────────────
  SnackBar _buildSnackBar(String message) => SnackBar(
    content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
    backgroundColor: AppTheme.forest,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoading = auth.isLoading;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.clay,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  // Cap card width on larger phones/tablets
                  constraints: BoxConstraints(
                    maxWidth: screenWidth > 480 ? 440 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Wordmark ────────────────────────────────────
                      _Wordmark(),
                      const SizedBox(height: 36),

                      // ── Main card ───────────────────────────────────
                      _LoginCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        emailFocus: _emailFocus,
                        passwordFocus: _passwordFocus,
                        rememberMe: _rememberMe,
                        obscurePassword: _obscurePassword,
                        errorMessage: _errorMessage,
                        isLoading: isLoading,
                        isThrottled: _isThrottled,
                        onRememberMeChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onSubmit: _throttledSubmit,
                        onForgotPassword: () =>
                            Navigator.pushNamed(context, '/forgot-password'),
                      ),

                      const SizedBox(height: 20),

                      // ── [PLACEHOLDER] Social divider + buttons ──────
                      _SocialDivider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              label: 'Google',
                              isLoading: _googleLoading,
                              icon: _GoogleIcon(),
                              onTap: _googleLogin,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SocialButton(
                              label: 'Apple',
                              isLoading: _appleLoading,
                              icon: const Icon(
                                Icons.apple,
                                size: 18,
                                color: AppTheme.ink,
                              ),
                              onTap: _appleLogin,
                            ),
                          ),
                        ],
                      ),

                      // ── [PLACEHOLDER] Biometric shortcut ────────────
                      if (_biometricAvailable) ...[
                        const SizedBox(height: 16),
                        _BiometricButton(onTap: _biometricLogin),
                      ],

                      const SizedBox(height: 28),

                      // ── Register CTA ────────────────────────────────
                      _RegisterCta(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                      ),

                      const SizedBox(height: 16),

                      // ── [PLACEHOLDER] Terms note ─────────────────────
                      // TODO: link to actual Terms & Privacy pages
                      _TermsNote(
                        onTermsTap: () {
                          /* push /terms */
                        },
                        onPrivacyTap: () {
                          /* push /privacy */
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo mark — forest circle + leaf icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.forest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.shadowForest,
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 20),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1.1,
              color: AppTheme.ink,
            ),
            children: [TextSpan(text: 'Welcome\nback')],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to continue your impact.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.inkSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.rememberMe,
    required this.obscurePassword,
    required this.errorMessage,
    required this.isLoading,
    required this.isThrottled,
    required this.onRememberMeChanged,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool rememberMe;
  final bool obscurePassword;
  final String? errorMessage;
  final bool isLoading;
  final bool isThrottled;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: errorMessage != null
                  ? Padding(
                      key: const ValueKey('error'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AuthErrorMessage(
                        errorMessage: errorMessage,
                        isVisible: true,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-error')),
            ),

            // Email field
            _EcoField(
              controller: emailController,
              focusNode: emailFocus,
              label: 'Email address',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              onEditingComplete: () => passwordFocus.requestFocus(),
              validator: ValidationUtils.validateEmail,
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: 14),

            // Password field
            _EcoField(
              controller: passwordController,
              focusNode: passwordFocus,
              label: 'Password',
              hint: 'Enter your password',
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onEditingComplete: onSubmit,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppTheme.inkTertiary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Remember me + forgot password row
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: onRememberMeChanged,
                    activeColor: AppTheme.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.inkSecondary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.forest,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Primary CTA
            _PrimaryButton(
              label: 'Sign in',
              isLoading: isLoading,
              disabled: isThrottled,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _EcoField extends StatelessWidget {
  const _EcoField({
    required this.controller,
    required this.label,
    required this.hint,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.onEditingComplete,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.inkTertiary,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 17, color: AppTheme.inkTertiary)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.clay,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.forest, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.terracotta),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.terracotta, width: 1.5),
            ),
            errorStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppTheme.terracotta,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final active = !disabled && !isLoading;

    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        decoration: BoxDecoration(
          color: active ? AppTheme.forest : AppTheme.forest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: active ? AppTheme.shadowForest : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppTheme.borderSubtle, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkTertiary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.borderSubtle, thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: AppTheme.shadowSoft,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.forest),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.forestLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.forest.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fingerprint_rounded, size: 20, color: AppTheme.forest),
            SizedBox(width: 8),
            Text(
              'Sign in with biometrics',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterCta extends StatelessWidget {
  const _RegisterCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "New to EcoPulse? ",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: AppTheme.inkSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Create account',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.forest,
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsNote extends StatelessWidget {
  const _TermsNote({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'By signing in you agree to our ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.inkTertiary,
            ),
          ),
          GestureDetector(
            onTap: onTermsTap,
            child: const Text(
              'Terms',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text(
            ' and ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.inkTertiary,
            ),
          ),
          GestureDetector(
            onTap: onPrivacyTap,
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text(
            '.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: replace with SvgPicture.asset('assets/icons/google.svg')
    //       or use font_awesome_flutter package
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppTheme.clay,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppTheme.terracotta,
          ),
        ),
      ),
    );
  }
}
