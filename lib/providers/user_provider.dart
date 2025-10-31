import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/user_repository.dart';
import '../models/user.dart';

part 'user_provider.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository();
}

@riverpod
class UserNotifier extends _$UserNotifier {
  late UserRepository _userRepository;

  @override
  Future<User?> build() async {
    _userRepository = ref.read(userRepositoryProvider);
    return null;
  }

  // Yeni kullanıcı kaydet
  Future<void> registerUser({
    required String email,
    required String name,
    required String password,
    String themePreference = 'system',
    String language = 'tr',
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _userRepository.createUser(
        email: email,
        name: name,
        password: password,
        themePreference: themePreference,
        language: language,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Giriş yap
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final user = await _userRepository.authenticate(email, password);
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        state = AsyncValue.error('E-posta veya şifre hatalı', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Çıkış yap
  void signOut() {
    state = const AsyncValue.data(null);
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUser(User user) async {
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
}

// Convenience provider'lar
@riverpod
bool isLoggedIn(Ref ref) {
  final user = ref.watch(userNotifierProvider);
  return user.value != null;
}

@riverpod
User? currentUser(Ref ref) {
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