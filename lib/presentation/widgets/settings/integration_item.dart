import 'package:flutter/material.dart';

/// Entegrasyon item widget'ı
class IntegrationItem extends StatelessWidget {
  final Map<String, dynamic> integration;
  final IconData categoryIcon;
  final Function(String, bool) onTap;

  const IntegrationItem({
    super.key,
    required this.integration,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = integration['connected'] as bool;
    final name = integration['name'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // İkon
          Icon(
            categoryIcon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 16),

          // Entegrasyon Bilgisi
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Durum ve Buton
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isConnected ? 'BAĞLI' : 'BAĞLI DEĞİL',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isConnected ? Colors.green : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => onTap(name, isConnected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(isConnected ? 'Bağlantıyı Kes' : 'Bağlan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

