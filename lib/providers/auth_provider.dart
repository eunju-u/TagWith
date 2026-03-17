import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.loading;
  Map<String, dynamic>? _user;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;

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
    notifyListeners();
  }



  // 이메일 로그인 실행
  Future<bool> signInWithEmail(String email, String password) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final userData = await _authService.signInWithEmail(email, password);
    if (userData != null) {
      _user = userData;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
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

  // 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
