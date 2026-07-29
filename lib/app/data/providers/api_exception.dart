import 'package:dio/dio.dart';

/// Anything a repository call can fail with, already turned into a message the
/// UI can show.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Laravel's machine-readable `code` field, e.g. `invalid_credentials`,
  /// `account_suspended`.
  final String? code;

  bool get isUnauthorized => statusCode == 401;

  /// Builds the message from Laravel's error envelope, which is either
  /// `{message, code}` or a 422 `{message, errors: {field: [msg]}}`.
  factory ApiException.fromResponse(Response<dynamic> response) {
    final body = response.data;

    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException(
            first.first.toString(),
            statusCode: response.statusCode,
            code: body['code'] as String?,
          );
        }
      }

      final message = body['message'];
      if (message is String && message.isNotEmpty) {
        return ApiException(
          message,
          statusCode: response.statusCode,
          code: body['code'] as String?,
        );
      }
    }

    return ApiException(
      'Terjadi kesalahan (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException('Koneksi timeout. Coba lagi.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException('Sertifikat server tidak valid.');
      case DioExceptionType.cancel:
        return const ApiException('Permintaan dibatalkan.');
      case DioExceptionType.badResponse:
        final response = error.response;
        return response != null
            ? ApiException.fromResponse(response)
            : const ApiException('Server tidak merespons.');
    }
  }

  @override
  String toString() => message;
}
