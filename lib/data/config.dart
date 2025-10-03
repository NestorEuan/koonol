class AppConfig {
  static bool validarExistencia =
      false; // Variable global para controlar validación

  // Otros valores de configuración que puedas necesitar después
  static bool mostrarCosto = false;
  static bool permitirVentasNegativas = false;
  static double margenMinimoPermitido = 0.0;

  // NUEVO: Control de vista simplificada para kilo de huevo
  static bool mostrarVistaSimplificada = true; // Cambiar a true para habilitar

  static void habilitarValidacionExistencia() {
    validarExistencia = true;
  }

  static void deshabilitarValidacionExistencia() {
    validarExistencia = false;
  }

  static void toggleValidacionExistencia() {
    validarExistencia = !validarExistencia;
  }
}
