import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_isSignUp) ...[
                            _buildTextField(
                              controller: _nameController,
                              hint: '이름',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _emailController,
                                    hint: '이메일',
                                    icon: Icons.email_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isEmailVerified ? null : () async {
                                      if (_emailController.text.isEmpty) {
                                        _showSnackBar(context, '이메일을 입력해 주세요.', theme);
                                        return;
                                      }

                                      final success = await authProvider.sendVerificationCode(_emailController.text);

                                      if (success) {
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
                                    child: Text(_isEmailVerified ? '인증됨' : '인증 요청'),
                                  ),
                                ),
                              ],
                            ),
                            if (_isCodeSent && !_isEmailVerified) ...[
                              const SizedBox(height: 16),
                              Row(
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
                                          setState(() => _isEmailVerified = true);
                                          _showSnackBar(context, '이메일 인증에 성공했습니다!', theme);
                                        } else {
                                          _showSnackBar(context, '인증 코드가 올바르지 않습니다.', theme);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1), // 보라색과 어울리는 인디고 색상
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: _isVerifying 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('확인'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              hint: '비밀번호',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                          ] else ...[
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
                          ],
                          const SizedBox(height: 24),
                          
                          // 로그인/회원가입 버튼
                          ElevatedButton(
                            onPressed: authProvider.status == AuthStatus.loading
                                ? null
                                : () async {
                                    bool success;
                                    String message;
                                    
                                    if (_isSignUp) {
                                      if (!_isEmailVerified) {
                                        _showSnackBar(context, '이메일 인증을 먼저 완료해 주세요.', theme);
                                        return;
                                      }
                                      // 비밀번호 유효성 검사
                                      final password = _passwordController.text;
                                      bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
                                      bool hasDigit = password.contains(RegExp(r'[0-9]'));
                                      bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*()]'));
                                      
                                      int score = (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSpecial ? 1 : 0);
                                      
                                      if (password.length < 8 || score < 2) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '비밀번호는 8자 이상이며, 영문/숫자/특수문자 중 2가지 이상을 조합해야 합니다.',
                                                style: TextStyle(color: theme.colorScheme.onSurface),
                                              ),
                                              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // 회원가입 로직
                                      success = await authProvider.signUpWithEmail(
                                        _emailController.text,
                                        _passwordController.text,
                                        _nameController.text,
                                      );
                                      message = success ? '회원가입에 성공했습니다! 로그인해 주세요.' : '회원가입에 실패했습니다.';
                                      
                                      if (success && mounted) {
                                        setState(() {
                                          _isSignUp = false;
                                        });
                                      }
                                    } else {
                                      // 로그인 로직
                                      success = await authProvider.signInWithEmail(
                                        _emailController.text,
                                        _passwordController.text,
                                      );

                                      message = success ? '로그인에 성공했습니다!' : '로그인에 실패했습니다. 정보를 확인해 주세요.';
                                    }

                                    if (mounted) {
                                      _showSnackBar(context, message, theme);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: theme.colorScheme.primary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.status == AuthStatus.loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _isSignUp ? '시작하기' : '로그인',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          

                          
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                              });
                            },
                            child: Text(
                              _isSignUp ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
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
