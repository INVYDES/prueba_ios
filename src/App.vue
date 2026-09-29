<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { Capacitor } from '@capacitor/core';
import { APP_CONFIG } from './config/appConfig';
import { Printer } from './plugins/printer';

// Estado de la interfaz
const isWebViewActive = ref(false);
const targetUrl = ref(APP_CONFIG.targetWebUrl);
const platform = ref('Detectando...');
const isNativeApp = ref(false);
const iframeKey = ref(0);
const printerLog = ref<string | null>(null);

onMounted(() => {
  const currentPlatform = Capacitor.getPlatform();
  platform.value = currentPlatform;
  isNativeApp.value = Capacitor.isNativePlatform();
});

// Acción principal: Abrir Web dentro de la aplicación mediante WKWebView nativo
const abrirWeb = () => {
  // Al estar configurado 'allowNavigation' en capacitor.config.ts,
  // la navegación permanece 100% dentro de la app sin abrir Safari.
  window.location.href = targetUrl.value;
};

// Navegación directa alternativa
const abrirWebDirecta = () => {
  window.location.href = targetUrl.value;
};

// Demostración de la arquitectura de impresión Fase 2
const probarLlamadaPrinter = async () => {
  printerLog.value = 'Invocando Printer.print(...)';
  try {
    const res = await Printer.print({
      ip: '192.168.1.50',
      port: 9100,
      data: 'EasyOrder POS - Ticket de prueba #001'
    });
    printerLog.value = `Respuesta recibida:\n${res.message}`;
  } catch (err: any) {
    printerLog.value = `Error en llamada: ${err?.message || err}`;
  }
};
</script>

<template>
  <div class="app-container">
    <!-- ============================================================= -->
    <!-- MODO 1: CONTENEDOR WEBVIEW INTERNO (PANTALLA COMPLETA EN APP) -->
    <!-- ============================================================= -->
    <div v-if="isWebViewActive" class="webview-screen">
      <!-- Barra de navegación superior estilo iOS (Respeta Safe Area) -->
      <header class="webview-header safe-area-top">
        <button class="nav-btn back-btn" @click="cerrarWeb" id="btn-back">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="15 18 9 12 15 6"></polyline>
          </svg>
          Volver
        </button>

        <div class="url-badge" :title="targetUrl">
          <span class="lock-icon">🔒</span>
          <span class="url-text">{{ targetUrl }}</span>
        </div>

        <button class="nav-btn icon-btn" @click="recargarWeb" title="Recargar página" id="btn-reload">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M23 4v6h-6"></path>
            <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
          </svg>
        </button>
      </header>

      <!-- Iframe interno que actúa como WebView nativo dentro del contenedor -->
      <div class="iframe-wrapper">
        <iframe
          :key="iframeKey"
          :src="targetUrl"
          class="native-webview-frame"
          allow="geolocation; microphone; camera; display-capture"
          sandbox="allow-scripts allow-same-origin allow-forms allow-popups allow-modals"
        ></iframe>
      </div>
    </div>

    <!-- ============================================================= -->
    <!-- MODO 2: PANTALLA PRINCIPAL DE PRUEBA (EASYORDER TEST)        -->
    <!-- ============================================================= -->
    <div v-else class="main-screen safe-area-top safe-area-bottom">
      <main class="content-card">
        <!-- Encabezado solicitado -->
        <div class="header-section">
          <div class="app-badge">iOS WebView Container</div>
          <h1 class="app-title">{{ APP_CONFIG.appName }}</h1>
          <h2 class="app-subtitle">{{ APP_CONFIG.subTitle }}</h2>
        </div>

        <!-- Indicador de estado nativo -->
        <div class="status-box">
          <div class="status-row">
            <span class="status-label">Plataforma activa:</span>
            <span class="status-value highlight" id="platform-tag">
              {{ platform.toUpperCase() }} {{ isNativeApp ? '(Nativo iOS)' : '(Entorno Web)' }}
            </span>
          </div>
          <div class="status-row">
            <span class="status-label">Bundle ID:</span>
            <span class="status-value code">{{ APP_CONFIG.bundleId }}</span>
          </div>
          <div class="status-row">
            <span class="status-label">URL configurada:</span>
            <span class="status-value code url">{{ targetUrl }}</span>
          </div>
        </div>

        <!-- Selector / Input editable para probar URLs al vuelo -->
        <div class="url-input-container">
          <label for="url-input" class="input-label">URL a cargar en el WebView:</label>
          <input
            id="url-input"
            v-model="targetUrl"
            type="url"
            class="url-input"
            placeholder="https://example.com"
          />
          <small class="input-hint">
            Configurable de forma predeterminada en <code>src/config/appConfig.ts</code>
          </small>
        </div>

        <!-- Botón principal solicitado -->
        <div class="actions-section">
          <button
            class="primary-btn pulse-glow"
            @click="abrirWeb"
            id="btn-abrir-web"
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <circle cx="12" cy="12" r="10"></circle>
              <line x1="2" y1="12" x2="22" y2="12"></line>
              <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
            </svg>
            ABRIR WEB
          </button>

          <button
            class="secondary-btn"
            @click="abrirWebDirecta"
            title="Redirige la ventana completa de Capacitor a la URL remota"
          >
            Navegar con WKWebView directo (window.location)
          </button>
        </div>

        <!-- Preparación Fase 2: Impresora nativa -->
        <div class="phase2-box">
          <div class="phase2-title">
            <span>🖨️ Fase 2: Arquitectura EasyOrderPrinter</span>
          </div>
          <p class="phase2-desc">
            La interfaz de llamada nativa está lista en TypeScript.
            Puedes pulsar el botón para comprobar el puente sin ejecutar TCP aún.
          </p>
          <button class="test-printer-btn" @click="probarLlamadaPrinter">
            Probar llamada TypeScript: Printer.print(...)
          </button>
          <pre v-if="printerLog" class="printer-output">{{ printerLog }}</pre>
        </div>
      </main>

      <footer class="footer-info">
        <p>EasyOrder Test &bull; Capacitor iOS Proof of Concept</p>
      </footer>
    </div>
  </div>
</template>

<style scoped>
.app-container {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: radial-gradient(circle at 50% 10%, #1e293b 0%, #0f172a 100%);
}

/* Pantalla principal */
.main-screen {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
  overflow-y: auto;
}

.content-card {
  width: 100%;
  max-width: 440px;
  background: var(--bg-card);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid var(--bg-card-border);
  border-radius: 24px;
  padding: 28px 24px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
  display: flex;
  flex-direction: column;
  gap: 22px;
}

.header-section {
  text-align: center;
}

.app-badge {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  padding: 4px 12px;
  background: rgba(37, 99, 235, 0.2);
  color: #60a5fa;
  border-radius: 20px;
  margin-bottom: 12px;
  border: 1px solid rgba(96, 165, 250, 0.3);
}

.app-title {
  font-size: 32px;
  font-weight: 800;
  letter-spacing: -0.5px;
  color: #ffffff;
  margin-bottom: 6px;
}

.app-subtitle {
  font-size: 16px;
  font-weight: 400;
  color: var(--text-muted);
}

/* Caja de estado del sistema */
.status-box {
  background: rgba(15, 23, 42, 0.6);
  border-radius: 14px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.status-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
}

.status-label {
  color: var(--text-muted);
}

.status-value {
  font-weight: 600;
  color: var(--text-main);
}

.status-value.highlight {
  color: #38bdf8;
}

.status-value.code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 12px;
  background: rgba(255, 255, 255, 0.08);
  padding: 2px 6px;
  border-radius: 6px;
}

.status-value.url {
  max-width: 170px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Input para URL */
.url-input-container {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.input-label {
  font-size: 13px;
  font-weight: 600;
  color: #cbd5e1;
}

.url-input {
  width: 100%;
  padding: 12px 14px;
  background: rgba(15, 23, 42, 0.8);
  border: 1px solid rgba(148, 163, 184, 0.3);
  border-radius: 12px;
  color: #ffffff;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.url-input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.25);
}

.input-hint {
  font-size: 11px;
  color: #64748b;
}

.input-hint code {
  color: #93c5fd;
}

/* Botones de acción */
.actions-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.primary-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  width: 100%;
  padding: 16px;
  background: var(--accent-gradient);
  color: #ffffff;
  font-size: 17px;
  font-weight: 700;
  letter-spacing: 0.5px;
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(37, 99, 235, 0.4);
}

.primary-btn:hover {
  filter: brightness(1.1);
}

.secondary-btn {
  width: 100%;
  padding: 10px 14px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #cbd5e1;
  font-size: 12px;
  border-radius: 10px;
}

.secondary-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

/* Fase 2 - Impresión */
.phase2-box {
  background: rgba(30, 41, 59, 0.5);
  border: 1px dashed rgba(148, 163, 184, 0.25);
  border-radius: 14px;
  padding: 14px;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.phase2-title {
  font-weight: 700;
  color: #f1f5f9;
}

.phase2-desc {
  color: var(--text-muted);
  line-height: 1.4;
}

.test-printer-btn {
  padding: 8px 12px;
  background: rgba(59, 130, 246, 0.15);
  border: 1px solid rgba(59, 130, 246, 0.3);
  color: #93c5fd;
  border-radius: 8px;
  font-size: 11px;
  font-weight: 600;
}

.printer-output {
  background: #020617;
  padding: 8px;
  border-radius: 6px;
  font-family: monospace;
  font-size: 11px;
  color: #10b981;
  white-space: pre-wrap;
  word-break: break-all;
}

.footer-info {
  margin-top: 16px;
  font-size: 12px;
  color: #475569;
  text-align: center;
}

/* =========================================================================
   ESTILOS DEL MODO WEBVIEW INTERNO
   ========================================================================= */
.webview-screen {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: #000000;
}

.webview-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-left: 12px;
  padding-right: 12px;
  padding-bottom: 10px;
  background: rgba(15, 23, 42, 0.95);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.nav-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  background: rgba(255, 255, 255, 0.1);
  color: #ffffff;
  padding: 8px 14px;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
}

.nav-btn.icon-btn {
  padding: 8px;
}

.url-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  max-width: 50%;
  background: rgba(0, 0, 0, 0.3);
  padding: 6px 12px;
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.lock-icon {
  font-size: 11px;
}

.url-text {
  font-size: 12px;
  color: #e2e8f0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.iframe-wrapper {
  flex: 1;
  width: 100%;
  height: 100%;
  position: relative;
  background: #ffffff;
}

.native-webview-frame {
  width: 100%;
  height: 100%;
  border: none;
}
</style>
