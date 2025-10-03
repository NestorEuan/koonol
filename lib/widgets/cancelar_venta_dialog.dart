import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta_mdl.dart';
import '../data/database_manager.dart';

class CancelarVentaDialog extends StatefulWidget {
  final VentaMdl venta;

  const CancelarVentaDialog({super.key, required this.venta});

  @override
  State<CancelarVentaDialog> createState() => _CancelarVentaDialogState();
}

class _CancelarVentaDialogState extends State<CancelarVentaDialog> {
  final _motivoController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _detalleVenta;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _cargarDetalleVenta();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalleVenta() async {
    try {
      final dbManager = DatabaseManager();
      final db = await dbManager.database;

      // Obtener detalles básicos
      final detalles = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as totalItems,
          COALESCE(SUM(nCantidad), 0) as totalArticulos
        FROM ventadetalle
        WHERE idVenta = ?
        ''',
        [widget.venta.idVenta!],
      );

      if (mounted) {
        setState(() {
          _detalleVenta = detalles.first;
        });
      }
    } catch (e) {
      // Error silencioso, no es crítico
    }
  }

  Future<void> _procesarCancelacion() async {
    // Validar motivo
    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe ingresar un motivo para la cancelación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final dbManager = DatabaseManager();
      await _cancelarVentaConTransaccion(dbManager);

      if (mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta cancelada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarVentaConTransaccion(DatabaseManager dbManager) async {
    await dbManager.transaction((txn) async {
      final idVenta = widget.venta.idVenta!;

      // 1. Obtener el corte asociado
      final corteCajaVenta = await txn.query(
        'cortecajaventa',
        where: 'idVenta = ?',
        whereArgs: [idVenta],
        limit: 1,
      );

      if (corteCajaVenta.isEmpty) {
        throw Exception('No se encontró el corte asociado');
      }

      final idCorteCaja = corteCajaVenta.first['idCorteCaja'] as int;

      // 2. Actualizar estado de la venta a CANCELADA
      await txn.update(
        'venta',
        {'cEstado': 'CANCELADA'},
        where: 'idVenta = ?',
        whereArgs: [idVenta],
      );

      // 3. Obtener detalles de la venta para restar de acumulados
      final detalles = await txn.query(
        'ventadetalle',
        where: 'idVenta = ?',
        whereArgs: [idVenta],
      );

      // 4. Restar de acumulados de artículos
      for (var detalle in detalles) {
        final idArticulo = detalle['idArticulo'] as int;
        final cantidad = (detalle['nCantidad'] as double?) ?? 0.0;
        final precio = (detalle['nPrecio'] as double?) ?? 0.0;
        final costo = (detalle['nCosto'] as double?) ?? 0.0;

        final importeItem = cantidad * precio;
        final costoItem = cantidad * costo;

        // Verificar si existe el acumulado
        final existing = await txn.query(
          'acumcortedetalle',
          where: 'idCorte = ? AND idArticulo = ?',
          whereArgs: [idCorteCaja, idArticulo],
        );

        if (existing.isNotEmpty) {
          final importeActual = (existing.first['nImporte'] as double?) ?? 0.0;
          final costoActual = (existing.first['nCosto'] as double?) ?? 0.0;

          // Restar los valores (asegurar que no sean negativos)
          final nuevoImporte = (importeActual - importeItem).clamp(
            0.0,
            double.infinity,
          );
          final nuevoCosto = (costoActual - costoItem).clamp(
            0.0,
            double.infinity,
          );

          await txn.update(
            'acumcortedetalle',
            {'nImporte': nuevoImporte, 'nCosto': nuevoCosto},
            where: 'idCorte = ? AND idArticulo = ?',
            whereArgs: [idCorteCaja, idArticulo],
          );
        }
      }

      // 5. Obtener tipos de pago de la venta
      final tiposPago = await txn.query(
        'ventatipopago',
        where: 'idVenta = ?',
        whereArgs: [idVenta],
      );

      // 6. Restar de acumulados de tipos de pago
      for (var tipoPago in tiposPago) {
        final idTipoPago = tipoPago['idTipoPago'] as int;
        final importe = (tipoPago['nImporte'] as double?) ?? 0.0;

        final existing = await txn.query(
          'acumcortetipopago',
          where: 'idCorteCaja = ? AND idTipoPago = ?',
          whereArgs: [idCorteCaja, idTipoPago],
        );

        if (existing.isNotEmpty) {
          final importeActual = (existing.first['nImporte'] as double?) ?? 0.0;
          final nuevoImporte = (importeActual - importe).clamp(
            0.0,
            double.infinity,
          );

          await txn.update(
            'acumcortetipopago',
            {'nImporte': nuevoImporte},
            where: 'idCorteCaja = ? AND idTipoPago = ?',
            whereArgs: [idCorteCaja, idTipoPago],
          );
        }
      }

      // 7. Eliminar la venta del corte (cortecajaventa)
      await txn.delete(
        'cortecajaventa',
        where: 'idVenta = ?',
        whereArgs: [idVenta],
      );

      // 8. Recalcular el importe total del corte
      final totalResult = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(nImporte + nIVA - nDescuento), 0) as total 
        FROM cortecajaventa 
        WHERE idCorteCaja = ?
        ''',
        [idCorteCaja],
      );

      final totalCorte = (totalResult.first['total'] as double?) ?? 0.0;

      await txn.update(
        'cortecaja',
        {'nImporte': totalCorte},
        where: 'idCorteCaja = ?',
        whereArgs: [idCorteCaja],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Cancelar Venta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Advertencia
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Esta acción actualizará todos los acumulados y no se puede deshacer.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información de la venta
                  _buildInfoSection(),

                  const SizedBox(height: 16),

                  // Campo de motivo
                  TextField(
                    controller: _motivoController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de cancelación *',
                      hintText: 'Ingrese el motivo...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    maxLines: 3,
                    enabled: !_isProcessing,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    '* Campo obligatorio',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _procesarCancelacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venta #${widget.venta.idVenta}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Fecha:', _dateFormat.format(widget.venta.dtAlta)),
          _buildInfoRow('Total:', '\$${widget.venta.total.toStringAsFixed(2)}'),
          if (_detalleVenta != null) ...[
            _buildInfoRow(
              'Artículos:',
              '${(_detalleVenta!['totalArticulos'] as double).toStringAsFixed(0)} unidades',
            ),
            _buildInfoRow(
              'Items:',
              '${_detalleVenta!['totalItems']} productos',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
