
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class AuthService {

  
  final _storage = const FlutterSecureStorage();
  final _dio = Dio(BaseOptions(baseUrl: 'https://web-production-e1340.up.railway.app'));

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';



  // 이메일 로그인
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        
        // 로그인 성공 후 사용자 정보 가져오기
        final userData = await getCurrentUser(token);
        
        if (userData != null) {
          await _saveSession(token, userData);
          return userData;
        }
      }
      return null;
    } catch (e) {
      print('Email Sign-In Error: $e');
      return null;
    }
  }

  // 인증 번호 발송
  Future<bool> sendVerificationCode(String email) async {

    try {
      final response = await _dio.post('/auth/send-verification', data: {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      print('Send Verification Error: $e');
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
      print('Verify Code Error: $e');
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
        print('Email Sign-Up Error Status: ${e.response?.statusCode}');
        print('Email Sign-Up Error Data: ${e.response?.data}');
      }
      print('Email Sign-Up Error: $e');
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
      print('Get Current User Error: $e');
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
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      print('Sign-Out Error: $e');
    }
  }
}
