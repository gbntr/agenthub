# Proposal: Widget de Status da VM com Indicador de Memória (`vm-status-widget`)

> **Change ID:** `vm-status-widget`  
> **Stage:** `BRIEFING` (Human Gate 1)  
> **UI Impact:** `has_frontend_ui: true` (`ui-mockup.html` incluso)

---

## 1. Resumo

Criar uma página com um widget em formato de card responsivo utilizando **Tailwind CSS** para monitoramento rápido da máquina virtual (VM). O componente exibirá o consumo atual de memória RAM (com barra de progresso visual, percentual e valores em GB) e o status de conectividade da rede **Tailscale** (estado da conexão, IP Tailscale e hostname), acompanhado de um botão interativo para recarregar os dados sob demanda com feedback visual de carregamento.

---

## 2. Escopo (In Scope)

- Layout de página responsivo em **Tailwind CSS** contendo o card de status da VM.
- Indicador visual de uso de memória RAM:
  - Exibição de memória utilizada vs. memória total (ex.: `6.4 GB / 16.0 GB`) e percentual (`40%`).
  - Barra de progresso dinâmica com mudança semântica de cor conforme limiares de uso (Normal `< 70%`, Alerta `70%–89%`, Crítico `>= 90%`).
- Indicador de status de conexão **Tailscale**:
  - Badge visual indicando estado (`Conectado` / `Desconectado`).
  - Exibição de metadados essenciais da sessão Tailscale (IP da Tailnet `100.x.y.z`, nome do nó e latência/rota).
- Botão interativo **"Recarregar Dados"**:
  - Disparo de atualização dos indicadores de memória e status Tailscale.
  - Estado visual de carregamento (`loading` / spinner) e timestamp da última atualização.
- Protótipo visual autocontido em `openspec/changes/vm-status-widget/ui-mockup.html`.

---

## 3. Fora de Escopo (Out of Scope)

- Histórico temporal ou gráficos de séries temporais (ex.: Prometheus/Grafana) de uso de RAM ou rede.
- Gerenciamento administrativo da conexão Tailscale (autenticação OAuth, troca de exit nodes ou edição de ACLs pela interface).
- Monitoramento de múltiplos nós/clusters simultâneos (escopo restrito à VM local).
- Alertas externos via e-mail, Slack, Discord ou Webhooks.

---

## 4. Requisitos Iniciais (EARS Syntax)

### 4.1. Requisitos Ubiquitous (Ubíquos)
- **REQ-01 (Layout Responsivo):** The system SHALL render a responsive VM status card using Tailwind CSS that adapts cleanly across mobile (`< 640px`) and desktop (`>= 640px`) viewports.
- **REQ-02 (Indicador de Memória RAM):** The system SHALL display the current RAM consumption showing used memory (GB), total memory (GB), usage percentage (`0%`–`100%`), and a visual progress bar.
- **REQ-03 (Indicador Tailscale):** The system SHALL display the current Tailscale connection state (`Connected` or `Disconnected`), along with the assigned Tailscale IPv4 address and node hostname.

### 4.2. Requisitos Event-Driven (Orientados a Eventos)
- **REQ-04 (Recarregamento Interativo):** WHEN the user clicks the "Recarregar Dados" button, the system SHALL fetch the latest RAM usage and Tailscale connection metrics and update the card indicators and last-updated timestamp.

### 4.3. Requisitos State-Driven (Orientados a Estado)
- **REQ-05 (Estado de Carregamento):** WHILE the status data is being reloaded, the system SHALL disable the "Recarregar Dados" button and display an animated loading spinner indicator.
- **REQ-06 (Alerta de Uso Elevado de RAM):** WHILE the RAM usage percentage is between `70%` and `89%`, the system SHALL style the memory progress bar and badge with a warning color scheme (amber/yellow).
- **REQ-07 (Estado Crítico de RAM):** WHILE the RAM usage percentage is greater than or equal to `90%`, the system SHALL style the memory progress bar and badge with a critical alert color scheme (red/rose).

### 4.4. Requisitos Unwanted Behavior (Tratamento de Exceções)
- **REQ-08 (Tailscale Desconectado ou Indisponível):** IF the Tailscale daemon is disconnected or unreachable, THEN the system SHALL display a disconnected badge (red/slate) and show a fallback message in place of the active Tailscale IP.
- **REQ-09 (Falha na Atualização de Dados):** IF the data reload operation fails, THEN the system SHALL display a visible error notification inside the widget and preserve the last known valid metrics with their original timestamp.

---

## 5. Etapas Previstas

1. **Stage 1 — `BRIEFING` (Gate 1 - Atual):**
   - Geração e revisão humana do `proposal.md` e aprovação visual preliminar do `ui-mockup.html`.
2. **Stage 2 — `SPEC` (Gate 2):**
   - Detalhamento das especificações formais em `openspec/changes/vm-status-widget/specs/`, lista atômica de tarefas em `tasks.md` e validação via `openspec validate --strict`.
3. **Stage 3 — `APPLY` (`/opsx:apply`):**
   - Implementação do componente/página de produção e integração com coleta de métricas e testes unitários/Zero-Token validation.
4. **Stage 4 — `QA_VISUAL` (`/opsx:verify`):**
   - Verificação automatizada via Playwright MCP comparando a implementação final contra os cenários EARS e o `ui-mockup.html`, gerando `qa-report.md`.
