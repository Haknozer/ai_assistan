import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/user_repository.dart';
import '../models/user.dart' as app_user;
import '../services/supabase_auth_service.dart';

part 'user_provider.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository();
}

@riverpod
SupabaseAuthService supabaseAuthService(Ref ref) {
  return SupabaseAuthService();
}

@riverpod
class UserNotifier extends _$UserNotifier {
  late UserRepository _userRepository;
  late SupabaseAuthService _authService;

  @override
  Future<app_user.User?> build() async {
    _userRepository = ref.read(userRepositoryProvider);
    _authService = ref.read(supabaseAuthServiceProvider);
    // Supabase auth state değişikliklerini dinle
    ref.listen(supabaseAuthStateProvider, (previous, next) {
      if (next.value?.session != null) {
        _syncUserFromSupabase();
      } else {
        state = const AsyncValue.data(null);
      }
    });

    return _getCurrentUser();
  }

  // Yeni kullanıcı kaydet (Supabase + Yerel)
  Future<void> registerUser({
    required String email,
    required String name,
    required String password,
    String themePreference = 'system',
    String language = 'tr',
  }) async {
    state = const AsyncValue.loading();

    try {
      // Supabase ile kayıt yap
      final response = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (response.user != null) {
        // Yerel veritabanına da kaydet
        final localUser = await _userRepository.createUser(
          email: email,
          name: name,
          password: '', // Supabase tarafından yönetiliyor
          themePreference: themePreference,
          language: language,
        );

        // Supabase'de profil oluştur
        await _authService.upsertProfile(
          response.user!.id,
          {
            'email': email,
            'name': name,
            'theme_preference': themePreference,
            'language': language,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        state = AsyncValue.data(localUser);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Giriş yap (Supabase + Yerel)
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      // Supabase ile giriş yap
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Yerel veritabanında kullanıcı var mı kontrol et
        app_user.User? localUser = await _userRepository.getUserByEmail(email);

        if (localUser == null) {
          // Yerelde yoksa yeni kayıt oluştur
          final userName = response.user!.userMetadata?['name'] ?? 'Kullanıcı';
          localUser = await _userRepository.createUser(
            email: email,
            name: userName,
            password: '', // Supabase tarafından yönetiliyor
            themePreference: 'system',
            language: 'tr',
          );
        }

        state = AsyncValue.data(localUser);
      } else {
        state = AsyncValue.error('E-posta veya şifre hatalı', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Çıkış yap (Supabase + Yerel)
  Future<void> signOut() async {
    try {
      // Supabase'den çıkış yap
      await _authService.signOut();

      // Yerel state'i temizle
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUser(app_user.User user) async {
    state = const AsyncValue.loading();

    try {
      await _userRepository.updateUser(user);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Kullanıcı adını güncelle
  Future<void> updateUserName(String newName) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();

    try {
      await _userRepository.updateUserName(currentUser.id!, newName);
      final updatedUser = currentUser.copyWith(name: newName);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Şifre güncelle
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();

    try {
      // Önce eski şifreyi kontrol et
      final authenticatedUser = await _userRepository.authenticate(
        currentUser.email,
        oldPassword,
      );

      if (authenticatedUser == null) {
        state = AsyncValue.error('Mevcut şifre hatalı', StackTrace.current);
        return;
      }

      await _userRepository.updateUserPassword(currentUser.id!, newPassword);
      // Şifre güncellendi ama state'deki kullanıcıyı güncellemeliyiz
      state = AsyncValue.data(currentUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Tema tercihini güncelle
  Future<void> updateTheme(String themePreference) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();

    try {
      await _userRepository.updateUserTheme(currentUser.id!, themePreference);
      final updatedUser = currentUser.copyWith(themePreference: themePreference);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Dil tercihini güncelle
  Future<void> updateLanguage(String language) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();

    try {
      await _userRepository.updateUserLanguage(currentUser.id!, language);
      final updatedUser = currentUser.copyWith(language: language);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // E-posta var mı kontrol et
  Future<bool> checkEmailExists(String email) async {
    try {
      return await _userRepository.isEmailExists(email);
    } catch (e) {
      return false;
    }
  }

  // ID'ye göre kullanıcı yükle
  Future<void> loadUserById(int userId) async {
    state = const AsyncValue.loading();

    try {
      final user = await _userRepository.getUserById(userId);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Hata sıfırla
  void clearError() {
    if (state.hasError) {
      state = AsyncValue.data(state.value);
    }
  }

  // Mevcut kullanıcıyı al
  Future<app_user.User?> _getCurrentUser() async {
    final supabaseUser = _authService.getCurrentUser();
    if (supabaseUser == null) return null;

    // Yerel veritabanında ara
    final localUser = await _userRepository.getUserByEmail(supabaseUser.email!);
    return localUser;
  }

  // Supabase'den kullanıcıyı senkronize et
  Future<void> _syncUserFromSupabase() async {
    try {
      final supabaseUser = _authService.getCurrentUser();
      if (supabaseUser == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Yerel veritabanında ara
      app_user.User? localUser = await _userRepository.getUserByEmail(supabaseUser.email!);

      if (localUser == null) {
        // Yerelde yoksa oluştur
        final userName = supabaseUser.userMetadata?['name'] ?? 'Kullanıcı';
        localUser = await _userRepository.createUser(
          email: supabaseUser.email!,
          name: userName,
          password: '',
          themePreference: 'system',
          language: 'tr',
        );
      }

      state = AsyncValue.data(localUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Convenience provider'lar
@riverpod
bool isLoggedIn(Ref ref) {
  final user = ref.watch(userNotifierProvider);
  return user.value != null;
}

@riverpod
app_user.User? currentUser(Ref ref) {
  return ref.watch(userNotifierProvider).value;
}

@riverpod
String userTheme(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.themePreference ?? 'system';
}

@riverpod
String userLanguage(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.language ?? 'tr';
}

@riverpod
bool isUserLoading(Ref ref) {
  return ref.watch(userNotifierProvider).isLoading;
}

@riverpod
String? userError(Ref ref) {
  final error = ref.watch(userNotifierProvider).error;
  return error?.toString();
}

// Supabase auth state provider
@riverpod
Stream<AuthState> supabaseAuthState(Ref ref) {
  final supabaseClient = Supabase.instance.client;
  return supabaseClient.auth.onAuthStateChange;
}
