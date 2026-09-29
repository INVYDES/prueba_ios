#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

/**
 * Registro de métodos Capacitor en Objective-C Runtime para iOS
 */
CAP_PLUGIN(EasyOrderPrinterPlugin, "EasyOrderPrinter",
   CAP_PLUGIN_METHOD(print, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(checkStatus, CAPPluginReturnPromise);
)
