import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar el total de la venta
class TotalVentaWidget extends StatelessWidget {
  final double total;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool compacto;

  const TotalVentaWidget({
    super.key,
    required this.total,
    this.label = 'Total de la Venta:',
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.green.withOpacity(0.1);
    final txtColor = textColor ?? Colors.green;

    return Card(
      color: bgColor,
      child: Padding(
        padding: EdgeInsets.all(compacto ? 8 : 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: txtColor, size: compacto ? 20 : 24),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compacto ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: compacto ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
