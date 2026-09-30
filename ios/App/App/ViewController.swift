import UIKit
import Capacitor
import WebKit

/**
 * Controlador de vista principal de la aplicación.
 * Subclase de CAPBridgeViewController para registrar plugins nativos locales en Capacitor 6,
 * interceptar window.print() para AirPrint, interceptar window.open() para tickets térmicos ESC/POS
 * y proveer un botón flotante de configuración de IP para impresoras de red.
 */
class ViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        super.capacitorDidLoad()
        
        // Registra la instancia del plugin nativo EasyOrderPrinter en el puente de Capacitor
        bridge?.registerPluginInstance(EasyOrderPrinterPlugin())
        
        // Inyecta el interceptor de impresión y el botón flotante de ajustes en eorder.mx
        let bridgeScript = #"""
        (function() {
            if (window.__easyOrderBridgeInitialized) return;
            window.__easyOrderBridgeInitialized = true;

            // ==========================================
            // 1. GESTOR DE CONFIGURACIÓN DE IMPRESORA
            // ==========================================
            async function getPrinterConfig() {
                let ip = localStorage.getItem('easyorder_printer_ip') || '';
                let port = parseInt(localStorage.getItem('easyorder_printer_port') || '9100', 10);

                if (!ip && window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.EasyOrderPrinter) {
                    try {
                        const native = await window.Capacitor.Plugins.EasyOrderPrinter.getSettings();
                        if (native && native.ip) {
                            ip = native.ip;
                            port = native.port || 9100;
                            localStorage.setItem('easyorder_printer_ip', ip);
                            localStorage.setItem('easyorder_printer_port', port);
                        }
                    } catch (e) {}
                }
                return { ip: ip.trim(), port: port || 9100 };
            }

            async function savePrinterConfig(ip, port) {
                localStorage.setItem('easyorder_printer_ip', ip.trim());
                localStorage.setItem('easyorder_printer_port', String(port || 9100));

                if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.EasyOrderPrinter) {
                    try {
                        await window.Capacitor.Plugins.EasyOrderPrinter.setSettings({ ip: ip.trim(), port: Number(port || 9100) });
                    } catch (e) {}
                }
                updateBadgeStatus();
            }

            // ==========================================
            // 2. SISTEMA DE TOAST / AVISOS FLOTANTES
            // ==========================================
            function showToast(message, type, duration) {
                type = type || 'info';
                duration = duration || 3500;
                let toast = document.getElementById('eo-toast');
                if (!toast) {
                    toast = document.createElement('div');
                    toast.id = 'eo-toast';
                    toast.style.cssText = 'position:fixed;top:24px;left:50%;transform:translateX(-50%);padding:12px 20px;border-radius:12px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;font-size:14px;font-weight:600;color:#ffffff;z-index:10000000;box-shadow:0 10px 25px rgba(0,0,0,0.5);transition:opacity 0.3s ease,transform 0.3s ease;display:flex;align-items:center;gap:10px;max-width:90vw;text-align:center;pointer-events:none;';
                    document.body.appendChild(toast);
                }

                let bg = 'rgba(30, 41, 59, 0.95)';
                let border = '1px solid rgba(148, 163, 184, 0.3)';
                if (type === 'success') {
                    bg = 'rgba(16, 185, 129, 0.95)';
                    border = '1px solid rgba(5, 150, 105, 0.5)';
                } else if (type === 'error') {
                    bg = 'rgba(239, 68, 68, 0.95)';
                    border = '1px solid rgba(220, 38, 38, 0.5)';
                } else if (type === 'warning') {
                    bg = 'rgba(245, 158, 11, 0.95)';
                    border = '1px solid rgba(217, 119, 6, 0.5)';
                }

                toast.style.background = bg;
                toast.style.border = border;
                toast.innerHTML = message;
                toast.style.opacity = '1';
                toast.style.transform = 'translateX(-50%) translateY(0)';

                if (toast.timer) clearTimeout(toast.timer);
                toast.timer = setTimeout(() => {
                    toast.style.opacity = '0';
                    toast.style.transform = 'translateX(-50%) translateY(-10px)';
                }, duration);
            }

            // ==========================================
            // 3. PARSER HTML -> COMANDOS ESC/POS TÉRMICOS
            // ==========================================
            function htmlToEscPos(html) {
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');

                const ESC = '\x1B';
                const GS = '\x1D';
                const INIT = ESC + '@';
                const CODE_PAGE = ESC + 't\x00';
                const ALIGN_LEFT = ESC + 'a\x00';
                const ALIGN_CENTER = ESC + 'a\x01';
                const ALIGN_RIGHT = ESC + 'a\x02';
                const BOLD_ON = ESC + 'E\x01';
                const BOLD_OFF = ESC + 'E\x00';
                const CUT_PAPER = GS + 'V\x42\x00';
                const OPEN_DRAWER = ESC + 'p\x00\x19\xFA';

                let buffer = INIT + CODE_PAGE + ALIGN_CENTER;
                const LINE_WIDTH = 40;

                function processNode(node) {
                    if (!node) return;

                    if (node.nodeType === Node.TEXT_NODE) {
                        const text = node.textContent.trim();
                        if (text) {
                            buffer += text + ' ';
                        }
                        return;
                    }

                    if (node.nodeType !== Node.ELEMENT_NODE) return;

                    const tag = node.tagName.toLowerCase();
                    if (tag === 'script' || tag === 'style' || tag === 'svg') return;

                    if (tag === 'br') {
                        buffer += '\n';
                        return;
                    }

                    if (tag === 'hr') {
                        buffer += '\n' + '-'.repeat(LINE_WIDTH) + '\n';
                        return;
                    }

                    if (tag === 'h1' || tag === 'h2' || tag === 'h3') {
                        buffer += '\n' + ALIGN_CENTER + BOLD_ON;
                        buffer += node.textContent.trim();
                        buffer += BOLD_OFF + '\n' + ALIGN_LEFT;
                        return;
                    }

                    if (tag === 'table') {
                        buffer += ALIGN_LEFT;
                        const rows = node.querySelectorAll('tr');
                        rows.forEach(tr => {
                            const cells = Array.from(tr.querySelectorAll('th, td')).map(c => c.textContent.trim().replace(/\s+/g, ' '));
                            if (cells.length === 0) return;

                            if (cells.length === 1) {
                                buffer += cells[0] + '\n';
                            } else if (cells.length === 2) {
                                const left = cells[0];
                                const right = cells[1];
                                const spaces = Math.max(1, LINE_WIDTH - left.length - right.length);
                                buffer += left + ' '.repeat(spaces) + right + '\n';
                            } else if (cells.length === 3) {
                                const col1 = cells[0].slice(0, 4).padEnd(4, ' ');
                                const col3 = cells[2].slice(0, 9).padStart(9, ' ');
                                const maxCol2 = LINE_WIDTH - 4 - 9 - 2;
                                const col2 = cells[1].slice(0, maxCol2).padEnd(maxCol2, ' ');
                                buffer += col1 + ' ' + col2 + ' ' + col3 + '\n';
                            } else {
                                buffer += cells.join('  ') + '\n';
                            }
                        });
                        buffer += '\n';
                        return;
                    }

                    const isBlock = ['div', 'p', 'section', 'header', 'footer'].includes(tag);
                    const style = node.getAttribute('style') || '';
                    const className = node.className || '';
                    const isCentered = style.includes('center') || className.includes('center');

                    if (isCentered) buffer += ALIGN_CENTER;
                    if (tag === 'b' || tag === 'strong') buffer += BOLD_ON;

                    node.childNodes.forEach(child => processNode(child));

                    if (tag === 'b' || tag === 'strong') buffer += BOLD_OFF;
                    if (isCentered) buffer += ALIGN_LEFT;
                    if (isBlock) buffer += '\n';
                }

                const body = doc.body || doc;
                processNode(body);

                let cleanText = buffer.replace(/\n{3,}/g, '\n\n');
                cleanText += '\n\n\n\n' + CUT_PAPER + OPEN_DRAWER;

                const bytes = new Uint8Array(cleanText.length);
                for (let i = 0; i < cleanText.length; i++) {
                    bytes[i] = cleanText.charCodeAt(i) & 0xff;
                }

                let binary = '';
                const len = bytes.byteLength;
                for (let i = 0; i < len; i++) {
                    binary += String.fromCharCode(bytes[i]);
                }
                return window.btoa(binary);
            }

            // ==========================================
            // 4. ENVÍO DEL TICKET A LA IMPRESORA TÉRMICA
            // ==========================================
            async function printTicketFromHtml(ticketHtml) {
                const config = await getPrinterConfig();

                if (!config.ip) {
                    showToast('⚠️ Ingresa la IP de tu impresora en el botón ⚙️', 'warning', 4500);
                    openSettingsModal();
                    return;
                }

                showToast('🖨️ Imprimiendo ticket en ' + config.ip + '...', 'info', 2500);

                try {
                    const base64Data = htmlToEscPos(ticketHtml);

                    if (!window.Capacitor?.Plugins?.EasyOrderPrinter) {
                        throw new Error('Plugin EasyOrderPrinter no disponible.');
                    }

                    const res = await window.Capacitor.Plugins.EasyOrderPrinter.print({
                        ip: config.ip,
                        port: config.port,
                        data: base64Data,
                        timeoutMs: 5000
                    });

                    showToast('✓ Ticket impreso (' + (res.bytesWritten || 'OK') + ' bytes)', 'success', 3000);
                } catch (err) {
                    console.error('Error al imprimir ticket:', err);
                    showToast('❌ Error al imprimir en ' + config.ip + ': ' + (err.message || err), 'error', 5000);
                }
            }

            // ==========================================
            // 5. INTERCEPTOR DE WINDOW.OPEN (TICKETS DE VUE)
            // ==========================================
            const originalWindowOpen = window.open;
            window.open = function(url, target, features) {
                const isBlankPopup = !url || url === '' || url === 'about:blank' || (typeof url === 'string' && url.trim() === '');

                if (isBlankPopup) {
                    let capturedHtml = '';
                    const mockWindow = {
                        document: {
                            open: function() {},
                            write: function(content) {
                                capturedHtml += content;
                            },
                            writeln: function(content) {
                                capturedHtml += content + '\n';
                            },
                            close: function() {},
                            focus: function() {},
                            get body() {
                                const div = document.createElement('div');
                                div.innerHTML = capturedHtml;
                                return div;
                            }
                        },
                        focus: function() {},
                        close: function() {},
                        print: function() {
                            printTicketFromHtml(capturedHtml);
                        }
                    };
                    return mockWindow;
                }

                return originalWindowOpen.apply(this, arguments);
            };

            // ==========================================
            // 6. INTERCEPTOR DE WINDOW.PRINT (AIRPRINT LISTA COMPRAS)
            // ==========================================
            const originalWindowPrint = window.print;
            window.print = function() {
                if (window.Capacitor?.Plugins?.EasyOrderPrinter?.printCurrentPage) {
                    window.Capacitor.Plugins.EasyOrderPrinter.printCurrentPage();
                } else if (originalWindowPrint) {
                    originalWindowPrint.apply(this, arguments);
                }
            };

            // ==========================================
            // 7. BOTÓN FLOTANTE Y MODAL DE CONFIGURACIÓN
            // ==========================================
            function initUI() {
                if (document.getElementById('eo-printer-btn')) return;

                const btn = document.createElement('div');
                btn.id = 'eo-printer-btn';
                btn.innerHTML = '<span>⚙️</span><div id="eo-badge-dot"></div>';
                btn.style.cssText = 'position:fixed;bottom:24px;left:20px;width:50px;height:50px;border-radius:50%;background:rgba(15,23,42,0.88);border:2px solid #3b82f6;box-shadow:0 8px 24px rgba(0,0,0,0.45);backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);z-index:9999999;display:flex;align-items:center;justify-content:center;font-size:24px;cursor:pointer;user-select:none;touch-action:none;transition:transform 0.15s ease;';

                const badge = btn.querySelector('#eo-badge-dot');
                badge.style.cssText = 'position:absolute;top:2px;right:2px;width:12px;height:12px;border-radius:50%;background:#f59e0b;border:2px solid #0f172a;';

                document.body.appendChild(btn);

                let isDragging = false;
                let startX = 0, startY = 0;
                let initialLeft = 20, initialTop = window.innerHeight - 74;

                btn.addEventListener('touchstart', (e) => {
                    const touch = e.touches[0];
                    startX = touch.clientX;
                    startY = touch.clientY;
                    const rect = btn.getBoundingClientRect();
                    initialLeft = rect.left;
                    initialTop = rect.top;
                    isDragging = false;
                    btn.style.transform = 'scale(0.92)';
                }, { passive: true });

                btn.addEventListener('touchmove', (e) => {
                    const touch = e.touches[0];
                    const dx = touch.clientX - startX;
                    const dy = touch.clientY - startY;

                    if (Math.abs(dx) > 6 || Math.abs(dy) > 6) {
                        isDragging = true;
                    }

                    if (isDragging) {
                        let newX = initialLeft + dx;
                        let newY = initialTop + dy;
                        newX = Math.max(10, Math.min(window.innerWidth - 60, newX));
                        newY = Math.max(20, Math.min(window.innerHeight - 70, newY));

                        btn.style.left = newX + 'px';
                        btn.style.top = newY + 'px';
                        btn.style.bottom = 'auto';
                    }
                }, { passive: true });

                btn.addEventListener('touchend', () => {
                    btn.style.transform = 'scale(1)';
                    if (!isDragging) {
                        openSettingsModal();
                    }
                });

                btn.addEventListener('click', () => {
                    if (!isDragging) openSettingsModal();
                });

                createModalHTML();
                updateBadgeStatus();
            }

            async function updateBadgeStatus() {
                const config = await getPrinterConfig();
                const dot = document.getElementById('eo-badge-dot');
                if (dot) {
                    dot.style.background = config.ip ? '#10b981' : '#f59e0b';
                }
            }

            function createModalHTML() {
                if (document.getElementById('eo-settings-modal')) return;

                const overlay = document.createElement('div');
                overlay.id = 'eo-settings-modal';
                overlay.style.cssText = 'position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(0,0,0,0.7);backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);z-index:10000000;display:none;align-items:center;justify-content:center;padding:16px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;box-sizing:border-box;';

                overlay.innerHTML = `
                    <div style="background:#0f172a;border:1px solid rgba(148,163,184,0.25);border-radius:20px;width:100%;max-width:360px;padding:22px 20px;box-shadow:0 20px 40px rgba(0,0,0,0.6);color:#ffffff;display:flex;flex-direction:column;gap:16px;position:relative;">
                        <div style="display:flex;justify-content:space-between;align-items:center;">
                            <div style="display:flex;align-items:center;gap:8px;">
                                <span style="font-size:20px;">🖨️</span>
                                <h3 style="margin:0;font-size:17px;font-weight:700;color:#f8fafc;">Impresora Térmica</h3>
                            </div>
                            <button id="eo-modal-close" style="background:rgba(255,255,255,0.1);border:none;color:#94a3b8;width:30px;height:30px;border-radius:50%;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;">✕</button>
                        </div>
                        <p style="margin:0;font-size:12px;color:#94a3b8;line-height:1.4;">
                            Ingresa la dirección IP de tu impresora térmica de red (Ethernet o Wi-Fi) para recibir comandas y tickets automáticamente.
                        </p>
                        <div style="display:flex;flex-direction:column;gap:10px;">
                            <div>
                                <label style="display:block;font-size:12px;font-weight:600;color:#cbd5e1;margin-bottom:4px;">Dirección IP de la Impresora:</label>
                                <input id="eo-input-ip" type="text" placeholder="Ej: 192.168.1.100" style="width:100%;padding:10px 12px;background:#1e293b;border:1px solid rgba(148,163,184,0.3);border-radius:10px;color:#ffffff;font-size:15px;outline:none;box-sizing:border-box;" />
                            </div>
                            <div>
                                <label style="display:block;font-size:12px;font-weight:600;color:#cbd5e1;margin-bottom:4px;">Puerto TCP (ESC/POS):</label>
                                <input id="eo-input-port" type="number" value="9100" style="width:100%;padding:10px 12px;background:#1e293b;border:1px solid rgba(148,163,184,0.3);border-radius:10px;color:#ffffff;font-size:15px;outline:none;box-sizing:border-box;" />
                            </div>
                        </div>
                        <div id="eo-status-box" style="display:none;padding:8px 12px;border-radius:8px;font-size:12px;line-height:1.3;"></div>
                        <div style="display:flex;flex-direction:column;gap:8px;margin-top:4px;">
                            <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;">
                                <button id="eo-btn-ping" style="padding:10px 8px;background:rgba(59,130,246,0.15);border:1px solid rgba(59,130,246,0.4);border-radius:10px;color:#93c5fd;font-size:13px;font-weight:600;cursor:pointer;">🔍 Probar Ping</button>
                                <button id="eo-btn-test-print" style="padding:10px 8px;background:rgba(16,185,129,0.15);border:1px solid rgba(16,185,129,0.4);border-radius:10px;color:#6ee7b7;font-size:13px;font-weight:600;cursor:pointer;">🧾 Ticket Demo</button>
                            </div>
                            <button id="eo-btn-save" style="padding:12px;background:linear-gradient(135deg,#2563eb,#1d4ed8);border:none;border-radius:10px;color:#ffffff;font-size:14px;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(37,99,235,0.35);">💾 Guardar Configuración</button>
                        </div>
                    </div>
                `;

                document.body.appendChild(overlay);

                overlay.querySelector('#eo-modal-close').addEventListener('click', closeSettingsModal);
                overlay.addEventListener('click', (e) => {
                    if (e.target === overlay) closeSettingsModal();
                });

                overlay.querySelector('#eo-btn-ping').addEventListener('click', async () => {
                    const ip = overlay.querySelector('#eo-input-ip').value.trim();
                    const port = parseInt(overlay.querySelector('#eo-input-port').value || '9100', 10);

                    if (!ip) {
                        showModalStatus('Ingresa una IP primero.', 'error');
                        return;
                    }

                    showModalStatus('Conectando por TCP a ' + ip + ':' + port + '...', 'loading');

                    try {
                        const res = await window.Capacitor.Plugins.EasyOrderPrinter.checkStatus({ ip, port, timeoutMs: 3500 });
                        if (res.connected) {
                            showModalStatus('🟢 ONLINE: ' + res.message, 'success');
                        } else {
                            showModalStatus('🔴 OFFLINE: ' + res.message, 'error');
                        }
                    } catch (err) {
                        showModalStatus('Error: ' + (err.message || err), 'error');
                    }
                });

                overlay.querySelector('#eo-btn-test-print').addEventListener('click', async () => {
                    const ip = overlay.querySelector('#eo-input-ip').value.trim();
                    const port = parseInt(overlay.querySelector('#eo-input-port').value || '9100', 10);

                    if (!ip) {
                        showModalStatus('Ingresa una IP primero.', 'error');
                        return;
                    }

                    showModalStatus('Enviando comanda demo a ' + ip + '...', 'loading');

                    const now = new Date().toLocaleString();
                    const testHtml = `
                        <div style="text-align:center;">
                            <h2>*** EASYORDER TEST ***</h2>
                            <p>Impresora Termica ESC/POS</p>
                            <p>` + now + `</p>
                            <hr>
                        </div>
                        <table>
                            <tr><td>1  Platillo Demo</td><td>$150.00</td></tr>
                            <tr><td>1  Refresco</td><td>$35.00</td></tr>
                            <tr><th>TOTAL:</th><th>$185.00</th></tr>
                        </table>
                        <hr>
                        <div style="text-align:center;">
                            <p>¡Conexion exitosa desde iPhone!</p>
                        </div>
                    `;

                    try {
                        const base64Data = htmlToEscPos(testHtml);
                        const res = await window.Capacitor.Plugins.EasyOrderPrinter.print({ ip, port, data: base64Data, timeoutMs: 5000 });
                        showModalStatus('✓ Ticket enviado (' + (res.bytesWritten || 'OK') + ' bytes)', 'success');
                    } catch (err) {
                        showModalStatus('Error al imprimir: ' + (err.message || err), 'error');
                    }
                });

                overlay.querySelector('#eo-btn-save').addEventListener('click', async () => {
                    const ip = overlay.querySelector('#eo-input-ip').value.trim();
                    const port = parseInt(overlay.querySelector('#eo-input-port').value || '9100', 10);

                    await savePrinterConfig(ip, port);
                    showToast('✓ Configuración guardada en el dispositivo', 'success');
                    closeSettingsModal();
                });
            }

            function showModalStatus(msg, type) {
                const statusBox = document.getElementById('eo-status-box');
                if (!statusBox) return;

                statusBox.style.display = 'block';
                statusBox.textContent = msg;

                if (type === 'success') {
                    statusBox.style.background = 'rgba(16, 185, 129, 0.15)';
                    statusBox.style.color = '#6ee7b7';
                    statusBox.style.border = '1px solid rgba(16, 185, 129, 0.3)';
                } else if (type === 'error') {
                    statusBox.style.background = 'rgba(239, 68, 68, 0.15)';
                    statusBox.style.color = '#fca5a5';
                    statusBox.style.border = '1px solid rgba(239, 68, 68, 0.3)';
                } else {
                    statusBox.style.background = 'rgba(59, 130, 246, 0.15)';
                    statusBox.style.color = '#93c5fd';
                    statusBox.style.border = '1px solid rgba(59, 130, 246, 0.3)';
                }
            }

            async function openSettingsModal() {
                createModalHTML();
                const overlay = document.getElementById('eo-settings-modal');
                const config = await getPrinterConfig();

                if (overlay) {
                    overlay.querySelector('#eo-input-ip').value = config.ip || '';
                    overlay.querySelector('#eo-input-port').value = config.port || 9100;
                    const statusBox = overlay.querySelector('#eo-status-box');
                    if (statusBox) statusBox.style.display = 'none';
                    overlay.style.display = 'flex';
                }
            }

            function closeSettingsModal() {
                const overlay = document.getElementById('eo-settings-modal');
                if (overlay) overlay.style.display = 'none';
            }

            function ensureUI() {
                if (!document.body) {
                    setTimeout(ensureUI, 100);
                    return;
                }
                initUI();
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', ensureUI);
            } else {
                ensureUI();
            }
        })();
        """#
        
        let userScript = WKUserScript(source: bridgeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        bridge?.webView?.configuration.userContentController.addUserScript(userScript)
    }
}
