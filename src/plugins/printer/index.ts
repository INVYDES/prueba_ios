import { registerPlugin } from '@capacitor/core';
import type { EasyOrderPrinterPlugin, PrintOptions, PrintResult, PrinterStatusResult } from './definitions';

/**
 * Registro del plugin nativo 'EasyOrderPrinter' con Capacitor.
 * 
 * En iOS físico, Capacitor buscará la clase Swift anotada con:
 * `@objc(EasyOrderPrinterPlugin) public class EasyOrderPrinterPlugin: CAPPlugin`
 * 
 * Si se ejecuta en navegador Web, invocará la implementación mock/simulada
 * que definimos abajo para facilitar el desarrollo sin bloquear la interfaz.
 */
class EasyOrderPrinterWeb implements EasyOrderPrinterPlugin {
  async print(options: PrintOptions): Promise<PrintResult> {
    console.warn(
      '[EasyOrderPrinter - Web Mock] Solicitud de impresión interceptada (Fase de arquitectura).',
      options
    );
    return {
      success: true,
      message: `[MODO SIMULADO] Se simularon ${options.data.length} bytes hacia ${options.ip}:${options.port ?? 9100}. En iOS real viajará por el plugin nativo Swift vía TCP/IP.`,
      bytesWritten: options.data.length
    };
  }

  async checkStatus(options: { ip: string; port?: number; timeoutMs?: number }): Promise<PrinterStatusResult> {
    console.warn('[EasyOrderPrinter - Web Mock] Consulta de estado simulada:', options);
    return {
      connected: true,
      status: 'ONLINE',
      message: `Impresora en ${options.ip}:${options.port ?? 9100} simulada OK.`
    };
  }
}

export const Printer = registerPlugin<EasyOrderPrinterPlugin>('EasyOrderPrinter', {
  web: () => new EasyOrderPrinterWeb()
});

export * from './definitions';
