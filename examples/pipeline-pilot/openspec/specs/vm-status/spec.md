# vm-status Specification

## Purpose
TBD - created by archiving change vm-status-widget. Update Purpose after archive.

## Requirements

### Requirement: Layout do Card Responsivo
The system SHALL render a responsive widget card using Tailwind CSS, adapting cleanly to mobile devices and desktop screens.

#### Scenario: Visualização em Desktop
- GIVEN que o usuário acessa a página em uma tela desktop (largura >= 640px)
- WHEN a página é carregada
- THEN o card deve ser centralizado com largura máxima adequada e espaçamentos proporcionais.

#### Scenario: Visualização em Mobile
- GIVEN que o usuário acessa a página em dispositivo móvel (largura < 640px)
- WHEN a página é carregada
- THEN os elementos do card devem se reorganizar verticalmente sem quebra de layout ou rolagem horizontal indesejada.

### Requirement: Telemetria de Memória RAM
The system SHALL display the current RAM consumption showing used memory (GB), total memory (GB), usage percentage, and a visual progress bar with semantic alert colors.

#### Scenario: Consumo de Memória em Nível Normal
- GIVEN que o uso de RAM está abaixo de 70%
- WHEN a telemetria é apresentada
- THEN o percentual e a barra de progresso devem exibir tonalidade verde/esmeralda com badge "Normal".

#### Scenario: Alerta de Consumo Elevado de Memória
- GIVEN que o uso de RAM está entre 70% e 89%
- WHEN a telemetria é apresentada
- THEN a barra de progresso e o badge devem mudar para tonalidade âmbar/amarela com badge "Alerta".

#### Scenario: Consumo Crítico de Memória
- GIVEN que o uso de RAM está em 90% ou superior
- WHEN a telemetria é apresentada
- THEN a barra de progresso e o badge devem mudar para tonalidade vermelha/rose com badge "Crítico".

### Requirement: Indicador de Conexão Tailscale
The system SHALL indicate the Tailscale connection status, displaying the Tailnet IPv4 address and node hostname.

#### Scenario: Tailscale Conectado
- GIVEN que o serviço Tailscale está ativo e autenticado
- WHEN o card for exibido
- THEN o indicador deve mostrar badge verde "Conectado" acompanhado do IP da Tailnet (100.x.y.z) e hostname.

#### Scenario: Tailscale Desconectado
- GIVEN que a conexão Tailscale está inativa ou indisponível
- WHEN o card for exibido
- THEN o indicador deve exibir badge cinza/vermelho "Desconectado" e mensagem de fallback.

### Requirement: Ação de Recarregamento de Dados
WHEN the user clicks the "Recarregar Dados" button, the system SHALL refresh memory and network metrics with visual loading feedback.

#### Scenario: Recarregamento com Sucesso
- GIVEN que o usuário clica no botão "Recarregar Dados"
- WHEN a atualização for concluída
- THEN o timestamp de última atualização deve ser atualizado para o horário corrente e os valores na tela devem refletir a nova medição.

#### Scenario: Estado de Carregamento Ativo
- GIVEN que o processo de recarga de dados está em andamento
- WHEN a requisição estiver pendente
- THEN o botão "Recarregar Dados" deve ficar desabilitado e exibir um ícone giratório de spinner.
