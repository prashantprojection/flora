import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class CustomDropdownButton<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String hint;
  final IconData icon;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<T?> onChanged;

  const CustomDropdownButton({
    super.key,
    required this.value,
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });

  InputDecoration _buildInputDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.1,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        LucideIcons.chevronDown,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      dropdownColor: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      hint: Text(
        hint,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
      ),
      decoration: _buildInputDecoration(context),
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((T item) {
          return Text(
            itemLabelBuilder(item),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList();
      },
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabelBuilder(item),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
