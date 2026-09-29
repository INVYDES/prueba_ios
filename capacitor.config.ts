import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  // Identificador de la aplicación en iOS (Bundle Identifier)
  appId: 'mx.easyorder.test',

  // Nombre visible en la pantalla de inicio del iPhone/iPad
  appName: 'EasyOrder Test',

  // Directorio de salida del build de Vite
  webDir: 'dist',

  // Configuración del servidor WebView
  server: {
    // Si en el futuro deseas que la app cargue directamente tu backend/web en la nube
    // al iniciar (en lugar de empaquetar el frontend local), puedes descomentar la siguiente línea:
    // url: 'https://mi-dominio.com',
    androidScheme: 'https',
    iosScheme: 'https'
  },

  ios: {
    // Permite scroll fluido y soporte para gestos táctiles tipo iOS
    contentInset: 'always',
    preferredContentMode: 'mobile'
  }
};

export default config;
