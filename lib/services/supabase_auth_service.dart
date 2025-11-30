import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Yeni kullanıcı kaydet
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );
      return response;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Giriş yap
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Mevcut kullanıcıyı al
  dynamic getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Kullanıcı state değişikliklerini dinle
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Şifre güncelle
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateProfile({String? name}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {
          if (name != null) 'name': name,
        }),
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Hata yönetimi
  String _handleAuthException(dynamic e) {
    // Network hatalarını kontrol et
    if (e is SocketException || 
        (e.toString().contains('Failed host lookup') || 
         e.toString().contains('SocketException') ||
         e.toString().contains('ClientException'))) {
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    }

    // AuthRetryableFetchException - network hataları için sessizce yönet
    if (e.toString().contains('AuthRetryableFetchException') ||
        e.toString().contains('Failed host lookup')) {
      if (kDebugMode) {
        debugPrint('[Supabase Auth] Network error (handled silently): $e');
      }
      return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
    }

    if (e is AuthException) {
      switch (e.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'E-posta veya şifre hatalı';
        case 'user already registered':
          return 'Bu e-posta adresi zaten kayıtlı';
        case 'email not confirmed':
          return 'E-posta adresiniz doğrulanmamış';
        case 'weak password':
          return 'Şifre en az 6 karakter olmalıdır';
        case 'invalid email':
          return 'Geçersiz e-posta adresi';
        default:
          return e.message;
      }
    }
    return 'Bir hata oluştu: ${e.toString()}';
  }

  // Kullanıcı bilgilerini veritabanından al
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase.from('profiles').select().eq('id', userId).single();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Profil oluştur/güncelle
  Future<void> upsertProfile(String userId, Map<String, dynamic> profile) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        ...profile,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }
}
