import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

final Dio _dio = Dio();

Future<Map<String, dynamic>> callLambdaFunction(
  String endpoint,
  Map<String, dynamic> payload,
) async {
  try {
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data ?? {};
  } on DioException catch (error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response?.data as Map<String, dynamic>;
      if (data['error'] != null) {
        debugPrint(
          'Lambda Function Error: ${data['error']}, details: ${data['details']}',
        );
        throw Exception(data['error']);
      }
    }
    debugPrint('Lambda function error: $error');
    rethrow;
  }
}
