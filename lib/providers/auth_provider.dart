import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/app_log.dart';


enum AuthStatus { authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.loading;
  Map<String, dynamic>? _user;
  bool _isInitialized = false;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _checkSession();
  }

  // 초기 세션 체크 (서버 검증 포함)
  Future<void> _checkSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final token = await _authService.getToken();
    if (token != null) {
      final userData = await _authService.getCurrentUser(token);
      if (userData != null) {
        _user = userData;
        _status = AuthStatus.authenticated;
      } else {
        // 토큰이 유효하지 않으면 로그아웃 처리
        await _authService.signOut();
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    _isInitialized = true;
    notifyListeners();
  }



  // 이메일 로그인 실행
  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();

    AppLog.logD('AuthProvider', 'signInWithEmail', '로그인 프로세스 시작');
    final userData = await _authService.signInWithEmail(email, password);
    if (userData != null) {
      AppLog.logD('AuthProvider', 'signInWithEmail', '유저 데이터 획득 성공, 상태 업데이트');
      _user = userData;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      AppLog.logD('AuthProvider', 'signInWithEmail', '유저 데이터 획득 실패');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // 인증 번호 요청
  Future<bool> sendVerificationCode(String email) async {
    return await _authService.sendVerificationCode(email);
  }

  // 비밀번호 찾기 (인증 번호 요청)
  Future<bool> forgotPassword(String email) async {
    return await _authService.forgotPassword(email);
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    return await _authService.resetPassword(email, code, newPassword);
  }

  // 인증 번호 확인
  Future<bool> verifyCode(String email, String code) async {
    return await _authService.verifyCode(email, code);
  }

  // 회원가입 실행
  Future<bool> signUpWithEmail(String email, String password, String name) async {

    _status = AuthStatus.loading;
    notifyListeners();

    final success = await _authService.signUpWithEmail(email, password, name);

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return success;
  }

  // 사용자 정보 새로고침 (OCR 횟수 등 동기화)
  Future<void> refreshUser() async {
    final token = await _authService.getToken();
    if (token != null) {
      final userData = await _authService.getCurrentUser(token);
      if (userData != null) {
        _user = userData;
        notifyListeners();
      }
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // 회원 탈퇴
  Future<bool> withdraw() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final success = await _authService.withdraw();
    if (success) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else {
      // 실패 시 다시 인증된 상태로 복구 (필요시)
      _status = AuthStatus.authenticated;
    }
    
    notifyListeners();
    return success;
  }
}
