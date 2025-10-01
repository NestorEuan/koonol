import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta_mdl.dart';
import '../data/venta.dart';
import '../data/database_manager.dart';

class DetalleVentaDialog extends StatefulWidget {
  final VentaMdl venta;

  const DetalleVentaDialog({super.key, required this.venta});

  @override
  State<DetalleVentaDialog> createState() => _DetalleVentaDialogState();
}

class _DetalleVentaDialogState extends State<DetalleVentaDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _detalleCompleto;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final dbManager = DatabaseManager();
      final database = await dbManager.database;
      final ventaRepo = Venta(database);

      final detalle = await ventaRepo.getDetalleCompletoVenta(
        widget.venta.idVenta!,
      );

      if (mounted) {
        setState(() {
          _detalleCompleto = detalle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esActiva = widget.venta.cEstado == 'ACTIVA';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esActiva ? Colors.green : Colors.red,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    esActiva ? Icons.receipt_long : Icons.cancel,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Venta #${widget.venta.idVenta}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.venta.cEstado,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Contenido
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_detalleCompleto != null)
              Expanded(child: _buildContenido())
            else
              const Expanded(
                child: Center(child: Text('Error al cargar detalle')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    final detalles = _detalleCompleto!['detalles'] as List;
    final tiposPago = _detalleCompleto!['tiposPago'] as List;
    final totalArticulos = _detalleCompleto!['totalArticulos'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información general
          _buildSeccion('Información General', [
            _buildInfoRow('Fecha:', _dateFormat.format(widget.venta.dtAlta)),
            _buildInfoRow('Cliente ID:', '${widget.venta.idCliente}'),
            _buildInfoRow(
              'Total Artículos:',
              totalArticulos.toStringAsFixed(2),
            ),
          ]),

          const SizedBox(height: 16),

          // Artículos
          _buildSeccion(
            'Artículos (${detalles.length})',
            detalles.map((detalle) {
              final cantidad = (detalle['nCantidad'] as double?) ?? 0.0;
              final precio = (detalle['nPrecio'] as double?) ?? 0.0;
              final subtotal = cantidad * precio;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detalle['descripcionArticulo'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Código: ${detalle['codigoArticulo'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Cant: ${cantidad.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Precio: \$${precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Tipos de pago
          _buildSeccion(
            'Formas de Pago',
            tiposPago.map((tipo) {
              final importe = (tipo['nImporte'] as double?) ?? 0.0;
              return _buildInfoRow(
                tipo['descripcionTipoPago'] ?? 'Desconocido',
                '\$${importe.toStringAsFixed(2)}',
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Totales
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                _buildTotalRow('Subtotal:', widget.venta.nImporte),
                if (widget.venta.nIVA > 0)
                  _buildTotalRow('IVA:', widget.venta.nIVA),
                if (widget.venta.nDescuento > 0)
                  _buildTotalRow('Descuento:', -widget.venta.nDescuento),
                const Divider(),
                _buildTotalRow(
                  'Total:',
                  widget.venta.total,
                  esBold: true,
                  colorTexto: Colors.green,
                ),
                _buildTotalRow('Pagado:', widget.venta.nTotalPagado),
                if (widget.venta.nCambio > 0)
                  _buildTotalRow(
                    'Cambio:',
                    widget.venta.nCambio,
                    colorTexto: Colors.blue,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double valor, {
    bool esBold = false,
    Color? colorTexto,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: esBold ? FontWeight.bold : FontWeight.normal,
              color: colorTexto,
            ),
          ),
          Text(
            '\$${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: esBold ? FontWeight.bold : FontWeight.w500,
              fontSize: esBold ? 16 : 14,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}
