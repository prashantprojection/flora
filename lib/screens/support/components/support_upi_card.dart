import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/widgets/animated_press.dart';

class SupportUpiCard extends StatefulWidget {
  final void Function(String amount) onPay;
  const SupportUpiCard({super.key, required this.onPay});

  @override
  State<SupportUpiCard> createState() => _SupportUpiCardState();
}

class _SupportUpiCardState extends State<SupportUpiCard> {
  static const _presets = ['49', '99', '199'];
  String? _selected = '49';
  final _customController = TextEditingController();
  bool _isCustom = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const upiColor = Color(0xFF5B67CA);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        border: Border.all(color: upiColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [BoxShadow(color: upiColor.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: upiColor.withValues(alpha: 0.08)),
              ),
            ),
            Positioned(
              bottom: -20,
              left: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: upiColor.withValues(alpha: 0.05)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount chips row
                  Row(
                    children: [
                      ..._presets.map((amount) {
                        final isSelected = !_isCustom && _selected == amount;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedPress(
                            onTap: () => setState(() {
                              _selected = amount;
                              _isCustom = false;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? upiColor : upiColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: isSelected ? upiColor : upiColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                '₹$amount',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : upiColor),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Custom chip
                      AnimatedPress(
                        onTap: () => setState(() => _isCustom = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isCustom ? upiColor : upiColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: _isCustom ? upiColor : upiColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'Other',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isCustom ? Colors.white : upiColor),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Custom amount input
                  if (_isCustom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: upiColor.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: upiColor.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: upiColor.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: upiColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Pay button
                  AnimatedPress(
                    onTap: () {
                      final amount = _isCustom ? _customController.text.trim() : (_selected ?? '49');
                      if (amount.isEmpty) return;
                      widget.onPay(amount);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: upiColor, borderRadius: BorderRadius.circular(14)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.smartphoneNfc, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Pay via UPI',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.lock, size: 12, color: Colors.teal.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'GPay · PhonePe · Paytm & more',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.teal.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
