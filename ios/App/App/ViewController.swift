import UIKit
import Capacitor
import WebKit

/**
 * Controlador de vista principal de la aplicación.
 * Subclase de CAPBridgeViewController para registrar plugins nativos locales en Capacitor 6
 * e interceptar window.print() para habilitar AirPrint nativo.
 */
class ViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        super.capacitorDidLoad()
        
        // Registra la instancia del plugin nativo EasyOrderPrinter en el puente de Capacitor
        bridge?.registerPluginInstance(EasyOrderPrinterPlugin())
        
        // Intercepta window.print() en eorder.mx para abrir la ventana oficial de AirPrint
        let printPolyfill = """
        window.print = function() {
            if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.EasyOrderPrinter) {
                window.Capacitor.Plugins.EasyOrderPrinter.printCurrentPage();
            }
        };
        """
        let userScript = WKUserScript(source: printPolyfill, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        bridge?.webView?.configuration.userContentController.addUserScript(userScript)
    }
}
