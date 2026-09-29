import UIKit
import Capacitor

/**
 * Controlador de vista principal de la aplicación.
 * Subclase de CAPBridgeViewController para registrar plugins nativos locales en Capacitor 6.
 */
class ViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        super.capacitorDidLoad()
        
        // Registra la instancia del plugin nativo EasyOrderPrinter en el puente de Capacitor
        bridge?.registerPluginInstance(EasyOrderPrinterPlugin())
    }
}
