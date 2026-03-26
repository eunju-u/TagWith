
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/app_config.dart';
import '../core/app_log.dart';


class AuthService {

  
  final _storage = const FlutterSecureStorage();
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';



  // 이메일 로그인
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      AppLog.logD('AuthService', 'signInWithEmail', '로그인 시도: $email');
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      AppLog.logD('AuthService', 'signInWithEmail', '응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        AppLog.logD('AuthService', 'signInWithEmail', '토큰 획득 성공');
        
        // 로그인 성공 후 사용자 정보 가져오기
        final userData = await getCurrentUser(token);
        
        if (userData != null) {
          await _saveSession(token, userData);
          AppLog.logD('AuthService', 'signInWithEmail', '세션 저장 및 로그인 완료');
          return userData;
        } else {
          AppLog.logD('AuthService', 'signInWithEmail', '로그인 성공했으나 사용자 정보 조회 실패');
        }
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        AppLog.logD('AuthService', 'signInWithEmail', '로그인 API 에러: ${e.response?.statusCode}');
        AppLog.logD('AuthService', 'signInWithEmail', '에러 내용: ${e.response?.data}');
      } else {
        AppLog.logD('AuthService', 'signInWithEmail', '알 수 없는 로그인 에러: $e');
      }
      return null;
    }
  }

  // 인증 번호 발송
  Future<bool> sendVerificationCode(String email) async {

    try {
      final response = await _dio.post('/auth/send-verification', data: {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      AppLog.logD('AuthService', 'sendVerificationCode', 'Send Verification Error: $e');
      return false;
    }
  }

  // 비밀번호 찾기 (인정 번호 발송)
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      AppLog.logD('AuthService', 'forgotPassword', 'Forgot Password Error: $e');
      return false;
    }
  }

  // 비밀번호 재설정
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
      return response.statusCode == 200;
    } catch (e) {
      AppLog.logD('AuthService', 'resetPassword', 'Reset Password Error: $e');
      return false;
    }
  }

  // 인증 번호 확인
  Future<bool> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post('/auth/verify-code', data: {
        'email': email,
        'code': code,
      });
      return response.statusCode == 200;
    } catch (e) {
      AppLog.logD('AuthService', 'verifyCode', 'Verify Code Error: $e');
      return false;
    }
  }

  // 회원가입
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'name': name,
        'profile_image': '', // 기본값 빈 문자열
        'password': password,
      });


      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        AppLog.logD('AuthService', 'signUpWithEmail', 'Email Sign-Up Error Status: ${e.response?.statusCode}');
        AppLog.logD('AuthService', 'signUpWithEmail', 'Email Sign-Up Error Data: ${e.response?.data}');
      }
      AppLog.logD('AuthService', 'signUpWithEmail', 'Email Sign-Up Error: $e');
      return false;
    }
  }

  // 세션 저장
  Future<void> _saveSession(String token, Map<String, dynamic> userData) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  // 현재 사용자 정보 가져오기 (토큰 검증)
  Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final userData = response.data; // 서버 명세상 유저 객체 자체가 반환됨
        await _storage.write(key: _userKey, value: jsonEncode(userData));
        return userData;
      }
      return null;
    } catch (e) {
      AppLog.logD('AuthService', 'getCurrentUser', 'Get Current User Error: $e');
      return null;
    }
  }

  // 저장된 토큰 가져오기
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 저장된 유저 데이터 가져오기
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          '/auth/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
      }
    } catch (e) {
      AppLog.logD('AuthService', 'signOut', 'Sign-Out API Error: $e');
    } finally {
      try {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _userKey);
      } catch (e) {
        AppLog.logD('AuthService', 'signOut', 'Sign-Out Local Storage Error: $e');
      }
    }
  }

  // 회원 탈퇴
  Future<bool> withdraw() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _dio.delete(
        '/auth/withdraw',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        // 탈퇴 성공 시 로컬 세션 정보 삭제
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _userKey);
        AppLog.logD('AuthService', 'withdraw', '회원 탈퇴 및 로컬 세션 삭제 완료');
        return true;
      }
      return false;
    } catch (e) {
      if (e is DioException) {
        AppLog.logD('AuthService', 'withdraw', '회원 탈퇴 API 에러: ${e.response?.statusCode}');
        AppLog.logD('AuthService', 'withdraw', '에러 내용: ${e.response?.data}');
      } else {
        AppLog.logD('AuthService', 'withdraw', '알 수 없는 회원 탈퇴 에러: $e');
      }
      return false;
    }
  }
}
