# Prompt de Integración de Impresión Nativa para eOrder (Frontend)

Copia y pega este contenido en el chat de tu espacio de trabajo de **`EASY_ORDER_FRONT_MAIN-conexiones`**:

```markdown
Hola. Acabamos de desarrollar, compilar e instalar con éxito en un iPhone físico la aplicación nativa iOS para EasyOrder (basada en Capacitor 6) que funciona como contenedor de esta plataforma web (https://eorder.mx/).

En la aplicación iOS ya está compilado, enlazado y probado con éxito un plugin nativo en Swift llamado `EasyOrderPrinter` que se comunica directamente por sockets TCP (puerto 9100) con impresoras térmicas de comandas ESC/POS en la red local.

Necesito que integremos en este proyecto frontend de EasyOrder el servicio de impresión para que cuando el sistema esté corriendo dentro de la app iOS, dispare la impresión por socket TCP nativo en lugar del navegador.

REQUERIMIENTOS ESPECÍFICOS:

1. No instalar librerías de Capacitor con npm en este proyecto:
   La app de iOS ya inyecta automáticamente en tiempo de ejecución el objeto global `window.Capacitor` y su plugin `window.Capacitor.Plugins.EasyOrderPrinter`.

2. Crear un servicio reutilizable en `src/services/printerService.js` (o `.ts` según el proyecto) con:
   - Detección de entorno: saber si estamos en la app iOS nativa (`window.Capacitor?.isNativePlatform()`).
   - Función `imprimirComanda({ ip, port = 9100, data, timeoutMs = 5000 })` que invoque:
     `await window.Capacitor.Plugins.EasyOrderPrinter.print({ ip, port, data, timeoutMs })`
     y que tenga fallback a `window.print()` si estamos en PC normal.
   - Función `probarConexionImpresora(ip, port = 9100)` que invoque:
     `await window.Capacitor.Plugins.EasyOrderPrinter.checkStatus({ ip, port })`
   - Generador/Formateador de tickets en formato estándar ESC/POS (cabecera con nombre de sucursal, folio/comanda, mesa, mesero, detalle de platillos con cantidades y notas, total, y comando de corte de papel: \x1D\x56\x41\x03).

3. Configuración de IP:
   - Proveer soporte para que la IP de la impresora pueda configurarse dinámicamente (por ejemplo en localStorage o asociada a la sucursal actual) para no tener IPs fijas en el código.

4. Integración en vistas:
   - Indícame en qué componentes/vistas de comandas o cobro debemos importar este servicio para vincularlo al botón de "Mandar a Cocina" o "Imprimir Cuenta".

Por favor analiza la estructura actual de este proyecto y genera el servicio y la integración correspondiente.
```
