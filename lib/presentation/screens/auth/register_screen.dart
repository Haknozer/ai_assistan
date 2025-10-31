import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Register screen de login screen ile aynı arayüzü kullanacak
    // LoginScreen'e yönlendiriyoruz
    return const LoginScreen();
  }
}