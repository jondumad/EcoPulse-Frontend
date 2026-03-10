import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_error_message.dart';
import '../utils/validation_utils.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String _selectedRole = 'Volunteer';
  bool _tosAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isThrottled = false;
  String? _errorMessage;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  Timer? _throttleTimer;

  // ── [PLACEHOLDER] Avatar/photo picker ───────────────────────
  // TODO: wire up image_picker package
  // ImageProvider? _avatarImage;

  static const _roles = [
    _Role(
      name: 'Volunteer',
      icon: Icons.eco_rounded,
      tagline: 'Participate in missions',
      detail: 'Join cleanup drives, earn eco-points, and track your impact.',
    ),
    _Role(
      name: 'Coordinator',
      icon: Icons.groups_rounded,
      tagline: 'Organise missions',
      detail:
          'Create and manage your own environmental missions for your community.',
    ),
  ];

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
    _passwordController.addListener(_onPasswordChanged);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _throttleTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
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
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_tosAccepted) {
      setState(
        () =>
            _errorMessage = 'You must accept the Terms of Service to continue.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
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
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth > 480 ? 440 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopRow(onBack: () => Navigator.pop(context)),
                      const SizedBox(height: 28),

                      _Headline(),
                      const SizedBox(height: 28),

                      _RoleSelector(
                        roles: _roles,
                        selectedRole: _selectedRole,
                        onSelect: (r) => setState(() => _selectedRole = r),
                      ),
                      const SizedBox(height: 20),

                      _FormCard(
                        formKey: _formKey,
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        nameFocus: _nameFocus,
                        emailFocus: _emailFocus,
                        passwordFocus: _passwordFocus,
                        confirmFocus: _confirmFocus,
                        obscurePassword: _obscurePassword,
                        obscureConfirm: _obscureConfirm,
                        passwordStrength: _passwordStrength,
                        tosAccepted: _tosAccepted,
                        errorMessage: _errorMessage,
                        isLoading: auth.isLoading,
                        isThrottled: _isThrottled,
                        onToggleObscurePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onToggleObscureConfirm: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        onTosChanged: (v) =>
                            setState(() => _tosAccepted = v ?? false),
                        onSubmit: _throttledSubmit,
                        onTermsTap: () {
                          /* TODO: push /terms */
                        },
                        onPrivacyTap: () {
                          /* TODO: push /privacy */
                        },
                      ),

                      const SizedBox(height: 24),

                      _LoginCta(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                      ),

                      const SizedBox(height: 12),
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

class _TopRow extends StatelessWidget {
  const _TopRow({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: AppTheme.shadowSoft,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: AppTheme.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.forest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 7),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppTheme.ink,
                ),
                children: [
                  TextSpan(text: 'Eco'),
                  TextSpan(
                    text: 'Pulse',
                    style: TextStyle(color: AppTheme.terracotta),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Join the\nmovement.',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1.1,
            color: AppTheme.ink,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Choose your role and start making an impact.',
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

class _Role {
  const _Role({
    required this.name,
    required this.icon,
    required this.tagline,
    required this.detail,
  });
  final String name;
  final IconData icon;
  final String tagline;
  final String detail;
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.roles,
    required this.selectedRole,
    required this.onSelect,
  });

  final List<_Role> roles;
  final String selectedRole;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: roles.map((role) {
        final selected = selectedRole == role.name;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: role == roles.first ? 0 : 6,
              right: role == roles.last ? 0 : 6,
            ),
            child: Tooltip(
              message: role.detail,
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: false,
              decoration: BoxDecoration(
                color: AppTheme.forest,
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: Colors.white,
              ),
              child: GestureDetector(
                onTap: () => onSelect(role.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.forestLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppTheme.forest : AppTheme.borderSubtle,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? AppTheme.shadowForest
                        : AppTheme.shadowSoft,
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.forest : AppTheme.clay,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          role.icon,
                          size: 20,
                          color: selected ? Colors.white : AppTheme.inkTertiary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        role.name,
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: selected ? AppTheme.forest : AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: selected
                              ? AppTheme.forest
                              : AppTheme.inkTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.passwordStrength,
    required this.tosAccepted,
    required this.errorMessage,
    required this.isLoading,
    required this.isThrottled,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirm,
    required this.onTosChanged,
    required this.onSubmit,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode nameFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final bool obscurePassword;
  final bool obscureConfirm;
  final PasswordStrength passwordStrength;
  final bool tosAccepted;
  final String? errorMessage;
  final bool isLoading;
  final bool isThrottled;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirm;
  final ValueChanged<bool?> onTosChanged;
  final VoidCallback onSubmit;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

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
            // Error banner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: errorMessage != null
                  ? Padding(
                      key: const ValueKey('err'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AuthErrorMessage(
                        errorMessage: errorMessage,
                        isVisible: true,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-err')),
            ),

            // Full name
            _EcoField(
              controller: nameController,
              focusNode: nameFocus,
              label: 'Full name',
              hint: 'Alex Kim',
              keyboardType: TextInputType.name,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              onEditingComplete: () => emailFocus.requestFocus(),
              validator: ValidationUtils.validateName,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),

            // Email
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

            // Password
            _EcoField(
              controller: passwordController,
              focusNode: passwordFocus,
              label: 'Password',
              hint: 'Min 8 chars, 1 uppercase, 1 number',
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onEditingComplete: () => confirmFocus.requestFocus(),
              validator: ValidationUtils.validatePassword,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: GestureDetector(
                onTap: onToggleObscurePassword,
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppTheme.inkTertiary,
                ),
              ),
            ),

            // Password strength meter
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: passwordController.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _PasswordStrengthBar(strength: passwordStrength),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // Confirm password
            _EcoField(
              controller: confirmPasswordController,
              focusNode: confirmFocus,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              obscureText: obscureConfirm,
              textInputAction: TextInputAction.done,
              onEditingComplete: onSubmit,
              validator: (v) => ValidationUtils.validateConfirmPassword(
                v,
                passwordController.text,
              ),
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: GestureDetector(
                onTap: onToggleObscureConfirm,
                child: Icon(
                  obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppTheme.inkTertiary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── [PLACEHOLDER] Referral code field ─────────────────
            // TODO: optional — add backend redemption logic
            // _EcoField(label: 'Referral code (optional)', hint: 'ECO-XXXX', ...),

            // ToS row
            _TosRow(
              accepted: tosAccepted,
              onChanged: onTosChanged,
              onTermsTap: onTermsTap,
              onPrivacyTap: onPrivacyTap,
            ),
            const SizedBox(height: 22),

            // CTA
            _PrimaryButton(
              label: 'Create account',
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

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final PasswordStrength strength;

  static const _segments = 4;

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:
        return AppTheme.terracotta;
      case PasswordStrength.fair:
        return AppTheme.amber;
      case PasswordStrength.good:
        return AppTheme.forest;
      case PasswordStrength.strong:
        return AppTheme.forest;
    }
  }

  int get _filledCount {
    switch (strength) {
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.fair:
        return 2;
      case PasswordStrength.good:
        return 3;
      case PasswordStrength.strong:
        return 4;
    }
  }

  String get _label => ValidationUtils.getStrengthLabel(strength);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Segmented bar
        ...List.generate(_segments, (i) {
          final filled = i < _filledCount;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _segments - 1 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? _color : AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        // Label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _label,
            key: ValueKey(_label),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TosRow extends StatelessWidget {
  const _TosRow({
    required this.accepted,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool accepted;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: accepted,
              onChanged: onChanged,
              activeColor: AppTheme.forest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppTheme.inkSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  WidgetSpan(
                    baseline: TextBaseline.alphabetic,
                    alignment: PlaceholderAlignment.baseline,
                    child: GestureDetector(
                      onTap: onTermsTap,
                      child: const Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forest,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.forest,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    baseline: TextBaseline.alphabetic,
                    alignment: PlaceholderAlignment.baseline,
                    child: GestureDetector(
                      onTap: onPrivacyTap,
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forest,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.forest,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCta extends StatelessWidget {
  const _LoginCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: AppTheme.inkSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Sign in',
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
              borderSide: const BorderSide(
                color: AppTheme.terracotta,
                width: 1.5,
              ),
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
          color: active
              ? AppTheme.forest
              : AppTheme.forest.withValues(alpha: 0.5),
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
