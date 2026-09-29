/**
 * =========================================================================
 * SIMULADOR DE IMPRESORA TÉRMICA ESC/POS (TCP PORT 9100)
 * =========================================================================
 *
 * Ejecuta este script en tu PC para simular una impresora de comandas real:
 *   node tools/printer-simulator.js
 *
 * Tu PC escuchará en el puerto 9100 de tu red local Wi-Fi.
 * Cuando tu iPhone mande a imprimir, verás el ticket aparecer en vivo aquí.
 */

import net from 'net';
import os from 'os';

const PORT = 9100;

// Obtener todas las IPs locales de la PC
function getLocalIps() {
  const interfaces = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        ips.push({ name, address: iface.address });
      }
    }
  }
  return ips;
}

const localIps = getLocalIps();

const server = net.createServer((socket) => {
  const clientAddress = `${socket.remoteAddress}:${socket.remotePort}`;
  console.log(`\n\x1b[32m[✓] ¡Conexión TCP entrante desde iPhone!\x1b[0m (${clientAddress})`);

  let receivedData = Buffer.alloc(0);

  socket.on('data', (chunk) => {
    receivedData = Buffer.concat([receivedData, chunk]);
  });

  socket.on('end', () => {
    console.log(`\x1b[36m============================================================\x1b[0m`);
    console.log(`\x1b[1m\x1b[33m🧾 TICKET DE COMANDA RECIBIDO (${receivedData.length} bytes):\x1b[0m`);
    console.log(`\x1b[36m============================================================\x1b[0m`);

    // Limpiar secuencias binarias de control ESC/POS para visualización legible
    const textOutput = receivedData
      .toString('utf8')
      .replace(/\x1D\x56\x41\x03/g, '\n\x1b[35m[✂️ CORTAR PAPEL - GS V A 3]\x1b[0m\n')
      .replace(/[\x00-\x09\x0B-\x1F\x7F]/g, '');

    console.log(textOutput);
    console.log(`\x1b[36m============================================================\x1b[0m\n`);
  });

  socket.on('error', (err) => {
    console.error(`[!] Error en socket: ${err.message}`);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n\x1b[1m\x1b[32m============================================================\x1b[0m`);
  console.log(`\x1b[1m🖨️  SIMULADOR DE IMPRESORA TÉRMICA ESC/POS ACTIVO\x1b[0m`);
  console.log(`============================================================`);
  console.log(`📡 Tu PC está escuchando en el puerto: \x1b[33m${PORT}\x1b[0m`);
  console.log(`🌐 Direcciones IP detectadas en esta PC:`);
  for (const item of localIps) {
    console.log(`   * \x1b[32m\x1b[1m${item.address}\x1b[0m (${item.name})`);
  }
  console.log(`------------------------------------------------------------`);
  console.log(`👉 En tu iPhone, pon una de estas IPs y puerto \x1b[33m${PORT}\x1b[0m`);
  console.log(`   Luego pulsa "Imprimir Comanda de Prueba" en la app.`);
  console.log(`============================================================\n`);
});
