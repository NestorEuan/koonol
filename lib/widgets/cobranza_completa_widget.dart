import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/articulo_mdl.dart';
import '../models/tipo_pago_mdl.dart';
import '../models/cliente.dart';
import '../controllers/articulo_controller.dart';
import '../services/ui_service.dart';
import '../widgets/tipos_pago_widget.dart';
import '../widgets/validacion_cobro_widget.dart';
import '../widgets/total_venta_widget.dart';

/// Widget de cobranza completa
/// Integra: artículo kilo, tipos de pago y validación de cobro
/// Ideal para ventas rápidas en una sola pantalla
class CobranzaCompletaWidget extends StatefulWidget {
  final ArticuloMdl articulo;
  final Cliente? cliente;
  final List<TipoPagoMdl> tiposPago;
  final Function(
    ArticuloMdl articulo,
    double cantidad,
    double precio,
    Map<int, double> tiposPago,
    double totalPagado,
    double cambio,
  )?
  onConfirmarVenta;
  final VoidCallback? onCancelar;

  const CobranzaCompletaWidget({
    super.key,
    required this.articulo,
    this.cliente,
    required this.tiposPago,
    this.onConfirmarVenta,
    this.onCancelar,
  });

  @override
  State<CobranzaCompletaWidget> createState() => _CobranzaCompletaWidgetState();
}

class _CobranzaCompletaWidgetState extends State<CobranzaCompletaWidget> {
  late ArticuloController _articuloController;
  final Map<int, double> _montosPago = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _articuloController = ArticuloController(
      articulo: widget.articulo,
      onStateChanged: () => setState(() {}),
      onShowMessage: (message) => UIService.showWarning(context, message),
    );

    // Inicializar montos de pago en 0
    for (var tipoPago in widget.tiposPago) {
      _montosPago[tipoPago.idTipoPago ?? 0] = 0.0;
    }
  }

  @override
  void dispose() {
    _articuloController.dispose();
    super.dispose();
  }

  // Cálculos
  double get _totalVenta =>
      _articuloController.cantidad * _articuloController.precio;

  double get _totalPagos =>
      _montosPago.values.fold(0.0, (sum, monto) => sum + monto);

  double get _montoEfectivo {
    try {
      final efectivo = widget.tiposPago.firstWhere(
        (tipo) => tipo.cTipoPago.toLowerCase().contains('efectivo'),
      );
      return _montosPago[efectivo.idTipoPago] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double get _cambio {
    if (_montoEfectivo > 0 && _totalPagos > _totalVenta) {
      final exceso = _totalPagos - _totalVenta;
      return exceso <= _montoEfectivo ? exceso : _montoEfectivo;
    }
    return 0.0;
  }

  bool get _puedeConfirmar {
    return _articuloController.canAddToCart() &&
        _totalPagos >= _totalVenta &&
        (_totalPagos == _totalVenta || _montoEfectivo > 0);
  }

  void _onMontoChanged(int idTipoPago, double monto) {
    setState(() {
      _montosPago[idTipoPago] = monto;
    });
  }

  void _confirmarVenta() {
    if (!_puedeConfirmar) {
      UIService.showWarning(context, 'Verifique los datos de la venta');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Filtrar solo los tipos de pago con monto > 0
      final Map<int, double> tiposPagoFiltrados = {};
      _montosPago.forEach((id, monto) {
        if (monto > 0) {
          tiposPagoFiltrados[id] = monto;
        }
      });

      if (widget.onConfirmarVenta != null) {
        widget.onConfirmarVenta!(
          widget.articulo,
          _articuloController.cantidad,
          _articuloController.precio,
          tiposPagoFiltrados,
          _totalPagos,
          _cambio,
        );
      }

      // Limpiar y resetear
      _limpiarFormulario();
      UIService.showSuccess(context, 'Venta registrada exitosamente');
    } catch (e) {
      UIService.showError(context, 'Error al procesar venta: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _articuloController.resetCantidad();
      _montosPago.updateAll((key, value) => 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header con información del cliente
          _buildHeader(),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección 1: Artículo
                  _buildSeccionArticulo(),

                  const SizedBox(height: 16),

                  // Sección 2: Total de la venta
                  TotalVentaWidget(
                    total: _totalVenta,
                    icon: Icons.shopping_cart,
                    compacto: true,
                  ),

                  const SizedBox(height: 16),

                  // Sección 3: Tipos de pago
                  TiposPagoWidget(
                    tiposPago: widget.tiposPago,
                    montosPago: _montosPago,
                    onMontoChanged: _onMontoChanged,
                    enabled: !_isProcessing,
                    compacto: true,
                  ),

                  const SizedBox(height: 16),

                  // Sección 4: Validación de cobro
                  ValidacionCobroWidget(
                    totalVenta: _totalVenta,
                    totalPagos: _totalPagos,
                    cambio: _cambio,
                    montoEfectivo: _montoEfectivo,
                    compacto: true,
                  ),
                ],
              ),
            ),
          ),

          // Footer con botones de acción
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cobranza Rápida',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.cliente != null)
                  Text(
                    widget.cliente!.nombre,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),
          if (widget.onCancelar != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _isProcessing ? null : widget.onCancelar,
              tooltip: 'Cerrar',
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionArticulo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del artículo
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.articulo.cDescripcion,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Código: ${widget.articulo.cCodigo}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campos de Precio y Cantidad
          Row(
            children: [
              // Precio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Precio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _articuloController.precioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: _articuloController.onPrecioChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Cantidad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cantidad',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _articuloController.cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: _articuloController.onCantidadChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicadores visuales
            Row(
              children: [
                Expanded(
                  child: _buildIndicador(
                    'Artículo',
                    _articuloController.canAddToCart(),
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildIndicador(
                    'Pago',
                    _totalPagos >= _totalVenta,
                    Icons.payment,
                  ),
                ),
                Expanded(
                  child: _buildIndicador(
                    'Cambio',
                    _totalPagos == _totalVenta || _montoEfectivo > 0,
                    Icons.change_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _limpiarFormulario,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing || !_puedeConfirmar
                        ? null
                        : _confirmarVenta,
                    icon: _isProcessing
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
                        : const Icon(Icons.check_circle, size: 20),
                    label: Text(
                      _isProcessing ? 'Procesando...' : 'Confirmar Venta',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _puedeConfirmar
                          ? Colors.green
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicador(String label, bool completo, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: completo ? Colors.green : Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: completo ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
