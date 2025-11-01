// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userRepositoryHash() => r'8366fba5ac0d6b90c6a637882d24c5e759a5a92f';

/// See also [userRepository].
@ProviderFor(userRepository)
final userRepositoryProvider = AutoDisposeProvider<UserRepository>.internal(
  userRepository,
  name: r'userRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRepositoryRef = AutoDisposeProviderRef<UserRepository>;
String _$supabaseAuthServiceHash() =>
    r'9cab3279e172ba4030d6833daff0584702689100';

/// See also [supabaseAuthService].
@ProviderFor(supabaseAuthService)
final supabaseAuthServiceProvider =
    AutoDisposeProvider<SupabaseAuthService>.internal(
  supabaseAuthService,
  name: r'supabaseAuthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseAuthServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseAuthServiceRef = AutoDisposeProviderRef<SupabaseAuthService>;
String _$isLoggedInHash() => r'685a804a5271d28e2cfe32b36069b866f8db25e3';

/// See also [isLoggedIn].
@ProviderFor(isLoggedIn)
final isLoggedInProvider = AutoDisposeProvider<bool>.internal(
  isLoggedIn,
  name: r'isLoggedInProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isLoggedInHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsLoggedInRef = AutoDisposeProviderRef<bool>;
String _$currentUserHash() => r'86d6ab8d67187b0b71aebdbb5fbf254a38c58e7b';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<app_user.User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<app_user.User?>;
String _$userThemeHash() => r'd7d4dcca917d6dfb60f5e17613d1f7277cd8c17d';

/// See also [userTheme].
@ProviderFor(userTheme)
final userThemeProvider = AutoDisposeProvider<String>.internal(
  userTheme,
  name: r'userThemeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userThemeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserThemeRef = AutoDisposeProviderRef<String>;
String _$userLanguageHash() => r'a84697cae49fb03a169cefde8931a485829f3666';

/// See also [userLanguage].
@ProviderFor(userLanguage)
final userLanguageProvider = AutoDisposeProvider<String>.internal(
  userLanguage,
  name: r'userLanguageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userLanguageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLanguageRef = AutoDisposeProviderRef<String>;
String _$isUserLoadingHash() => r'4c7c837a8ba3153d6eee499ff4c4ad9683a783f5';

/// See also [isUserLoading].
@ProviderFor(isUserLoading)
final isUserLoadingProvider = AutoDisposeProvider<bool>.internal(
  isUserLoading,
  name: r'isUserLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isUserLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsUserLoadingRef = AutoDisposeProviderRef<bool>;
String _$userErrorHash() => r'c265ccc6b49be50c4c7994baf703cd57a2569a5c';

/// See also [userError].
@ProviderFor(userError)
final userErrorProvider = AutoDisposeProvider<String?>.internal(
  userError,
  name: r'userErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserErrorRef = AutoDisposeProviderRef<String?>;
String _$supabaseAuthStateHash() => r'86df92005cbfa48db347335eff97406f82506a5e';

/// See also [supabaseAuthState].
@ProviderFor(supabaseAuthState)
final supabaseAuthStateProvider = AutoDisposeStreamProvider<AuthState>.internal(
  supabaseAuthState,
  name: r'supabaseAuthStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseAuthStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseAuthStateRef = AutoDisposeStreamProviderRef<AuthState>;
String _$userNotifierHash() => r'4a34f98d15e685a66ddf9a4c8c9b1b573ba5bb9f';

/// See also [UserNotifier].
@ProviderFor(UserNotifier)
final userNotifierProvider =
    AutoDisposeAsyncNotifierProvider<UserNotifier, app_user.User?>.internal(
  UserNotifier.new,
  name: r'userNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserNotifier = AutoDisposeAsyncNotifier<app_user.User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
