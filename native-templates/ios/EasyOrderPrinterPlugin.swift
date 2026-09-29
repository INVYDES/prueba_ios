import Foundation
import Capacitor

/**
 * =========================================================================
 * EASYORDER PRINTER - PLUGIN NATIVO SWIFT (CAPACITOR 6)
 * =========================================================================
 * 
 * Este archivo representa la estructura nativa para la Fase 2.
 * Cuando se compile el proyecto en Xcode en una Mac, este archivo o módulo
 * se vincula dentro de la carpeta `ios/App/App/`.
 * 
 * Flujo de ejecución futuro:
 * 1. Vue ejecuta: Printer.print({ ip: "192.168.1.50", port: 9100, data: "..." })
 * 2. Capacitor deserializa el JSON y llama a esta función `print(_ call: CAPPluginCall)`
 * 3. En la Fase 2, aquí se abrirá un socket NWConnection (Network.framework de Apple)
 *    hacia la IP y Puerto indicados, escribiendo los bytes ESC/POS.
 */

@objc(EasyOrderPrinterPlugin)
public class EasyOrderPrinterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "EasyOrderPrinterPlugin"
    public let jsName = "EasyOrderPrinter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "print", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkStatus", returnType: CAPPluginReturnPromise)
    ]

    @objc func print(_ call: CAPPluginCall) {
        guard let ip = call.getString("ip"), !ip.isEmpty else {
            call.reject("Debe proporcionar una dirección IP válida.")
            return
        }

        let port = call.getInt("port") ?? 9100
        let data = call.getString("data") ?? ""
        let timeoutMs = call.getInt("timeoutMs") ?? 5000

        // =====================================================================
        // NOTA FASE 2: Aquí se implementará la apertura de socket TCP con
        // Network.framework (NWConnection) o POSIX BSD sockets hacia ip:port.
        // =====================================================================

        NSLog("[EasyOrderPrinter Native iOS] Solicitud recibida: IP=%@, Puerto=%d, Bytes=%d, Timeout=%d", ip, port, data.count, timeoutMs)

        // Respuesta provisional confirmando recepción nativa (Estructura lista):
        call.resolve([
            "success": true,
            "message": "Comando recibido en el entorno nativo iOS de EasyOrder. Listo para enlazar socket TCP.",
            "bytesWritten": data.count
        ])
    }

    @objc func checkStatus(_ call: CAPPluginCall) {
        guard let ip = call.getString("ip") else {
            call.reject("Falta dirección IP")
            return
        }
        let port = call.getInt("port") ?? 9100

        call.resolve([
            "connected": true,
            "status": "ONLINE",
            "message": "Host \(ip):\(port) en espera de verificación de socket."
        ])
    }
}
