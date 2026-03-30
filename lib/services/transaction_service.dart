import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models.dart';
import '../core/app_config.dart';
import '../core/app_log.dart';


class TransactionService {
  final _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
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
        AppLog.logD('TransactionService', 'getTransactions', 'Server Data : $data');
        return data.map((json) => Transaction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLog.logD('TransactionService', 'getTransactions', 'Get Transactions Error: $e');
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
        '/transactions/statistics',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
       AppLog.logD('TransactionService', 'getStatistics', 'Server Data Raw JSON: ${response.data}');

      if (response.statusCode == 200) {
        return Statistics.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'getStatistics', 'Get Statistics Error: $e');
      return null;
    }
  }

  // 가계부 내역 추가
  Future<Transaction?> createTransaction(Transaction transaction) async {
    try {
      final token = await _getToken();

      if (token == null) return null;

      final response = await _dio.post(
        '/transactions',
        data: transaction.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      AppLog.logD('TransactionService', 'createTransaction', 'response : $response');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Transaction.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'createTransaction', 'Create Transaction Error: $e');
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
      AppLog.logD('TransactionService', 'deleteTransaction', 'Delete Transaction Error: $e');
      return false;
    }
  }

  // 가계부 내역 수정
  Future<Transaction?> updateTransaction(Transaction transaction) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.put(
        '/transactions/${transaction.id}',
        data: transaction.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Transaction.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'updateTransaction', 'Update Transaction Error: $e');
      return null;
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
      AppLog.logD('TransactionService', 'getCategories', 'Get Categories Error: $e');
      return [];
    }
  }

  // 사용자 전용 카테고리 가져오기
  Future<List<Category>> getUserCategories() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/user/categories',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLog.logD('TransactionService', 'getUserCategories', 'Get User Categories Error: $e');
      return [];
    }
  }

  // 사용자 전용 카테고리 추가하기
  Future<Category?> createUserCategory(Category category) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.post(
        '/user/categories',
        data: category.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'createUserCategory', 'Create User Category Error: $e');
      return null;
    }
  }

  // 사용자 전용 카테고리 수정하기
  Future<Category?> updateUserCategory(Category category) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.put(
        '/user/categories/${category.id}',
        data: category.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'updateUserCategory', 'Update User Category Error: $e');
      return null;
    }
  }

  // 사용자 전용 카테고리 삭제하기
  Future<bool> deleteUserCategory(String categoryId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await _dio.delete(
        '/user/categories/$categoryId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLog.logD('TransactionService', 'deleteUserCategory', 'Delete User Category Error: $e');
      return false;
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
      AppLog.logD('TransactionService', 'getTags', 'Get Tags Error: $e');
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
      AppLog.logD('TransactionService', 'createTag', 'Create Tag Error: $e');
      return null;
    }
  }
  // 영수증 OCR 업로드
  Future<Map<String, dynamic>?> uploadReceipt(String filePath) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/upload-receipt',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'uploadReceipt', 'Upload Receipt Error: $e');
      return null;
    }
  }

  // 고정 지출 설정 가져오기
  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _dio.get(
        '/transactions/recurring',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => RecurringTransaction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLog.logD('TransactionService', 'getRecurringTransactions', 'Error: $e');
      return [];
    }
  }

  // 고정 지출 설정 추가
  Future<RecurringTransaction?> createRecurringTransaction(RecurringTransaction recurring) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _dio.post(
        '/transactions/recurring',
        data: recurring.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return RecurringTransaction.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLog.logD('TransactionService', 'createRecurringTransaction', 'Error: $e');
      return null;
    }
  }
}

