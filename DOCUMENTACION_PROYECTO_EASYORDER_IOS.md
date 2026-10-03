# 📘 Documentación Maestra del Proyecto: EasyOrder iOS Container

> **Nota para agentes de Antigravity / Desarrolladores:**
> Este documento contiene **todo el contexto técnico, arquitectónico y operativo** del proyecto. Al abrir este repositorio en cualquier equipo, este archivo te permitirá entender de inmediato qué hace el sistema, cómo está estructurado, a qué repositorios y URLs está conectado y cómo continuar el desarrollo sin perder el hilo.

---

## 📌 1. Ficha Técnica del Proyecto

* **Nombre de la App:** EasyOrder Test
* **Identificador de Paquete (Bundle ID):** `mx.easyorder.test`
* **Tipo de Proyecto:** Contenedor nativo iOS (Capacitor 6 + WKWebView + Vue 3 + Vite)
* **Plataforma Web Cargada:** [`https://eorder.mx/`](https://eorder.mx/) (Sistema Web POS EasyOrder)
* **Repositorio Remoto (GitHub):** [`https://github.com/INVYDES/prueba_ios.git`](https://github.com/INVYDES/prueba_ios.git)
* **Rama Principal:** `main`
* **Sistema de Compilación (CI/CD):** GitHub Actions con máquinas virtuales oficiales de Apple (`macos-14` / Xcode)
* **Método de Instalación en iPhone:** Sideloadly en Windows usando Apple ID gratuito (firma e instalación vía USB)
* **Lenguajes:** Swift 5, Objective-C (runtime bridge), TypeScript, JavaScript, Vue 3

---

## 🎯 2. Propósito y Finalidad del Proyecto

El sistema **EasyOrder POS** opera en la web bajo la URL `https://eorder.mx/`. Cuando se intentaba utilizar en un iPhone a través de Safari, surgían tres problemas críticos para un restaurante o punto de venta:

1. **Problemas de interfaz móvil:** Safari muestra barras de navegación superior e inferior y no retiene una experiencia de pantalla completa de app nativa.
2. **Imposibilidad de imprimir comandas térmicas por red:** Los navegadores web móviles por motivos de seguridad no pueden abrir sockets TCP directos (puerto 9100) para comunicarse con impresoras térmicas de cocina o caja (ESC/POS).
3. **Bloqueo de tickets emergentes:** En el sistema web de escritorio, los tickets se imprimen abriendo una ventana emergente (`window.open('', '_blank')`) y llamando a `win.print()`. En iOS esto es bloqueado o mal interpretado por el navegador.

### 💡 Solución Implementada:
Se construyó este contenedor nativo en Capacitor 6 que:
* Carga `https://eorder.mx/` directamente a pantalla completa con soporte de Safe Area (Dynamic Island y Notch de iPhone).
* Implementa un plugin nativo en Swift (`EasyOrderPrinterPlugin`) que abre sockets TCP directos usando la librería oficial `Network.framework` de Apple hacia cualquier impresora térmica en la red Wi-Fi/Ethernet.
* **Cero cambios requeridos en el repositorio web de producción:** El contenedor intercepta automáticamente las llamadas a `window.open` y `window.print` en tiempo de ejecución, transformando los tickets HTML en comandos binarios ESC/POS con corte de papel automático.
* Proporciona un **botón flotante táctil y arrastrable (`⚙️`)** en la pantalla del iPhone para configurar la IP de la impresora térmica en cualquier momento y probar la conexión en vivo.

---

## 🏗️ 3. Arquitectura y Componentes del Código

```text
easyorder-test/
├── .github/
│   └── workflows/
│       └── build-ios.yml         # Flujo CI/CD en GitHub Actions (compila xcodebuild en macOS y genera .ipa)
├── capacitor.config.ts           # Configuración de Capacitor apuntando a eorder.mx y dominios permitidos
├── tools/
│   └── printer-simulator.js      # Servidor TCP local en Node.js que simula una impresora térmica ESC/POS
├── src/                          # Código fuente Vue/Vite del contenedor
│   ├── config/appConfig.ts       # URL objetivo configurada (https://eorder.mx/)
│   ├── plugins/printer/          # Definiciones TypeScript del plugin EasyOrderPrinter
│   └── App.vue                   # Interfaz de diagnóstico local
├── ios/                          # Proyecto nativo de Xcode (App.xcworkspace)
│   └── App/
│       └── App/
│           ├── EasyOrderPrinterPlugin.swift   # Implementación nativa de sockets TCP y AirPrint
│           ├── EasyOrderPrinterPlugin.m       # Registro de métodos en el puente de Capacitor
│           ├── ViewController.swift           # Controlador principal e inyección del script interceptor
│           └── project.pbxproj                # Configuración de compilación de Xcode
└── DOCUMENTACION_PROYECTO_EASYORDER_IOS.md   # Este documento
```

---

## 🔌 4. Detalle de los Módulos Principales

### A. Plugin Nativo Swift (`EasyOrderPrinterPlugin.swift` & `.m`)
Ubicación: `ios/App/App/EasyOrderPrinterPlugin.swift`
* **Tecnología:** `Network.framework` (`NWConnection` de Apple) para máxima estabilidad y compatibilidad con iOS 16, 17 y 18.
* **Métodos expuestos a JavaScript:**
  1. `checkStatus({ ip, port, timeoutMs })`: Realiza un ping por socket TCP para verificar si la impresora está encendida y accesible en la red local. Devuelve `ONLINE`, `OFFLINE` o `TIMEOUT`.
  2. `print({ ip, port, data, timeoutMs })`: Envía paquetes de bytes ESC/POS (soporta texto plano UTF-8 o codificado en Base64). Gestiona el buffer y cierra la conexión de forma segura.
  3. `printCurrentPage()`: Invoca el diálogo oficial de **Apple AirPrint** (`UIPrintInteractionController`) para documentos estándar (PDF / hojas de compras).
  4. `getSettings()` / `setSettings({ ip, port })`: Lee y guarda la IP y puerto de la impresora directamente en la memoria persistente del dispositivo (`UserDefaults.standard`).

### B. Controlador y Script Interceptor (`ViewController.swift`)
Ubicación: `ios/App/App/ViewController.swift`
Subclase de `CAPBridgeViewController` que inyecta en `eorder.mx` un script en tiempo de ejecución:
1. **Botón Flotante (`⚙️`):**
   * Elemento circular con diseño frosted glass (`z-index: 9999999`).
   * Soporta arrastre táctil en iPhone: el usuario puede moverlo a cualquier borde para que no tape botones del punto de venta.
   * Punto de estado: Verde si hay una IP configurada, Naranja si no se ha configurado.
2. **Modal de Configuración:**
   * Permite ingresar la IP de la impresora y el puerto (por defecto `9100`).
   * Botón **🔍 Probar Ping**: Verifica la conexión en tiempo real.
   * Botón **🧾 Ticket Demo**: Envía una comanda de prueba con corte de papel.
   * Botón **💾 Guardar**: Persiste la configuración tanto en `localStorage` como en `UserDefaults` nativo.
3. **Interceptor de Tickets (`window.open`):**
   * Cuando Vue ejecuta `win = window.open('', '_blank')`, el contenedor devuelve un objeto simulado.
   * Al ejecutarse `win.document.write(html)`, se captura todo el HTML del ticket.
   * Al ejecutarse `win.print()`, se activa el parser `htmlToEscPos()` que convierte tablas, negritas, alineaciones y totales en comandos ESC/POS y los dispara a la IP configurada junto con el comando de corte `\x1D\x56\x42\x00`.
4. **Interceptor de Documentos (`window.print`):**
   * Si se llama `window.print()` en la pantalla principal (como el botón de "Lista de compras"), se activa automáticamente **AirPrint**.

### C. Simulador Local de Impresora (`tools/printer-simulator.js`)
Ubicación: `tools/printer-simulator.js`
* Permite probar la app sin necesidad de una impresora física.
* Se ejecuta en la computadora con:
  ```bash
  node tools/printer-simulator.js
  ```
* Escucha conexiones TCP en el puerto 9100.
* Muestra en la consola de la PC las comandas y tickets recibidos desde el iPhone en tiempo real, interpretando cortes de papel y formateo.

---

## ☁️ 5. Flujo de Compilación e Instalación (Sin Mac)

Dado que el desarrollo se realiza en Windows, no se requiere una máquina Mac local. El flujo es:

```text
Tu PC (Windows)
      │
      ▼ (git push origin main)
Repositorio GitHub (https://github.com/INVYDES/prueba_ios.git)
      │
      ▼ (GitHub Actions Workflow: build-ios.yml)
Máquina Virtual macOS-14 (Apple Silicon M-Series en la nube)
  ├── Instala Node.js, dependencias y Capacitor
  ├── Ejecuta xcodebuild y compila la app nativa en Swift
  └── Empaqueta el instalador: EasyOrderTest-Unsigned.ipa (Tiempo: ~2-3 min)
      │
      ▼ (Descarga manual del artefacto en GitHub Actions)
Tu PC (Windows)
      │
      ▼ (Arrastrar el .ipa a Sideloadly conectado por USB al iPhone)
iPhone Físico con EasyOrder funcionando al 100%
```

---

## 🖨️ 6. Contexto Importante sobre Impresoras Compatibles

1. **Impresoras Térmicas de Tickets / Comandas (Epson, Xprinter, Bixolon, Star Micronics, etc.):**
   * **Compatibilidad:** 100% directa y nativa por Wi-Fi o Ethernet (cable de red).
   * **Protocolo:** ESC/POS sobre socket TCP en el puerto estándar `9100`.
   * **Estado:** Totalmente probado y verificado (la app envía comandas binarias con corte automático).

2. **Impresoras de Inyección de Tinta de Oficina (Ejemplo: Canon PIXMA G3010 series):**
   * **Limitación de fábrica:** Canon no incluyó la licencia de Apple AirPrint en la serie G3010 (la reservó para modelos superiores como la G3020/G4010). Tampoco aceptan texto plano por el puerto 9100 (requieren el protocolo gráfico propietario Canon BJNP en el puerto 8611).
   * **Solución 1:** En la PC (que ya tiene el driver de Canon instalado), usar un puente gratuito como *AirPrint Server / O'Print* para compartir la Canon como AirPrint hacia el iPhone.
   * **Solución 2:** Usar la app oficial gratuita *Canon PRINT Inkjet/SELPHY* en el iPhone recibiendo el documento desde la app mediante la Hoja de Compartir de iOS.

---

## 🚀 7. Comandos Frecuentes para el Desarrollador

* **Iniciar el simulador de impresora térmica en PC:**
  ```powershell
  cd C:\Users\mtait\.gemini\antigravity-ide\scratch\easyorder-test
  node tools/printer-simulator.js
  ```
* **Compilar y sincronizar cambios web hacia iOS:**
  ```powershell
  npm run build
  npx cap sync ios
  ```
* **Subir cambios a GitHub para generar un nuevo instalador `.ipa`:**
  ```powershell
  git add .
  git commit -m "Descripción de los cambios"
  git push origin main
  ```
* **Ver el estado de las compilaciones en la nube:**
  [https://github.com/INVYDES/prueba_ios/actions](https://github.com/INVYDES/prueba_ios/actions)

---

## 📋 8. Resumen del Estado Actual del Proyecto

| Funcionalidad | Estado | Comentarios |
| :--- | :---: | :--- |
| **Carga de eorder.mx** | ✅ Operativo | Carga directa en WKWebView a pantalla completa. |
| **Plugin Socket TCP (9100)** | ✅ Operativo | Probado exitosamente enviando comandas ESC/POS. |
| **Simulador de Impresora PC** | ✅ Operativo | Script en Node.js listo para pruebas de red local. |
| **Botón de Ajustes Flotante** | ✅ Operativo | Arrastrable, con ping de socket, prueba y guardado de IP. |
| **Intercepción de Tickets** | ✅ Operativo | Captura `window.open` y convierte HTML a ESC/POS. |
| **Soporte AirPrint Documentos** | ✅ Operativo | Intercepta `window.print` en la pantalla principal. |
| **Cloud Build en GitHub** | ✅ Operativo | Compilación automática de `.ipa` en macOS runners. |
