import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Servicio para manejo de elementos de UI comunes
/// Centraliza funcionalidades como mostrar mensajes, validaciones, etc.
class UIService {
  /// Muestra un mensaje en SnackBar
  static void showMessage(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.green,
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Muestra mensaje de éxito
  static void showSuccess(BuildContext context, String message) {
    showMessage(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  /// Muestra mensaje de error
  static void showError(BuildContext context, String message) {
    showMessage(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  /// Muestra mensaje de advertencia
  static void showWarning(BuildContext context, String message) {
    showMessage(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  /// Muestra mensaje de información
  static void showInfo(BuildContext context, String message) {
    showMessage(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
    );
  }

  /// Crea un InputFormatter para precios (números con máximo 2 decimales)
  static String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Crea un InputFormatter para cantidades
  static String formatQuantity(double quantity) {
    // Si es entero, no mostrar decimales
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  /// Valida si un string es un número válido
  static bool isValidNumber(String value) {
    return double.tryParse(value) != null;
  }

  /// Valida si un precio es válido (mayor a 0)
  static bool isValidPrice(String value) {
    final price = double.tryParse(value);
    return price != null && price > 0;
  }

  /// Valida si una cantidad es válida (mayor a 0)
  static bool isValidQuantity(String value) {
    final quantity = double.tryParse(value);
    return quantity != null && quantity > 0;
  }

  /// Crea un botón estilizado para los widgets
  static Widget createStyledButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double fontSize = 12,
    EdgeInsetsGeometry? padding,
    double iconSize = 16,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(text, style: TextStyle(fontSize: fontSize)),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Crea un contenedor de información con estilo consistente
  static Widget createInfoContainer({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(top: 8),
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? Colors.red.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  /// Crea un badge con estilo consistente
  static Widget createBadge({
    required String text,
    Color backgroundColor = Colors.orange,
    Color textColor = Colors.white,
    double fontSize = 10,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Crea un campo de texto estilizado
  static Widget createStyledTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    bool enabled = true,
    double fontSize = 12,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSize - 1, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          enabled: enabled,
          style: TextStyle(fontSize: fontSize),
          decoration: InputDecoration(
            prefixText: prefixText,
            isDense: true,
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// Crea botones de incremento/decremento
  static Widget createQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
    double size = 16,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: size,
            color: enabled ? (color ?? Colors.black) : Colors.grey,
          ),
        ),
      ),
    );
  }
}
