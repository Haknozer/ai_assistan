import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/user_provider.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';

class AuthForm extends ConsumerStatefulWidget {
  final bool isLogin;
  final VoidCallback onToggleMode;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
  });

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isLogin) {
      // Login işlemi
      await ref.read(userNotifierProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } else {
      // Register işlemi
      await ref.read(userNotifierProvider.notifier).registerUser(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            password: _passwordController.text,
          );
    }

    // Hata varsa göster
    final error = ref.read(userErrorProvider);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    // Kayıt sırasında şifre güçlülüğü kontrolü
    if (!widget.isLogin) {
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Şifre en az bir büyük harf içermeli';
      }
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Şifre en az bir küçük harf içermeli';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Şifre en az bir rakam içermeli';
      }
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }
    if (value != _passwordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isUserLoadingProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.isLogin ? null : widget.onToggleMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.isLogin ? AppColors.buttonBackground : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.isLogin
                              ? AppColors.borderColor.withValues(alpha: 0.5)
                              : AppColors.borderColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login,
                            size: 16,
                            color: widget.isLogin ? AppColors.primaryTextColor : AppColors.secondaryTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Giriş Yap',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.isLogin ? AppColors.primaryTextColor : AppColors.secondaryTextColor,
                              fontWeight: widget.isLogin ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: !widget.isLogin ? null : widget.onToggleMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !widget.isLogin ? AppColors.buttonBackground : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: !widget.isLogin
                              ? AppColors.borderColor.withValues(alpha: 0.5)
                              : AppColors.borderColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_alt,
                            size: 16,
                            color: !widget.isLogin ? AppColors.primaryTextColor : AppColors.secondaryTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kayıt Ol',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !widget.isLogin ? AppColors.primaryTextColor : AppColors.secondaryTextColor,
                              fontWeight: !widget.isLogin ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Name Field (Sadece Kayıt için)
            if (!widget.isLogin) ...[
              CustomTextField(
                controller: _nameController,
                label: 'Ad Soyad',
                hintText: 'Ahmet Yılmaz',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad Soyad gerekli';
                  }
                  if (value.length < 3) {
                    return 'Ad Soyad en az 3 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Email Field
            CustomTextField(
              controller: _emailController,
              label: 'E-posta',
              hintText: 'ornek@gmail.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'E-posta adresi gerekli';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Geçerli bir e-posta adresi girin';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              label: widget.isLogin ? 'Şifre' : 'Şifre (Büyük harf, küçük harf, rakam)',
              hintText: '••••••••',
              obscureText: !_isPasswordVisible,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.hintText,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: _validatePassword,
            ),

            if (!widget.isLogin) ...[
              const SizedBox(height: 14),

              // Confirm Password Field (Sadece Kayıt için)
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Şifre Tekrar',
                hintText: '••••••••',
                obscureText: !_isConfirmPasswordVisible,
                prefixIcon: Icons.lock_reset_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.hintText,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                validator: _validateConfirmPassword,
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            CustomButton(
              text: widget.isLogin ? 'Giriş Yap' : 'Kaydol',
              icon: widget.isLogin ? Icons.arrow_circle_right : Icons.person_add_alt,
              onPressed: _handleAuth,
              isLoading: isLoading,
              height: 48,
            ),

            const SizedBox(height: 16),

            // Şifremi Unuttum / Kayıt Ol Linkleri
            if (widget.isLogin) ...[
              // Şifremi Unuttum
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Şifremi unuttum özelliği
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Şifremi Unuttum?',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1,
                      decorationColor: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Kayıt Ol
              Center(
                child: TextButton(
                  onPressed: widget.onToggleMode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Hesabınız yok mu? Kaydol',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Giriş Yap
              Center(
                child: TextButton(
                  onPressed: widget.onToggleMode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Zaten hesabınız var mı? Giriş Yap',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
