import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models.dart';

class TransactionService {
  final _dio = Dio(BaseOptions(baseUrl: 'https://web-production-e1340.up.railway.app'));
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 가계부 내역 가져오기
  Future<List<Transaction>> getTransactions() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/transactions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Transaction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Transactions Error: $e');
      return [];
    }
  }

  // 통계 데이터 가져오기 (신설)
  Future<Statistics?> getStatistics({int? year, int? month}) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;

      final response = await _dio.get(
        '/statistics',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Statistics.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Get Statistics Error: $e');
      return null;
    }
  }

  // 가계부 내역 추가
  Future<Transaction?> createTransaction(Transaction transaction) async {
    try {
      final token = await _getToken();
      print('eunju createTransaction token =: $token');

      if (token == null) return null;

      final response = await _dio.post(
        '/transactions',
        data: transaction.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('eunju createTransaction response : $response');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Transaction.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Create Transaction Error: $e');
      return null;
    }
  }

  // 가계부 내역 삭제
  Future<bool> deleteTransaction(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await _dio.delete(
        '/transactions/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete Transaction Error: $e');
      return false;
    }
  }

  // 공용 카테고리 가져오기
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Categories Error: $e');
      return [];
    }
  }

  // 사용자 태그(Relations) 가져오기
  Future<List<Relation>> getTags() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/user/tags',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Relation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Tags Error: $e');
      return [];
    }
  }

  // 사용자 태그 추가하기
  Future<Relation?> createTag(String name) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.post(
        '/user/tags',
        data: {'name': name},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Relation.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Create Tag Error: $e');
      return null;
    }
  }
}

