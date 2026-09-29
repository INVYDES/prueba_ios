/**
 * =========================================================================
 * GENERADOR DE COMANDAS Y TICKETS ESC/POS PARA IMPRESORAS TÉRMICAS
 * =========================================================================
 */

export interface ComandaItem {
  name: string;
  qty: number;
  price: number;
  notes?: string;
}

export interface ComandaData {
  orderNumber: string | number;
  table: string;
  waiter: string;
  date: string;
  items: ComandaItem[];
  total: number;
}

export function generateEscPosComanda(comanda: ComandaData): string {
  // Comandos estándar ESC/POS
  const ESC = '\x1B';
  const GS = '\x1D';

  const INIT = ESC + '@';                       // Reiniciar / Limpiar buffer
  const ALIGN_CENTER = ESC + 'a' + '\x01';      // Centrar texto
  const ALIGN_LEFT = ESC + 'a' + '\x00';        // Alinear izquierda
  const ALIGN_RIGHT = ESC + 'a' + '\x02';       // Alinear derecha
  const BOLD_ON = ESC + 'E' + '\x01';           // Negrita ON
  const BOLD_OFF = ESC + 'E' + '\x00';          // Negrita OFF
  const DOUBLE_HEIGHT = ESC + '!' + '\x10';     // Texto doble altura
  const NORMAL_FONT = ESC + '!' + '\x00';       // Fuente normal
  const CUT_PAPER = GS + 'V' + '\x41' + '\x03'; // Alimentar papel y corte completo

  let buffer = '';

  // 1. Cabecera
  buffer += INIT;
  buffer += ALIGN_CENTER + BOLD_ON + DOUBLE_HEIGHT + 'EASYORDER POS\n' + NORMAL_FONT;
  buffer += '*** COMANDA DE COCINA ***\n';
  buffer += `Orden: #${comanda.orderNumber}  |  Mesa: ${comanda.table}\n`;
  buffer += `Mesero: ${comanda.waiter}\n`;
  buffer += `Fecha: ${comanda.date}\n`;
  buffer += '------------------------------------------------\n';

  // 2. Detalle de artículos
  buffer += ALIGN_LEFT;
  for (const item of comanda.items) {
    const qtyStr = `${item.qty}x `.padEnd(4, ' ');
    const priceStr = `$${(item.qty * item.price).toFixed(2)}`;
    const nameMaxLen = 48 - qtyStr.length - priceStr.length;
    const nameTrunc = item.name.padEnd(nameMaxLen, '.');

    buffer += BOLD_ON + qtyStr + BOLD_OFF + nameTrunc + priceStr + '\n';
    if (item.notes) {
      buffer += `   * NOTA: ${item.notes}\n`;
    }
  }

  // 3. Totales
  buffer += '------------------------------------------------\n';
  buffer += ALIGN_RIGHT + BOLD_ON + DOUBLE_HEIGHT;
  buffer += `TOTAL: $${comanda.total.toFixed(2)} MXN\n` + NORMAL_FONT + BOLD_OFF;
  buffer += ALIGN_CENTER + '\n¡Enviar con prioridad a Cocina!\n\n\n\n';

  // 4. Corte de papel
  buffer += CUT_PAPER;

  return buffer;
}

export const DEMO_COMANDA: ComandaData = {
  orderNumber: '42',
  table: 'Mesa 4 (Terraza)',
  waiter: 'Carlos M.',
  date: new Date().toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
  items: [
    { name: 'Tacos de Arrachera (3 pzas)', qty: 2, price: 90.00, notes: 'Bien dorada la carne' },
    { name: 'Gringa de Pastor con Queso', qty: 1, price: 85.00, notes: 'Sin cebolla' },
    { name: 'Guacamole Tradicional', qty: 1, price: 65.00 },
    { name: 'Coca-Cola Regular (Lata)', qty: 2, price: 35.00, notes: 'Con hielo y limón' }
  ],
  total: 395.00
};
