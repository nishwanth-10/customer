import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Base URL — change to your deployed backend
const String kBaseUrl = 'https://five-crabs-move.loca.lt/api/v1';
const String kWsUrl = 'wss://five-crabs-move.loca.lt/ws';

const FlutterSecureStorage _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const String _accessTokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';

/// Dio HTTP client provider with JWT interceptor and auto-refresh.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json', 
      'Accept': 'application/json',
      'Bypass-Tunnel-Reminder': 'true'
    },
  ));

  // Logging interceptor (debug only)
  dio.interceptors.add(PrettyDioLogger(
    requestHeader: false,
    requestBody: true,
    responseBody: true,
    error: true,
    compact: true,
  ));

  // JWT auth interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Try refresh
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken != null) {
          try {
            final response = await Dio().post(
              '$kBaseUrl/auth/refresh',
              data: {'refresh_token': refreshToken},
            );
            final newAccess = response.data['access_token'];
            final newRefresh = response.data['refresh_token'];
            await _storage.write(key: _accessTokenKey, value: newAccess);
            await _storage.write(key: _refreshTokenKey, value: newRefresh);

            // Retry original request
            error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            // Clear tokens on refresh failure
            await _storage.deleteAll();
          }
        }
      }
      return handler.next(error);
    },
  ));

  return dio;
});

/// Token storage helpers
Future<void> saveTokens(String access, String refresh) async {
  await _storage.write(key: _accessTokenKey, value: access);
  await _storage.write(key: _refreshTokenKey, value: refresh);
}

Future<void> clearTokens() async {
  await _storage.deleteAll();
}

Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
