import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Hızlı İşlemler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
        ),
        const SizedBox(height: 16),

        // Responsive Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              double childAspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.0;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildActionCard(
                    context,
                    'Yeni Görev',
                    Icons.add_task_outlined,
                    AppColors.primaryColor,
                    () {
                      // TODO: Navigate to tasks screen with add mode
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yeni görev ekleme sayfasına yönlendiriliyor...')),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'Etkinlik Ekle',
                    Icons.event,
                    Colors.purple,
                    () {
                      // TODO: Navigate to calendar screen with add mode
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etkinlik ekleme sayfasına yönlendiriliyor...')),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'E-postaları Gözden Geçir',
                    Icons.email_outlined,
                    Colors.blue,
                    () {
                      // TODO: Navigate to email screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('E-posta sayfasına yönlendiriliyor...')),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    'AI Asistan',
                    Icons.smart_toy_outlined,
                    Colors.orange,
                    () {
                      // TODO: Open AI Assistant
                      _showAIAssistantDialog(context);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIAssistantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text('AI Asistan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Asistan size nasıl yardımcı olabilir?'),
              const SizedBox(height: 16),
              _buildAIOption('Bugünkü görevleri özetle'),
              _buildAIOption('E-postaları analiz et'),
              _buildAIOption('Takvimini organize et'),
              _buildAIOption('Özel soru sor'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Asistan yakında kullanıma sunulacak!')),
                );
              },
              child: const Text('Başla'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAIOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.arrow_right,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
