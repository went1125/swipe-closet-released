import 'package:flutter/material.dart';

class GenderSelector extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;

  const GenderSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: options.map((gender) {
        final isSelected = selectedOption == gender;
        return ChoiceChip(
          label: Text(gender),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSelected(gender);
            }
          },
          selectedColor: Colors.pinkAccent.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? Colors.pinkAccent : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), 
            side: BorderSide.none
          ),
        );
      }).toList(),
    );
  }
}