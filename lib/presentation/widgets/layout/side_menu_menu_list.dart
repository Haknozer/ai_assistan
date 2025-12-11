import 'package:flutter/material.dart';

import 'side_menu_items.dart';

class SideMenuMenuList extends StatelessWidget {
  final List<SideMenuItem> items;
  final int selectedIndex;
  final void Function(int) onMenuTap;

  const SideMenuMenuList({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selectedIndex == item.index;

            return GestureDetector(
              onTap: () => onMenuTap(item.index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

