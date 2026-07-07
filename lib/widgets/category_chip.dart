// ============================================================
// category_chip.dart — Widget : chip de catégorie scrollable
// (RE)Sources Relationnelles
// ============================================================

import 'package:flutter/material.dart';
import '../main.dart';
import '../mock_data.dart';

/// Chip de catégorie cliquable
class CategoryChipWidget extends StatelessWidget {
  final MockCategory category;
  final bool isSelected;

  const CategoryChipWidget({
    super.key,
    required this.category,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFDDE2EA),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: 16,
            color: isSelected ? AppColors.white : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textDark,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne scrollable horizontale de catégories.
/// [selectedIndex] et [onSelected] permettent au parent de contrôler le filtre.
class CategoryChipsRow extends StatelessWidget {
  final List<MockCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategoryChipsRow({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onSelected(index),
            child: CategoryChipWidget(
              category: categories[index],
              isSelected: selectedIndex == index,
            ),
          );
        },
      ),
    );
  }
}
