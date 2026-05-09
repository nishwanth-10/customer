import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:customer_ledger_pro/core/network/dio_client.dart';
import 'package:customer_ledger_pro/core/storage/local_storage.dart';

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthUser {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String role;
  final bool isVerified;

  const AuthUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.role,
    required this.isVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['user_id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String?,
        phoneNumber: json['phone_number'] as String?,
        role: json['role'] as String,
        isVerified: json['is_verified'] as bool,
      );
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // Check if we have stored tokens
    final token = await getAccessToken();
    if (token == null) return null;

    // Try to load cached user from settings
    final userId = LocalStorage.getSetting<String>('user_id');
    final userName = LocalStorage.getSetting<String>('user_name');
    final userRole = LocalStorage.getSetting<String>('user_role');

    if (userId != null && userName != null && userRole != null) {
      return AuthUser(
        id: userId,
        fullName: userName,
        role: userRole,
        isVerified: true,
      );
    }
    return null;
  }

  Future<void> loginWithEmail(String email, String password, {String? fcmToken}) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });
      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed';
      state = AsyncError(message, StackTrace.current);
    }
  }

  Future<void> registerWithEmail(String fullName, String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'password': password,
      });
      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Registration failed';
      state = AsyncError(message, StackTrace.current);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    final dio = ref.read(dioProvider);
    await dio.post('/auth/send-otp', data: {'phone_number': phoneNumber});
  }

  Future<void> verifyOtp(String phoneNumber, String otp, {String? fcmToken}) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/verify-otp', data: {
        'phone_number': phoneNumber,
        'otp': otp,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });
      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'OTP verification failed';
      state = AsyncError(message, StackTrace.current);
    }
  }

  Future<void> signInWithGoogle(String idToken, {String? fcmToken}) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/google', data: {
        'id_token': idToken,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });
      await _handleAuthResponse(response.data);
    } on DioException catch (e) {
      state = AsyncError('Google sign-in failed: ${e.message}', StackTrace.current);
    }
  }

  Future<void> logout() async {
    await clearTokens();
    await LocalStorage.setSetting('user_id', null);
    await LocalStorage.setSetting('user_name', null);
    await LocalStorage.setSetting('user_role', null);
    state = const AsyncData(null);
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    await saveTokens(data['access_token'], data['refresh_token']);
    final user = AuthUser.fromJson(data);

    // Cache user data locally
    await LocalStorage.setSetting('user_id', user.id);
    await LocalStorage.setSetting('user_name', user.fullName);
    await LocalStorage.setSetting('user_role', user.role);

    state = AsyncData(user);
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(() {
  return AuthNotifier();
});
