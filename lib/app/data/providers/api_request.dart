import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Shared request plumbing for repositories.
///
/// `ApiService` sets `validateStatus` to accept anything under 500, so a 401,
/// 403 or 422 arrives as an ordinary response rather than a thrown
/// `DioException`. Without this check a failed call would parse as an empty
/// success, so every repository call goes through [send].
mixin ApiRequestMixin {
  Future<Map<String, dynamic>> send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    final Response<Map<String, dynamic>> response;

    try {
      response = await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw ApiException.fromResponse(response);
    }

    return response.data ?? const {};
  }
}
