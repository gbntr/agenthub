/**
 * VM Status Widget — Pipeline Pilot Client Logic
 * Implements EARS Requirements from openspec/changes/vm-status-widget/specs/vm-status/spec.md
 */

const TOTAL_RAM_GB = 11.0;

const state = {
  ramUsedGB: 4.6,
  ramCacheGB: 1.8,
  ramSwapGB: 0.1,
  ramPsi: "0.00%",
  tailscaleConnected: true,
  tailscaleIp: "100.121.31.71",
  tailscaleHostname: "gbntr-vps.tailnet.ts.net",
  tailscaleLatency: "Direta • 6 ms",
  isLoading: false,
};

function formatPercent(used, total) {
  return Math.round((used / total) * 100);
}

function updateMemoryUI() {
  const percent = formatPercent(state.ramUsedGB, TOTAL_RAM_GB);
  const freeGB = (TOTAL_RAM_GB - state.ramUsedGB).toFixed(1);

  const ramUsedEl = document.getElementById("ram-used");
  const ramTotalEl = document.getElementById("ram-total");
  const ramPercentEl = document.getElementById("ram-percent");
  const ramFreeEl = document.getElementById("ram-free");
  const progressBar = document.getElementById("ram-progress-bar");
  const badge = document.getElementById("ram-status-badge");
  const dot = document.getElementById("ram-status-dot");
  const label = document.getElementById("ram-status-label");

  if (ramUsedEl) ramUsedEl.textContent = `${state.ramUsedGB.toFixed(1)} GB`;
  if (ramTotalEl) ramTotalEl.textContent = `${TOTAL_RAM_GB.toFixed(1)} GB`;
  if (ramPercentEl) ramPercentEl.textContent = `${percent}%`;
  if (ramFreeEl) ramFreeEl.textContent = `${freeGB} GB`;

  if (progressBar) {
    progressBar.style.width = `${percent}%`;
    progressBar.setAttribute("aria-valuenow", String(percent));
  }

  // REQ-06 & REQ-07: Semantic Thresholds
  if (percent >= 90) {
    // Critical (Red)
    if (ramPercentEl) ramPercentEl.className = "text-lg sm:text-xl font-bold font-mono text-rose-400";
    if (progressBar) progressBar.className = "h-full rounded-full bg-rose-500 transition-all duration-500 ease-out";
    if (badge) badge.className = "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-rose-500/10 text-rose-400 border border-rose-500/20";
    if (dot) dot.className = "w-1.5 h-1.5 rounded-full bg-rose-400 animate-pulse";
    if (label) label.textContent = "Crítico";
  } else if (percent >= 70) {
    // Warning (Amber)
    if (ramPercentEl) ramPercentEl.className = "text-lg sm:text-xl font-bold font-mono text-amber-400";
    if (progressBar) progressBar.className = "h-full rounded-full bg-amber-500 transition-all duration-500 ease-out";
    if (badge) badge.className = "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20";
    if (dot) dot.className = "w-1.5 h-1.5 rounded-full bg-amber-400";
    if (label) label.textContent = "Alerta";
  } else {
    // Normal (Emerald)
    if (ramPercentEl) ramPercentEl.className = "text-lg sm:text-xl font-bold font-mono text-emerald-400";
    if (progressBar) progressBar.className = "h-full rounded-full bg-emerald-500 transition-all duration-500 ease-out";
    if (badge) badge.className = "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20";
    if (dot) dot.className = "w-1.5 h-1.5 rounded-full bg-emerald-400";
    if (label) label.textContent = "Normal";
  }
}

function updateTailscaleUI() {
  const badge = document.getElementById("ts-status-badge");
  const dot = document.getElementById("ts-status-dot");
  const label = document.getElementById("ts-status-label");
  const ipEl = document.getElementById("ts-ip");
  const hostEl = document.getElementById("ts-hostname");
  const relayEl = document.getElementById("ts-relay");

  if (state.tailscaleConnected) {
    if (badge) badge.className = "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20";
    if (dot) dot.className = "w-2 h-2 rounded-full bg-emerald-400 animate-pulse-subtle";
    if (label) label.textContent = "Conectado";
    if (ipEl) ipEl.textContent = state.tailscaleIp;
    if (hostEl) hostEl.textContent = state.tailscaleHostname;
    if (relayEl) relayEl.textContent = state.tailscaleLatency;
  } else {
    if (badge) badge.className = "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-800 text-slate-400 border border-slate-700";
    if (dot) dot.className = "w-2 h-2 rounded-full bg-slate-500";
    if (label) label.textContent = "Desconectado";
    if (ipEl) ipEl.textContent = "Offline";
    if (hostEl) hostEl.textContent = "Indisponível";
    if (relayEl) relayEl.textContent = "Sem rota ativa";
  }
}

function updateTimestamp() {
  const timeEl = document.getElementById("last-updated-time");
  if (timeEl) {
    const now = new Date();
    timeEl.textContent = now.toTimeString().split(" ")[0];
  }
}

function reloadData() {
  if (state.isLoading) return;
  state.isLoading = true;

  const btn = document.getElementById("reload-btn");
  const icon = document.getElementById("reload-icon");
  const text = document.getElementById("reload-btn-text");

  if (btn) btn.disabled = true;
  if (icon) icon.classList.add("animate-spin");
  if (text) text.textContent = "Atualizando...";

  setTimeout(() => {
    // Simulate slight metrics variation on refresh
    const variance = (Math.random() * 0.6 - 0.3);
    state.ramUsedGB = Math.max(2.0, Math.min(TOTAL_RAM_GB - 0.5, state.ramUsedGB + variance));

    updateMemoryUI();
    updateTailscaleUI();
    updateTimestamp();

    state.isLoading = false;
    if (btn) btn.disabled = false;
    if (icon) icon.classList.remove("animate-spin");
    if (text) text.textContent = "Recarregar Dados";
  }, 600);
}

// Initial binding
if (typeof document !== "undefined") {
  document.addEventListener("DOMContentLoaded", () => {
    updateMemoryUI();
    updateTailscaleUI();
    updateTimestamp();

    const reloadBtn = document.getElementById("reload-btn");
    if (reloadBtn) {
      reloadBtn.addEventListener("click", reloadData);
    }
  });
}

// Node.js export for automated tests
if (typeof module !== "undefined" && module.exports) {
  module.exports = { formatPercent, state, TOTAL_RAM_GB };
}
