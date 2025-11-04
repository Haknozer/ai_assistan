import 'package:flutter/material.dart';

/// Entegrasyon item - Detaylı versiyon (icon placeholder ile)
class IntegrationsItemDetailed extends StatelessWidget {
  final Map<String, dynamic> integration;
  final Function(String, bool) onTap;

  const IntegrationsItemDetailed({
    super.key,
    required this.integration,
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
          // İkon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.apps,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Entegrasyon Bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected ? 'Bağlı' : 'Bağlanmamış',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isConnected
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Durum ve Buton
          Row(
            children: [
              Icon(
                isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isConnected ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onTap(name, isConnected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  isConnected ? 'Ayır' : 'Bağlan',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

