import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_form.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);

    // Kullanıcı giriş yaptıysa yönlendir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userState.value != null && mounted) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Logo ve Başlık
                      const Expanded(
                        flex: 1,
                        child: Center(
                          child: AuthHeader(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Auth Form
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double maxWidth = 400;
                              // Responsive boyutlandırma
                              if (constraints.maxWidth < 480) {
                                maxWidth = constraints.maxWidth * 0.9;
                              } else if (constraints.maxWidth < 768) {
                                maxWidth = constraints.maxWidth * 0.7;
                              } else {
                                maxWidth = (constraints.maxWidth * 0.5).clamp(400.0, 500.0);
                              }

                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: maxWidth),
                                  child: AuthForm(
                                    isLogin: _isLogin,
                                    onToggleMode: _toggleAuthMode,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            '© 2025 AI Asistan. Tüm hakları saklıdır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
