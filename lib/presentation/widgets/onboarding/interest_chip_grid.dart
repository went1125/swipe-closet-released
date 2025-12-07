import 'package:flutter/material.dart';

class InterestChipGrid extends StatelessWidget {
  final List<String> items;
  final Set<String> selectedItems;
  final ValueChanged<String> onToggle;

  const InterestChipGrid({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onToggle(item),
          selectedColor: Colors.black, // 選中變黑
          checkmarkColor: Colors.white, // 打勾變白
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.grey[300]!
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      }).toList(),
    );
  }
}