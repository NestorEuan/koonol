import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar el estado de validación del cobro
/// Muestra el total a pagar, total de pagos, diferencia y cambio
class ValidacionCobroWidget extends StatelessWidget {
  final double totalVenta;
  final double totalPagos;
  final double cambio;
  final double montoEfectivo;
  final bool mostrarCambio;
  final bool compacto;

  const ValidacionCobroWidget({
    super.key,
    required this.totalVenta,
    required this.totalPagos,
    required this.cambio,
    this.montoEfectivo = 0.0,
    this.mostrarCambio = true,
    this.compacto = false,
  });

  /// Calcula la diferencia entre pagos y total
  double get diferencia => totalPagos - totalVenta;

  /// Determina si el pago es válido
  bool get esValido => totalPagos >= totalVenta;

  /// Obtiene el color según el estado del pago
  Color getEstadoPagoColor() {
    if (totalPagos == 0) return Colors.grey;
    if (totalPagos < totalVenta) return Colors.red;
    if (totalPagos == totalVenta) return Colors.green;
    return Colors.blue; // Exceso (cambio)
  }

  /// Obtiene el texto del estado
  String getEstadoPagoTexto() {
    if (totalPagos == 0) return 'Sin pagos';
    if (totalPagos < totalVenta) return 'Insuficiente';
    if (totalPagos == totalVenta) return 'Exacto';
    return 'Exceso (Cambio)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Estado del pago
        _buildEstadoPago(),

        // Información del cambio (si aplica)
        if (mostrarCambio && cambio > 0) ...[
          const SizedBox(height: 8),
          _buildCambio(),
        ],
      ],
    );
  }

  /// Construye la tarjeta de estado del pago
  Widget _buildEstadoPago() {
    final color = getEstadoPagoColor();
    final estado = getEstadoPagoTexto();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(compacto ? 8 : 12),
        child: Column(
          children: [
            // Total de pagos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pagos:',
                  style: TextStyle(
                    fontSize: compacto ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${totalPagos.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: compacto ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),

            SizedBox(height: compacto ? 4 : 6),

            // Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado:',
                  style: TextStyle(
                    fontSize: compacto ? 12 : 14,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getEstadoIcon(),
                      size: compacto ? 14 : 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      estado,
                      style: TextStyle(
                        fontSize: compacto ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Diferencia (solo si no es exacto)
            if (diferencia != 0) ...[
              SizedBox(height: compacto ? 4 : 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    diferencia > 0 ? 'Exceso:' : 'Faltante:',
                    style: TextStyle(
                      fontSize: compacto ? 12 : 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '\$${diferencia.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: compacto ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: diferencia > 0 ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de cambio
  Widget _buildCambio() {
    final exceso = diferencia;
    final cambioLimitado = cambio < exceso;

    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(compacto ? 8 : 12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.change_circle, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cambio a Entregar',
                  style: TextStyle(
                    fontSize: compacto ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: compacto ? 4 : 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cambio:',
                  style: TextStyle(
                    fontSize: compacto ? 16 : 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${cambio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: compacto ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            // Advertencia si el cambio está limitado por el efectivo
            if (cambioLimitado && montoEfectivo > 0) ...[
              SizedBox(height: compacto ? 6 : 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cambio limitado al efectivo recibido: \$${montoEfectivo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Obtiene el ícono según el estado
  IconData _getEstadoIcon() {
    if (totalPagos == 0) return Icons.info_outline;
    if (totalPagos < totalVenta) return Icons.error_outline;
    if (totalPagos == totalVenta) return Icons.check_circle_outline;
    return Icons.swap_horiz;
  }
}
