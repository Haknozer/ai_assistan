import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/voice/voice_command_sheet.dart';
import '../../../services/voice/voice_command_helper.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/user_provider.dart';
import 'side_menu_header.dart';
import 'side_menu_profile_card.dart';
import 'side_menu_items.dart';
import 'side_menu_menu_list.dart';
import 'side_menu_bottom_section.dart';

class SideMenu extends ConsumerWidget {
  final String userName;
  final String userEmail;
  final int selectedIndex;
  final Function(int) onMenuTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onVoiceTap;

  const SideMenu({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.selectedIndex,
    required this.onMenuTap,
    required this.onProfileTap,
    this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider).isDarkMode;
    final items = getSideMenuItems();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SideMenuHeader(),
          SideMenuProfileCard(
            userName: userName,
            userEmail: userEmail,
            onProfileTap: onProfileTap,
          ),
          const SizedBox(height: 12),
          SideMenuMenuList(
            items: items,
            selectedIndex: selectedIndex,
            onMenuTap: onMenuTap,
          ),
          SideMenuBottomSection(
            isDarkMode: isDarkMode,
            onToggleTheme: () => ref.read(themeProvider.notifier).toggleTheme(),
            onVoiceTap: onVoiceTap ?? () => _openVoiceSheetIfPossible(context, ref),
            onLogout: () {
              // TODO: Implement logout
            },
          ),
        ],
      ),
    );
  }
}

void _openVoiceSheetIfPossible(BuildContext context, WidgetRef ref) {
  const servicePath = AppConfig.googleApplicationCredentials;
  if (servicePath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GOOGLE_APPLICATION_CREDENTIALS tanımlı değil')),
    );
    return;
  }

  final user = ref.read(currentUserProvider);
  final userId = user?.id?.toString() ?? 'desktop-user';

  showVoiceCommandSheet(
    context,
    serviceAccountPath: servicePath,
    languageCode: AppConfig.gcpSttLanguage,
    voiceName: AppConfig.gcpTtsVoice,
    audioEncoding: AppConfig.gcpTtsEncoding,
    userId: userId,
    onSendVoice: (text) async {
      final connections = await VoiceCommandHelper.resolveEmailConnections(userId: null);
      return await VoiceCommandHelper.processVoiceCommand(
        context: context,
        text: text,
        userId: userId,
        // SideMenu içinde konum yok, null gönderiyoruz (veya servisten çekilebilir ama
        // helper içinde konum çekme yok, basit tutuyoruz. Gerekirse eklenebilir)
        latitude: null, // Konum gerekirse locationService'den çekilebilir
        longitude: null,
        gmailConnected: connections.gmail,
        outlookConnected: connections.outlook,
      );
    },
  );
}
