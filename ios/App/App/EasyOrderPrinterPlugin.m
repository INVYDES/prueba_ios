#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

/**
 * Registro de EasyOrderPrinterPlugin en el runtime de Capacitor
 */
CAP_PLUGIN(EasyOrderPrinterPlugin, "EasyOrderPrinter",
    CAP_PLUGIN_METHOD(print, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(checkStatus, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(printCurrentPage, CAPPluginReturnPromise);
)
