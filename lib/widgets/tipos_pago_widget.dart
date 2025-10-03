import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tipo_pago_mdl.dart';

/// Widget reutilizable para mostrar y capturar tipos de pago
/// Puede usarse en múltiples pantallas como finalizar venta, devoluciones, etc.
class TiposPagoWidget extends StatefulWidget {
  final List<TipoPagoMdl> tiposPago;
  final Map<int, double> montosPago;
  final Function(int idTipoPago, double monto) onMontoChanged;
  final bool enabled;
  final bool compacto; // Para vista compacta (grid de 2 columnas)

  const TiposPagoWidget({
    super.key,
    required this.tiposPago,
    required this.montosPago,
    required this.onMontoChanged,
    this.enabled = true,
    this.compacto = true,
  });

  @override
  State<TiposPagoWidget> createState() => _TiposPagoWidgetState();
}

class _TiposPagoWidgetState extends State<TiposPagoWidget> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (var tipoPago in widget.tiposPago) {
      final id = tipoPago.idTipoPago ?? 0;
      final monto = widget.montosPago[id] ?? 0.0;
      _controllers[id] = TextEditingController(
        text: monto > 0 ? monto.toStringAsFixed(2) : '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Método de Pago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid de tipos de pago
            if (widget.compacto)
              ..._buildGridCompacto()
            else
              ..._buildListaNormal(),
          ],
        ),
      ),
    );
  }

  /// Construye el grid compacto de 2 columnas
  List<Widget> _buildGridCompacto() {
    return List.generate((widget.tiposPago.length / 2).ceil(), (rowIndex) {
      final startIndex = rowIndex * 2;
      final endIndex = (startIndex + 2 > widget.tiposPago.length)
          ? widget.tiposPago.length
          : startIndex + 2;
      final rowItems = widget.tiposPago.sublist(startIndex, endIndex);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: _buildTipoPagoItem(rowItems[0])),
            const SizedBox(width: 8),
            Expanded(
              child: rowItems.length > 1
                  ? _buildTipoPagoItem(rowItems[1])
                  : const SizedBox(),
            ),
          ],
        ),
      );
    });
  }

  /// Construye una lista normal de tipos de pago (1 por fila)
  List<Widget> _buildListaNormal() {
    return widget.tiposPago.map((tipoPago) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildTipoPagoItem(tipoPago),
      );
    }).toList();
  }

  /// Construye un item individual de tipo de pago
  Widget _buildTipoPagoItem(TipoPagoMdl tipoPago) {
    final id = tipoPago.idTipoPago ?? 0;

    return Row(
      children: [
        _getTipoPagoIcon(tipoPago.cTipoPago),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(
            tipoPago.cTipoPago,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _controllers[id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: widget.enabled,
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (valor) {
              final monto = double.tryParse(valor) ?? 0.0;
              widget.onMontoChanged(id, monto);
            },
          ),
        ),
      ],
    );
  }

  /// Obtiene el ícono correspondiente al tipo de pago
  Icon _getTipoPagoIcon(String descripcion) {
    final desc = descripcion.toLowerCase();
    if (desc.contains('efectivo')) {
      return const Icon(Icons.attach_money, color: Colors.green, size: 18);
    } else if (desc.contains('tarjeta') ||
        desc.contains('crédito') ||
        desc.contains('débito')) {
      return const Icon(Icons.credit_card, color: Colors.blue, size: 18);
    } else if (desc.contains('transferencia')) {
      return const Icon(Icons.account_balance, color: Colors.purple, size: 18);
    } else if (desc.contains('cheque')) {
      return const Icon(Icons.receipt_long, color: Colors.orange, size: 18);
    } else {
      return const Icon(Icons.payment, color: Colors.grey, size: 18);
    }
  }
}
