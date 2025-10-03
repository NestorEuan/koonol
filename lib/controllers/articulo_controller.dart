import 'package:flutter/material.dart';
import '../models/articulo_mdl.dart';
import '../data/config.dart';

/// Controlador que maneja la lógica de negocio para los artículos
/// Separa la lógica de la interfaz de usuario
class ArticuloController {
  final ArticuloMdl articulo;

  late TextEditingController _precioController;
  late TextEditingController _cantidadController;
  double _cantidad = 1.0;
  late double _precio;

  // Callbacks para comunicar cambios a la UI
  final VoidCallback? onStateChanged;
  final Function(String)? onShowMessage;

  ArticuloController({
    required this.articulo,
    this.onStateChanged,
    this.onShowMessage,
  }) {
    _initializeControllers();
  }

  // Getters públicos
  double get cantidad => _cantidad;
  double get precio => _precio;
  TextEditingController get precioController => _precioController;
  TextEditingController get cantidadController => _cantidadController;

  /// Inicializa los controladores de texto
  void _initializeControllers() {
    _precio = articulo.nPrecio;
    _precioController = TextEditingController(text: _precio.toStringAsFixed(2));
    _cantidadController = TextEditingController(
      text: '0', // _cantidad.toStringAsFixed(2),
    );
  }

  /// Libera los recursos de los controladores
  void dispose() {
    _precioController.dispose();
    _cantidadController.dispose();
  }

  /// Incrementa la cantidad en 1 unidad
  void incrementarCantidad() {
    int cantidadEntera = _cantidad.toInt();
    double cantidadDecimal = _cantidad - cantidadEntera;

    if (_shouldValidateStock() &&
        (cantidadEntera + cantidadDecimal) >= articulo.existencia.toInt()) {
      _showMessage('No hay suficiente existencia');
      return;
    }

    cantidadEntera++;
    _updateCantidad(cantidadEntera.toDouble() + cantidadDecimal);
  }

  /// Decrementa la cantidad en 1 unidad (mínimo 1)
  void decrementarCantidad() {
    int cantidadEntera = _cantidad.toInt();
    double cantidadDecimal = _cantidad - cantidadEntera;

    if (cantidadEntera > 1) {
      cantidadEntera--;
      _updateCantidad(cantidadEntera.toDouble() + cantidadDecimal);
    }
  }

  /// Actualiza la cantidad desde input de texto
  void onCantidadChanged(String value) {
    final double? nuevaCantidad = double.tryParse(value);

    if (nuevaCantidad == null || nuevaCantidad <= 0) return;

    if (_shouldValidateStock() && nuevaCantidad > articulo.existencia) {
      _cantidadController.text = articulo.existencia.toString();
      _updateCantidad(articulo.existencia);
      _showMessage('Cantidad ajustada a existencia disponible');
      return;
    }

    _cantidad = nuevaCantidad;
    onStateChanged?.call();
    //    _updateCantidad(nuevaCantidad);
  }

  /// Actualiza el precio desde input de texto
  void onPrecioChanged(String value) {
    final double? nuevoPrecio = double.tryParse(value);

    if (nuevoPrecio != null && nuevoPrecio > 0) {
      _precio = nuevoPrecio;
      onStateChanged?.call();
    }
  }

  /// Valida si se puede agregar al carrito
  bool canAddToCart() {
    return _cantidad > 0 && _precio > 0 && !hasNoStock();
  }

  /// Verifica si el artículo no tiene existencia
  bool hasNoStock() {
    return _shouldValidateStock() && articulo.existencia == 0;
  }

  /// Verifica si el artículo tiene existencia baja
  bool hasLowStock() {
    return _shouldValidateStock() &&
        articulo.existencia <= 5 &&
        articulo.existencia > 0;
  }

  /// Obtiene el color para mostrar la existencia
  Color getStockColor() {
    if (hasNoStock()) return Colors.red;
    if (hasLowStock()) return Colors.orange;
    return Colors.green;
  }

  /// Obtiene el ícono de advertencia si es necesario
  Widget? getStockWarningIcon() {
    if (hasNoStock()) {
      return const Icon(Icons.warning, color: Colors.red, size: 14);
    }
    if (hasLowStock()) {
      return const Icon(Icons.warning, color: Colors.orange, size: 14);
    }
    return null;
  }

  /// Resetea la cantidad a 1
  void resetCantidad() {
    _updateCantidad(1.0);
  }

  /// Obtiene el estado actual para agregar al carrito
  Map<String, dynamic> getCartData() {
    return {'articulo': articulo, 'cantidad': _cantidad, 'precio': _precio};
  }

  // Métodos privados

  /// Actualiza la cantidad y notifica cambios
  void _updateCantidad(double nuevaCantidad) {
    _cantidad = nuevaCantidad;
    _cantidadController.text = _cantidad.toString();
    onStateChanged?.call();
  }

  /// Verifica si debe validar existencia según configuración
  bool _shouldValidateStock() {
    return AppConfig.validarExistencia;
  }

  /// Muestra un mensaje usando el callback
  void _showMessage(String message) {
    onShowMessage?.call(message);
  }
}
