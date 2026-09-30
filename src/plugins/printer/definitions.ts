/**
 * =========================================================================
 * FASE 2: PREPARACIÓN DE ARQUITECTURA DE IMPRESIÓN (EasyOrderPrinter)
 * =========================================================================
 * 
 * Este archivo define las interfaces TypeScript para el futuro plugin nativo
 * de Capacitor que se comunicará vía TCP/IP con impresoras térmicas ESC/POS.
 * 
 * Arquitectura prevista:
 * Vue (Frontend)
 *   ↓
 * Capacitor Plugin (TypeScript Bridge)
 *   ↓
 * Código Nativo iOS (Swift / Network.framework / POSIX Sockets)
 *   ↓
 * Red Local TCP/IP
 *   ↓
 * Impresora térmica ESC/POS (puerto 9100)
 */

export interface PrintOptions {
  /** Dirección IP local de la impresora térmica (ej: "192.168.1.50") */
  ip: string;

  /** Puerto RAW / JetDirect (por defecto 9100 para impresoras térmicas ESC/POS) */
  port?: number;

  /** Comandos ESC/POS a enviar (cadena de texto, bytes codificados en base64 o hex) */
  data: string;

  /** Tiempo máximo de espera en milisegundos (timeout) */
  timeoutMs?: number;
}

export interface PrintResult {
  /** Indica si los datos se enviaron exitosamente por el socket TCP */
  success: boolean;

  /** Mensaje de estado o diagnóstico */
  message: string;

  /** Cantidad de bytes transmitidos */
  bytesWritten?: number;
}

export interface PrinterStatusResult {
  connected: boolean;
  status: 'ONLINE' | 'OFFLINE' | 'BUSY' | 'PAPER_OUT' | 'UNKNOWN';
  message?: string;
}

export interface EasyOrderPrinterPlugin {
  /**
   * Envía un paquete de datos ESC/POS directamente a la impresora vía socket TCP/IP
   */
  print(options: PrintOptions): Promise<PrintResult>;

  /**
   * Comprueba si el host y puerto de la impresora responden en la red local
   */
  checkStatus(options: { ip: string; port?: number; timeoutMs?: number }): Promise<PrinterStatusResult>;

  /**
   * Abre el diálogo nativo de Apple AirPrint para imprimir la página web actual
   */
  printCurrentPage(): Promise<{ completed: boolean }>;
}
