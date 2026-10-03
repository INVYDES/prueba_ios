# EasyOrder iOS Container (App Nativa eOrder POS)

Contenedor nativo iOS desarrollado con **Capacitor 6**, **Swift 5** y **Vue 3** para el sistema web **[EasyOrder POS](https://eorder.mx/)**.

---

## 📖 Documentación Completa

Para una explicación exhaustiva de la arquitectura, configuración, impresión térmica TCP y flujo de compilación, consulta el archivo maestro:
👉 **[DOCUMENTACION_PROYECTO_EASYORDER_IOS.md](./DOCUMENTACION_PROYECTO_EASYORDER_IOS.md)**

---

## 🎯 Puntos Clave del Proyecto

* **URL del Sistema:** [`https://eorder.mx/`](https://eorder.mx/) (cargado en WKWebView a pantalla completa).
* **Repositorio Remoto:** [`https://github.com/INVYDES/prueba_ios.git`](https://github.com/INVYDES/prueba_ios.git)
* **Impresión Térmica:** Plugin nativo en Swift (`EasyOrderPrinterPlugin`) con comunicación directa por sockets TCP (puerto 9100) vía `Network.framework` de Apple.
* **Integración Zero-Touch:** No requiere modificar el código de producción de Vue. El contenedor intercepta en tiempo de ejecución las llamadas a `window.open` y `window.print` para procesar tickets y documentos automáticamente.
* **Botón Flotante (`⚙️`):** Interfaz arrastrable para configurar la IP de la impresora térmica, hacer ping de prueba y mandar tickets demo.
* **Compilación en la Nube:** Flujo automatizado en GitHub Actions con runners oficiales `macos-14`, generando instaladores `.ipa` listos para instalar con Sideloadly desde Windows.

---

## 🛠️ Comandos Rápidos

```powershell
# Iniciar simulador de impresora térmica en PC (puerto 9100)
node tools/printer-simulator.js

# Compilar proyecto web y sincronizar con iOS
npm run build
npx cap sync ios

# Subir cambios para compilar nuevo .ipa en GitHub Actions
git add .
git commit -m "Actualización"
git push origin main
```
