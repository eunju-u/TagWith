import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_snackbar.dart';
import '../../core/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_icons.dart';
import '../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _isSignUp = false;
  bool _isCodeSent = false;
  bool _isEmailVerified = false;
  bool _isVerifying = false;
  bool _obscurePassword = true;
  bool _isFindPassword = false;
  bool _isResetCodeSent = false;
  bool _isResetCodeVerified = false;
  final _storage = const FlutterSecureStorage();

  Future<bool> _canRequestVerification() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    final lastDate = await _storage.read(key: 'last_verification_date');
    final countStr = await _storage.read(key: 'verification_request_count');
    int count = int.tryParse(countStr ?? '0') ?? 0;

    if (lastDate != todayStr) {
      // New day, reset count
      await _storage.write(key: 'last_verification_date', value: todayStr);
      await _storage.write(key: 'verification_request_count', value: '0');
      return true;
    }

    if (count >= 5) {
      return false;
    }

    return true;
  }

  Future<void> _incrementRequestCount() async {
    final countStr = await _storage.read(key: 'verification_request_count');
    int count = int.tryParse(countStr ?? '0') ?? 0;
    await _storage.write(key: 'verification_request_count', value: (count + 1).toString());
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라데이션 및 디자인 요소
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고 및 브랜드 이름
                    Image.asset(
                      'assets/icons/app_logo.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.outfit(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 로그인 카드 (Glassmorphism 효과)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38), // 0.15 alpha
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withAlpha(51), // 0.2 alpha
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_isFindPassword) ...[
                            _buildFindPasswordUI(context, authProvider, theme),
                          ] else if (_isSignUp) ...[
                            _buildSignUpUI(context, authProvider, theme),
                          ] else ...[
                            _buildLoginUI(context, authProvider, theme),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginUI(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          hint: AppStrings.emailHint,
          icon: AppIcons.email,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: AppStrings.passwordHint,
          icon: AppIcons.password,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: authProvider.status == AuthStatus.loading
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  final success = await authProvider.signInWithEmail(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (mounted) {
                    AppSnackBar.show(context, success ? AppStrings.loginSuccess : AppStrings.loginFailed);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: authProvider.status == AuthStatus.loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text(AppStrings.loginButton, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _isFindPassword = true),
              child: const Text(AppStrings.forgotPasswordQuestion, style: TextStyle(color: Colors.white70)),
            ),
            const Text('|', style: TextStyle(color: Colors.white38)),
            TextButton(
              onPressed: () => setState(() => _isSignUp = true),
              child: const Text(AppStrings.signUpButton, style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpUI(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          hint: AppStrings.nameHint,
          icon: AppIcons.person,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          hint: AppStrings.emailHint,
          icon: AppIcons.email,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isEmailVerified ? null : () async {
              if (_emailController.text.isEmpty) {
                AppSnackBar.show(context, AppStrings.enterEmail);
                return;
              }
              final canRequest = await _canRequestVerification();
              if (!canRequest) {
                AppSnackBar.show(context, AppStrings.dailyLimitExceeded);
                return;
              }
              final success = await authProvider.sendVerificationCode(_emailController.text);
              if (success) {
                await _incrementRequestCount();
                setState(() => _isCodeSent = true);
                AppSnackBar.show(context, AppStrings.verificationCodeSent);
              } else {
                AppSnackBar.show(context, AppStrings.verificationCodeFailed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_isEmailVerified ? AppStrings.verificationDone : AppStrings.verificationRequest),
          ),
        ),
        if (_isCodeSent && !_isEmailVerified) ...[
          const SizedBox(height: 16),
          _buildVerificationRow(authProvider, theme),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: AppStrings.passwordHint,
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (!_isEmailVerified) {
              AppSnackBar.show(context, AppStrings.completeEmailVerification);
              return;
            }
            final success = await authProvider.signUpWithEmail(
              _emailController.text,
              _passwordController.text,
              _nameController.text,
            );
            if (mounted) {
              AppSnackBar.show(context, success ? AppStrings.signUpSuccess : AppStrings.signUpFailed);
              if (success) setState(() => _isSignUp = false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text(AppStrings.signUpButton, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              Text(
                AppStrings.privacyAgreementPrefix,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(AppStrings.privacyPolicyUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  AppStrings.privacyPolicyLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
              ),
              Text(
                AppStrings.privacyAgreementSuffix,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 0),
        TextButton(
          onPressed: () => setState(() => _isSignUp = false),
          child: const Text(AppStrings.alreadyHaveAccount, style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildFindPasswordUI(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          hint: AppStrings.enterRegisteredEmail,
          icon: AppIcons.email,
        ),
        const SizedBox(height: 12),
        if (!_isResetCodeVerified)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (_emailController.text.isEmpty) return;
                try {
                  AppLoadingOverlay.show(context);
                  final success = await authProvider.forgotPassword(_emailController.text);
                  if (success) {
                    setState(() => _isResetCodeSent = true);
                    AppSnackBar.show(context, AppStrings.verificationCodeSent);
                  } else {
                    AppSnackBar.show(context, AppStrings.verificationCodeFailed);
                  }
                } finally {
                  AppLoadingOverlay.hide();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_isResetCodeSent ? AppStrings.resendVerificationCode : AppStrings.getVerificationCode),
            ),
          ),
        if (_isResetCodeSent && !_isResetCodeVerified) ...[
          const SizedBox(height: 16),
          _buildVerificationRow(authProvider, theme, forReset: true),
        ],
        if (_isResetCodeVerified) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hint: AppStrings.newPasswordHint,
            icon: AppIcons.password,
            isPassword: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              try {
                AppLoadingOverlay.show(context);
                final success = await authProvider.resetPassword(
                  _emailController.text,
                  _verificationCodeController.text,
                  _passwordController.text,
                );
                if (mounted) {
                  AppSnackBar.show(context, success ? AppStrings.passwordChangedSuccess : AppStrings.passwordChangeFailed);
                  if (success) setState(() => _isFindPassword = false);
                }
              } finally {
                AppLoadingOverlay.hide();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text(AppStrings.resetPasswordButton, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
        TextButton(
          onPressed: () {
            setState(() {
              _isFindPassword = false;
              _isResetCodeSent = false;
              _isResetCodeVerified = false;
            });
          },
          child: const Text(AppStrings.backToLogin, style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildVerificationRow(AuthProvider authProvider, ThemeData theme, {bool forReset = false}) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _verificationCodeController,
            hint: AppStrings.verificationCodeHint,
            icon: AppIcons.security,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : () async {
              if (_verificationCodeController.text.isEmpty) return;
              try {
                AppLoadingOverlay.show(context);
                setState(() => _isVerifying = true);
                final success = await authProvider.verifyCode(
                  _emailController.text,
                  _verificationCodeController.text,
                );
                if (success) {
                  setState(() => forReset ? _isResetCodeVerified = true : _isEmailVerified = true);
                  AppSnackBar.show(context, AppStrings.verificationSuccess);
                } else {
                  AppSnackBar.show(context, AppStrings.invalidVerificationCode);
                }
              } finally {
                setState(() => _isVerifying = false);
                AppLoadingOverlay.hide();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isVerifying 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text(AppStrings.ok),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? AppIcons.visibilityOff : AppIcons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
