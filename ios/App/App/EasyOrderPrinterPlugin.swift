import Foundation
import Capacitor
import Network

/**
 * =========================================================================
 * EASYORDER PRINTER - PLUGIN NATIVO SWIFT (CAPACITOR 6)
 * =========================================================================
 *
 * Implementa comunicación TCP/IP directa mediante Network.framework (Apple)
 * hacia impresoras térmicas ESC/POS (puerto estándar 9100).
 */
@objc(EasyOrderPrinterPlugin)
public class EasyOrderPrinterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "EasyOrderPrinterPlugin"
    public let jsName = "EasyOrderPrinter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "print", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkStatus", returnType: CAPPluginReturnPromise)
    ]

    /**
     * Comprueba si el socket TCP de la impresora responde en la red local
     */
    @objc func checkStatus(_ call: CAPPluginCall) {
        guard let ip = call.getString("ip"), !ip.isEmpty else {
            call.reject("Dirección IP no válida.")
            return
        }

        let portNum = UInt16(call.getInt("port") ?? 9100)
        let timeoutMs = call.getInt("timeoutMs") ?? 3000

        guard let endpointPort = NWEndpoint.Port(rawValue: portNum) else {
            call.reject("Puerto inválido: \(portNum)")
            return
        }

        let endpointHost = NWEndpoint.Host(ip)
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = max(1, timeoutMs / 1000)

        let params = NWParameters(tls: nil, tcp: tcpOptions)
        let connection = NWConnection(host: endpointHost, port: endpointPort, using: params)

        var hasFinished = false

        connection.stateUpdateHandler = { state in
            guard !hasFinished else { return }
            switch state {
            case .ready:
                hasFinished = true
                connection.cancel()
                call.resolve([
                    "connected": true,
                    "status": "ONLINE",
                    "message": "Impresora disponible en \(ip):\(portNum)"
                ])
            case .failed(let error):
                hasFinished = true
                connection.cancel()
                call.resolve([
                    "connected": false,
                    "status": "OFFLINE",
                    "message": "Fallo al conectar con \(ip):\(portNum): \(error.localizedDescription)"
                ])
            default:
                break
            }
        }

        connection.start(queue: .global())

        // Timeout preventivo de seguridad
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
            if !hasFinished {
                hasFinished = true
                connection.cancel()
                call.resolve([
                    "connected": false,
                    "status": "TIMEOUT",
                    "message": "Tiempo agotado (\(timeoutMs)ms) buscando impresora en \(ip):\(portNum)"
                ])
            }
        }
    }

    /**
     * Envía comanda o ticket en formato ESC/POS vía socket TCP directo
     */
    @objc func print(_ call: CAPPluginCall) {
        guard let ip = call.getString("ip"), !ip.isEmpty else {
            call.reject("Debe proporcionar una dirección IP válida.")
            return
        }

        let portNum = UInt16(call.getInt("port") ?? 9100)
        let dataString = call.getString("data") ?? ""
        let timeoutMs = call.getInt("timeoutMs") ?? 5000

        guard let endpointPort = NWEndpoint.Port(rawValue: portNum) else {
            call.reject("Puerto inválido: \(portNum)")
            return
        }

        let endpointHost = NWEndpoint.Host(ip)

        // Soporta datos codificados en Base64 o texto plano UTF-8
        let dataToSend: Data
        if let base64Data = Data(base64Encoded: dataString) {
            dataToSend = base64Data
        } else {
            dataToSend = dataString.data(using: .utf8) ?? Data()
        }

        guard !dataToSend.isEmpty else {
            call.reject("No hay datos para imprimir.")
            return
        }

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = max(1, timeoutMs / 1000)

        let params = NWParameters(tls: nil, tcp: tcpOptions)
        let connection = NWConnection(host: endpointHost, port: endpointPort, using: params)

        var hasFinished = false

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                // Conexión TCP establecida con éxito, enviamos el paquete de bytes
                connection.send(content: dataToSend, completion: .contentProcessed { sendError in
                    guard !hasFinished else { return }
                    hasFinished = true

                    // Esperamos 100ms para asegurar que el buffer se vacíe en la impresora antes de cerrar
                    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
                        connection.cancel()
                    }

                    if let error = sendError {
                        call.reject("Error al transmitir datos a la impresora: \(error.localizedDescription)")
                    } else {
                        call.resolve([
                            "success": true,
                            "bytesWritten": dataToSend.count,
                            "message": "Comanda (\(dataToSend.count) bytes) enviada con éxito a \(ip):\(portNum)."
                        ])
                    }
                })
            case .failed(let error):
                guard !hasFinished else { return }
                hasFinished = true
                connection.cancel()
                call.reject("No se pudo conectar a la impresora en \(ip):\(portNum): \(error.localizedDescription)")
            default:
                break
            }
        }

        connection.start(queue: .global())

        // Timeout preventivo de seguridad
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
            if !hasFinished {
                hasFinished = true
                connection.cancel()
                call.reject("Tiempo de espera agotado al conectar a \(ip):\(portNum). Verifica que la impresora esté encendida y en la misma red Wi-Fi.")
            }
        }
    }
}
