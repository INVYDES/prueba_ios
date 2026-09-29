<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { Capacitor } from '@capacitor/core';
import { APP_CONFIG } from './config/appConfig';
import { Printer } from './plugins/printer';
import { generateEscPosComanda, DEMO_COMANDA } from './utils/escpos';

// Estado general
const platform = ref('Detectando...');
const isNativeApp = ref(false);
const targetUrl = ref(APP_CONFIG.targetWebUrl);

// Configuración persistente de la Impresora
const printerIp = ref('192.168.1.100');
const printerPort = ref(9100);
const printerName = ref('Impresora Cocina');

// Estado de operaciones de impresión
const statusMessage = ref<string | null>(null);
const statusType = ref<'info' | 'success' | 'error' | 'loading'>('info');
const isTestingConnection = ref(false);
const isPrinting = ref(false);

onMounted(() => {
  platform.value = Capacitor.getPlatform();
  isNativeApp.value = Capacitor.isNativePlatform();

  // Cargar configuración guardada previamente en el iPhone
  const savedIp = localStorage.getItem('easyorder_printer_ip');
  const savedPort = localStorage.getItem('easyorder_printer_port');
  const savedName = localStorage.getItem('easyorder_printer_name');

  if (savedIp) printerIp.value = savedIp;
  if (savedPort) printerPort.value = Number(savedPort);
  if (savedName) printerName.value = savedName;
});

// Guardar configuración en la memoria del iPhone
const guardarAjustes = () => {
  localStorage.setItem('easyorder_printer_ip', printerIp.value.trim());
  localStorage.setItem('easyorder_printer_port', String(printerPort.value));
  localStorage.setItem('easyorder_printer_name', printerName.value.trim());

  statusType.value = 'success';
  statusMessage.value = '✓ Ajustes de impresora guardados en el dispositivo.';
};

// Probar conexión TCP (Ping de socket)
const probarConexion = async () => {
  guardarAjustes();
  isTestingConnection.value = true;
  statusType.value = 'loading';
  statusMessage.value = `Conectando por TCP a ${printerIp.value}:${printerPort.value}...`;

  try {
    const res = await Printer.checkStatus({
      ip: printerIp.value.trim(),
      port: Number(printerPort.value),
      timeoutMs: 3500
    });

    if (res.connected) {
      statusType.value = 'success';
      statusMessage.value = `🟢 ONLINE: ${res.message}`;
    } else {
      statusType.value = 'error';
      statusMessage.value = `🔴 OFFLINE: ${res.message}`;
    }
  } catch (err: any) {
    statusType.value = 'error';
    statusMessage.value = `Error de socket: ${err?.message || err}`;
  } finally {
    isTestingConnection.value = false;
  }
};

// Enviar Comanda de Prueba ESC/POS
const imprimirComanda = async () => {
  guardarAjustes();
  isPrinting.value = true;
  statusType.value = 'loading';
  statusMessage.value = `Enviando comanda a ${printerIp.value}:${printerPort.value}...`;

  try {
    const comandaBytes = generateEscPosComanda(DEMO_COMANDA);

    const res = await Printer.print({
      ip: printerIp.value.trim(),
      port: Number(printerPort.value),
      data: comandaBytes,
      timeoutMs: 5000
    });

    statusType.value = 'success';
    statusMessage.value = `🧾 ${res.message}`;
  } catch (err: any) {
    statusType.value = 'error';
    statusMessage.value = `Error al imprimir: ${err?.message || err}`;
  } finally {
    isPrinting.value = false;
  }
};

// Navegación nativa al sistema POS
const abrirPosWeb = () => {
  window.location.href = targetUrl.value;
};
</script>

<template>
  <div class="app-container safe-area-top safe-area-bottom">
    <main class="content-card">
      <!-- Encabezado -->
      <header class="header-section">
        <div class="app-badge">
          <span class="badge-dot"></span>
          {{ platform.toUpperCase() }} {{ isNativeApp ? '(NATIVO)' : '(WEB)' }}
        </div>
        <h1 class="app-title">EasyOrder Test</h1>
        <p class="app-subtitle">Módulo de Impresión TCP & Contenedor POS</p>
      </header>

      <!-- SECCIÓN: CONFIGURACIÓN DE IMPRESORA -->
      <section class="printer-section">
        <div class="section-header">
          <div class="icon-wrap">🖨️</div>
          <div class="section-text">
            <h3>Configuración de Impresora</h3>
            <p>Define la IP local de tu impresora de comandas</p>
          </div>
        </div>

        <div class="form-grid">
          <div class="input-group full-width">
            <label for="printer-name">Nombre / Área:</label>
            <input
              id="printer-name"
              v-model="printerName"
              type="text"
              placeholder="Ej: Cocina, Barra, Caja"
              @change="guardarAjustes"
            />
          </div>

          <div class="input-group ip-group">
            <label for="printer-ip">Dirección IP:</label>
            <input
              id="printer-ip"
              v-model="printerIp"
              type="text"
              placeholder="192.168.1.100"
              @change="guardarAjustes"
            />
          </div>

          <div class="input-group port-group">
            <label for="printer-port">Puerto:</label>
            <input
              id="printer-port"
              v-model.number="printerPort"
              type="number"
              placeholder="9100"
              @change="guardarAjustes"
            />
          </div>
        </div>

        <!-- Botones de Acción de Impresora -->
        <div class="printer-actions">
          <button
            class="btn btn-secondary"
            :disabled="isTestingConnection || isPrinting"
            @click="probarConexion"
            id="btn-test-socket"
          >
            <span v-if="isTestingConnection">Conectando...</span>
            <span v-else>🔍 Probar Conexión (Ping)</span>
          </button>

          <button
            class="btn btn-print"
            :disabled="isTestingConnection || isPrinting"
            @click="imprimirComanda"
            id="btn-print-comanda"
          >
            <span v-if="isPrinting">Imprimiendo...</span>
            <span v-else>🧾 Imprimir Comanda de Prueba</span>
          </button>
        </div>

        <!-- Cuadro de Estado / Diagnóstico -->
        <div v-if="statusMessage" class="status-alert" :class="statusType">
          <p>{{ statusMessage }}</p>
        </div>
      </section>

      <!-- SECCIÓN: ACCESO AL SISTEMA POS WEB -->
      <section class="web-section">
        <button class="btn btn-primary" @click="abrirPosWeb" id="btn-open-web">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="2" y1="12" x2="22" y2="12"></line>
            <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
          </svg>
          ABRIR SISTEMA (eorder.mx)
        </button>
      </section>
    </main>

    <footer class="footer-note">
      EasyOrder iOS &bull; TCP/IP ESC/POS Thermal Printing Architecture
    </footer>
  </div>
</template>

<style scoped>
.app-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 18px;
  background: radial-gradient(circle at 50% 10%, #1e293b 0%, #0a0f1d 100%);
  overflow-y: auto;
}

.content-card {
  width: 100%;
  max-width: 440px;
  background: rgba(22, 30, 49, 0.85);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(148, 163, 184, 0.15);
  border-radius: 24px;
  padding: 24px 20px;
  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.45);
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Header */
.header-section {
  text-align: center;
}

.app-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.8px;
  padding: 4px 12px;
  background: rgba(37, 99, 235, 0.15);
  color: #60a5fa;
  border-radius: 20px;
  margin-bottom: 8px;
  border: 1px solid rgba(96, 165, 250, 0.25);
}

.badge-dot {
  width: 6px;
  height: 6px;
  background: #10b981;
  border-radius: 50%;
}

.app-title {
  font-size: 28px;
  font-weight: 800;
  color: #ffffff;
  letter-spacing: -0.5px;
}

.app-subtitle {
  font-size: 13px;
  color: #94a3b8;
  margin-top: 2px;
}

/* Sección de Impresora */
.printer-section {
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 18px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.icon-wrap {
  font-size: 24px;
}

.section-text h3 {
  font-size: 15px;
  font-weight: 700;
  color: #f8fafc;
}

.section-text p {
  font-size: 11px;
  color: #64748b;
}

/* Formulario */
.form-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 10px;
}

.full-width {
  grid-column: span 2;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.input-group label {
  font-size: 11px;
  font-weight: 600;
  color: #cbd5e1;
}

.input-group input {
  padding: 10px 12px;
  background: rgba(10, 15, 29, 0.8);
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 10px;
  color: #ffffff;
  font-size: 14px;
  outline: none;
  font-family: inherit;
}

.input-group input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

/* Botones de Impresora */
.printer-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 14px;
  border-radius: 12px;
  font-weight: 700;
  font-size: 14px;
  cursor: pointer;
  border: none;
  transition: all 0.2s;
}

.btn-secondary {
  background: rgba(59, 130, 246, 0.15);
  border: 1px solid rgba(59, 130, 246, 0.35);
  color: #93c5fd;
}

.btn-secondary:hover {
  background: rgba(59, 130, 246, 0.25);
}

.btn-print {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: #ffffff;
  box-shadow: 0 4px 14px rgba(16, 185, 129, 0.3);
}

.btn-print:hover {
  filter: brightness(1.1);
}

.btn-primary {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  color: #ffffff;
  box-shadow: 0 6px 20px rgba(37, 99, 235, 0.4);
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Avisos de estado */
.status-alert {
  padding: 10px 12px;
  border-radius: 10px;
  font-size: 12px;
  line-height: 1.4;
  word-break: break-word;
}

.status-alert.loading {
  background: rgba(59, 130, 246, 0.15);
  color: #93c5fd;
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.status-alert.success {
  background: rgba(16, 185, 129, 0.15);
  color: #6ee7b7;
  border: 1px solid rgba(16, 185, 129, 0.3);
}

.status-alert.error {
  background: rgba(239, 68, 68, 0.15);
  color: #fca5a5;
  border: 1px solid rgba(239, 68, 68, 0.3);
}

.footer-note {
  font-size: 11px;
  color: #475569;
  text-align: center;
  margin-top: 10px;
}
</style>
