/**
 * =========================================================================
 * EASYORDER TEST - CONFIGURACIÓN CENTRAL DE LA APLICACIÓN
 * =========================================================================
 * 
 * En este archivo puedes cambiar fácilmente la URL que se cargará
 * dentro de la aplicación mediante el WebView nativo.
 */

export const APP_CONFIG = {
  // -----------------------------------------------------------------------
  // URL OBJETIVO CONFIGURABLE:
  // Inicialmente apunta a 'https://example.com' para validar la arquitectura.
  // Cuando tengas tu servidor o frontend en producción, cambia este valor por:
  // 'https://mi-dominio.com' o tu IP de desarrollo (ej. 'http://192.168.1.100:8000')
  // -----------------------------------------------------------------------
  targetWebUrl: 'https://eorder.mx/',

  // Identidad de la aplicación
  appName: 'EasyOrder Test',
  subTitle: 'Prueba de aplicación iOS',
  bundleId: 'mx.easyorder.test',
  version: '1.0.0',

  // Modo de navegación WebView:
  // 'embedded': Carga la web dentro de un contenedor WebView interno sin salir de la app
  // 'direct_redirect': Redirige la ventana principal de Capacitor a la URL remota
  defaultNavigationMode: 'embedded' as 'embedded' | 'direct_redirect'
};
