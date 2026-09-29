# EasyOrder Test (iOS Capacitor Proof of Concept)

Prueba de concepto de contenedor nativo iOS (WebView) para el sistema **EasyOrder POS**, desarrollada con **Vue 3 + Vite** y **Capacitor 6**.

---

## 🎯 Objetivo de la Prueba

1. Validar la compilación, firma e instalación de una aplicación iOS nativa en un **iPhone físico**.
2. Comprobar el funcionamiento de un **WebView interno** que cargue una URL externa sin abrir la aplicación Safari.
3. Dejar sentada la arquitectura para la **Fase 2 (Impresión Térmica ESC/POS vía TCP/IP)** mediante un plugin nativo (`EasyOrderPrinter`).

---

## 📁 Estructura del Proyecto

```text
easyorder-test/
├── capacitor.config.ts           # Configuración de Capacitor (appId: mx.easyorder.test, appName: EasyOrder Test)
├── package.json                  # Dependencias y scripts
├── vite.config.ts                # Configuración del bundler Vite
├── index.html                    # Viewport configurado con viewport-fit=cover para Dynamic Island/Notch
├── src/
│   ├── config/
│   │   └── appConfig.ts          # URL OBJETIVO CONFIGURABLE (https://example.com -> https://mi-dominio.com)
│   ├── plugins/
│   │   └── printer/              # FASE 2: Definiciones TypeScript y bridge para EasyOrderPrinter
│   │       ├── definitions.ts    # Interfaces: PrintOptions, PrintResult, PrinterStatusResult
│   │       └── index.ts          # Registro de plugin nativo y Mock Web
│   ├── App.vue                   # Interfaz de usuario con botón "ABRIR WEB" y contenedor WebView interno
│   ├── style.css                 # Estilos iOS Safe-Area y paleta visual premium
│   └── main.ts                   # Montaje de la app Vue
├── native-templates/             # Plantillas nativas para la Fase 2 (Swift y Objective-C)
│   └── ios/
│       ├── EasyOrderPrinterPlugin.swift
│       └── EasyOrderPrinterPlugin.m
└── ios/                          # Proyecto Xcode nativo generado por Capacitor (App.xcworkspace)
```

---

## 🛠️ Comandos Disponibles

- `npm run dev`: Inicia el servidor de desarrollo local de Vite en el puerto 3000.
- `npm run build`: Genera los archivos estáticos optimizados en la carpeta `dist/`.
- `npx cap add ios`: Genera la carpeta nativa `ios/` con el proyecto de Xcode.
- `npm run cap:sync`: Compila Vue y sincroniza los cambios con la carpeta `ios/`.
- `npx cap open ios`: Abre el workspace en Xcode (requiere macOS).
