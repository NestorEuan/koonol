import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/carrito_item.dart';
import '../models/cliente.dart';
import '../models/tipo_pago.dart';
import '../data/data_provider.dart';
import '../widgets/cliente_vista_reducida_widget.dart';
import '../widgets/articulo_listado_reducido_widget.dart';

class FinalizarVentaScreen extends StatefulWidget {
  final List<CarritoItem> carrito;
  final Cliente cliente;
  final Function() onVentaFinalizada;

  const FinalizarVentaScreen({
    super.key,
    required this.carrito,
    required this.cliente,
    required this.onVentaFinalizada,
  });

  @override
  State<FinalizarVentaScreen> createState() => _FinalizarVentaScreenState();
}

class _FinalizarVentaScreenState extends State<FinalizarVentaScreen> {
  late List<TipoPago> _tiposPago;
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, double> _montosPago = {};
  final TextEditingController _montoRecibidoController =
      TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tiposPago = DataProvider.getTiposPago();

    // Inicializar controladores para cada tipo de pago
    for (var tipoPago in _tiposPago) {
      _controllers[tipoPago.idTipoPago] = TextEditingController();
      _montosPago[tipoPago.idTipoPago] = 0.0;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _montoRecibidoController.dispose();
    super.dispose();
  }

  double _calcularTotal() {
    return widget.carrito.fold(0.0, (total, item) => total + item.subtotal);
  }

  int _calcularTotalArticulos() {
    return widget.carrito.fold(0, (total, item) => total + item.cantidad);
  }

  double _calcularTotalPagos() {
    return _montosPago.values.fold(0.0, (total, monto) => total + monto);
  }

  double _getMontoEfectivo() {
    // Buscar el ID del tipo de pago "Efectivo"
    final efectivo = _tiposPago.firstWhere(
      (tipo) => tipo.descripcion == 'Efectivo',
    );
    return _montosPago[efectivo.idTipoPago] ?? 0.0;
  }

  double _calcularCambio() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();
    final montoEfectivo = _getMontoEfectivo();

    // Solo hay cambio si hay efectivo y el total de pagos es mayor al total de la venta
    if (montoEfectivo > 0 && totalPagos > total) {
      return totalPagos - total;
    }
    return 0.0;
  }

  bool _validarPago() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();

    if (totalPagos == 0) {
      _mostrarError('Debe ingresar al menos un monto de pago');
      return false;
    }

    if (totalPagos < total) {
      _mostrarError('El monto total de pagos es insuficiente');
      return false;
    }

    // Si hay exceso, debe haber efectivo para dar cambio
    if (totalPagos > total) {
      final montoEfectivo = _getMontoEfectivo();
      if (montoEfectivo == 0) {
        _mostrarError('Para dar cambio debe haber pago en efectivo');
        return false;
      }
    }

    return true;
  }

  void _onMontoChanged(int idTipoPago, String valor) {
    final double monto = double.tryParse(valor) ?? 0.0;
    setState(() {
      _montosPago[idTipoPago] = monto;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _procesarVenta() async {
    if (!_validarPago()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulamos el procesamiento de la venta
      await Future.delayed(const Duration(seconds: 2));

      _mostrarExito('Venta procesada exitosamente');
      _mostrarResumenVenta();
    } catch (e) {
      _mostrarError('Error al procesar la venta: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _mostrarResumenVenta() {
    final cambio = _calcularCambio();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Venta Completada'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${widget.cliente.nombre}'),
              const Divider(),
              const Text(
                'Métodos de pago:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._tiposPago
                  .where((tipo) => _montosPago[tipo.idTipoPago]! > 0)
                  .map(
                    (tipo) => Text(
                      '${tipo.descripcion}: \$${_montosPago[tipo.idTipoPago]!.toStringAsFixed(2)}',
                    ),
                  ),
              const Divider(),
              Text('Total: \$${_calcularTotal().toStringAsFixed(2)}'),
              Text('Pagado: \$${_calcularTotalPagos().toStringAsFixed(2)}'),
              if (cambio > 0)
                Text(
                  'Cambio: \$${cambio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text('Artículos: ${_calcularTotalArticulos()}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onVentaFinalizada();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Nueva Venta'),
            ),
          ],
        );
      },
    );
  }

  Color _getEstadoPagoColor() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();

    if (totalPagos == 0) return Colors.grey;
    if (totalPagos < total) return Colors.red;
    if (totalPagos == total) return Colors.green;
    return Colors.blue; // Exceso (cambio)
  }

  String _getEstadoPagoTexto() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();

    if (totalPagos == 0) return 'Sin pagos';
    if (totalPagos < total) return 'Insuficiente';
    if (totalPagos == total) return 'Exacto';
    return 'Exceso (Cambio)';
  }

  @override
  Widget build(BuildContext context) {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();
    final cambio = _calcularCambio();
    final diferencia = totalPagos - total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Venta'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente usando el widget reutilizable
            ClienteVistaReducidaWidget(cliente: widget.cliente),

            const SizedBox(height: 16),

            // Total de la venta (con padding reducido)
            _buildTotalVenta(total),

            const SizedBox(height: 16),

            // Métodos de pago con montos
            _buildMetodosPago(),

            const SizedBox(height: 16),

            // Estado del pago
            _buildEstadoPago(totalPagos, diferencia),

            const SizedBox(height: 16),

            // Información del cambio
            if (cambio > 0) _buildCambio(cambio),

            if (cambio > 0) const SizedBox(height: 16),

            // Listado de artículos usando el widget reutilizable (solo vista) - Al final
            ArticuloListadoReducidoWidget(
              items: widget.carrito,
              editable: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBotonesAccion(),
    );
  }

  Widget _buildTotalVenta(double total) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total de la Venta:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodosPago() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Método de Pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_tiposPago.map((tipoPago) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _getTipoPagoIcon(tipoPago.descripcion),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        tipoPago.descripcion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[tipoPago.idTipoPago],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged:
                            (valor) =>
                                _onMontoChanged(tipoPago.idTipoPago, valor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Icon _getTipoPagoIcon(String descripcion) {
    switch (descripcion) {
      case 'Efectivo':
        return const Icon(Icons.attach_money, color: Colors.green);
      case 'Tarjeta de Crédito/Débito':
        return const Icon(Icons.credit_card, color: Colors.blue);
      case 'Transferencia':
        return const Icon(Icons.account_balance, color: Colors.purple);
      case 'Cheque':
        return const Icon(Icons.receipt_long, color: Colors.orange);
      default:
        return const Icon(Icons.payment, color: Colors.grey);
    }
  }

  Widget _buildEstadoPago(double totalPagos, double diferencia) {
    final color = _getEstadoPagoColor();
    final estado = _getEstadoPagoTexto();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pagos:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalPagos.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  estado,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            if (diferencia != 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    diferencia > 0 ? 'Exceso:' : 'Faltante:',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    '\$${diferencia.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
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

  Widget _buildCambio(double cambio) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.change_circle, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Cambio a Entregar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cambio:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                Text(
                  '\$${cambio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion() {
    final total = _calcularTotal();
    final totalPagos = _calcularTotalPagos();
    final puedeConfirmar =
        totalPagos >= total && (totalPagos == total || _getMontoEfectivo() > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Regresar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed:
                  _isProcessing || !puedeConfirmar ? null : _procesarVenta,
              icon:
                  _isProcessing
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
                      : const Icon(Icons.check_circle),
              label: Text(_isProcessing ? 'Procesando...' : 'Confirmar Venta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: puedeConfirmar ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
