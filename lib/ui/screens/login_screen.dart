import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/auth_provider.dart';

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


  void _showSnackBar(BuildContext context, String message, ThemeData theme) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: const Color(0xFFF3F4F6),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 90,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TagWith',
                      style: GoogleFonts.outfit(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '태그로 연결되는 스마트 가계부',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 로그인 카드 (Glassmorphism 효과)
                    Container(
                      padding: const EdgeInsets.all(24),
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
          hint: '이메일',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: '비밀번호',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: authProvider.status == AuthStatus.loading
              ? null
              : () async {
                  final success = await authProvider.signInWithEmail(
                    _emailController.text,
                    _passwordController.text,
                  );
                  if (mounted) {
                    _showSnackBar(context, success ? '로그인에 성공했습니다!' : '로그인에 실패했습니다.', theme);
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
              : const Text('로그인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => _isFindPassword = true),
              child: const Text('비밀번호를 잊으셨나요?', style: TextStyle(color: Colors.white70)),
            ),
            const Text('|', style: TextStyle(color: Colors.white38)),
            TextButton(
              onPressed: () => setState(() => _isSignUp = true),
              child: const Text('회원가입', style: TextStyle(color: Colors.white70)),
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
          hint: '이름',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          hint: '이메일',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isEmailVerified ? null : () async {
              if (_emailController.text.isEmpty) {
                _showSnackBar(context, '이메일을 입력해 주세요.', theme);
                return;
              }
              final canRequest = await _canRequestVerification();
              if (!canRequest) {
                _showSnackBar(context, '오늘 인증 요청 한도(5회)를 초과했습니다.', theme);
                return;
              }
              final success = await authProvider.sendVerificationCode(_emailController.text);
              if (success) {
                await _incrementRequestCount();
                setState(() => _isCodeSent = true);
                _showSnackBar(context, '인증 코드가 발송되었습니다.', theme);
              } else {
                _showSnackBar(context, '코드 발송에 실패했습니다.', theme);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_isEmailVerified ? '인증 완료됨' : '인증 요청'),
          ),
        ),
        if (_isCodeSent && !_isEmailVerified) ...[
          const SizedBox(height: 16),
          _buildVerificationRow(authProvider, theme),
        ],
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: '비밀번호',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            if (!_isEmailVerified) {
              _showSnackBar(context, '이메일 인증을 완료해 주세요.', theme);
              return;
            }
            final success = await authProvider.signUpWithEmail(
              _emailController.text,
              _passwordController.text,
              _nameController.text,
            );
            if (mounted) {
              _showSnackBar(context, success ? '회원가입 성공!' : '회원가입 실패', theme);
              if (success) setState(() => _isSignUp = false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('회원가입', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => setState(() => _isSignUp = false),
          child: const Text('이미 계정이 있으신가요? 로그인', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildFindPasswordUI(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          hint: '가입된 이메일',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 12),
        if (!_isResetCodeVerified)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (_emailController.text.isEmpty) return;
                final success = await authProvider.forgotPassword(_emailController.text);
                if (success) {
                  setState(() => _isResetCodeSent = true);
                  _showSnackBar(context, '인증 코드가 발송되었습니다.', theme);
                } else {
                  _showSnackBar(context, '가입되지 않은 이메일이거나 발송에 실패했습니다.', theme);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_isResetCodeSent ? '인증 코드 재발송' : '인증 코드 받기'),
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
            hint: '새 비밀번호',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final success = await authProvider.resetPassword(
                _emailController.text,
                _verificationCodeController.text,
                _passwordController.text,
              );
              if (mounted) {
                _showSnackBar(context, success ? '비밀번호가 변경되었습니다.' : '변경 실패', theme);
                if (success) setState(() => _isFindPassword = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('비밀번호 재설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
          child: const Text('로그인으로 돌아가기', style: TextStyle(color: Colors.white70)),
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
            hint: '인증 코드',
            icon: Icons.security,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : () async {
              if (_verificationCodeController.text.isEmpty) return;
              setState(() => _isVerifying = true);
              final success = await authProvider.verifyCode(
                _emailController.text,
                _verificationCodeController.text,
              );
              setState(() => _isVerifying = false);
              if (success) {
                setState(() => forReset ? _isResetCodeVerified = true : _isEmailVerified = true);
                _showSnackBar(context, '인증에 성공했습니다!', theme);
              } else {
                _showSnackBar(context, '인증 코드가 올바르지 않습니다.', theme);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isVerifying 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('확인'),
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
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
