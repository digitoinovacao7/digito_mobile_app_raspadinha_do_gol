# Especificação e Planejamento: Plataforma "Raspadinha do Gol"

## Índice / Sumário
1. [Arquitetura da Plataforma](#parte-1-arquitetura-da-plataforma)
2. [Painel Administrativo (Completo)](#parte-2-painel-administrativo-completo)
3. [Wireframes Textuais](#parte-3-wireframes-textuais-de-cada-tela-principal)
4. [Estrutura do Site / Landing Page](#parte-4-estrutura-do-site--landing-page)
5. [User Journey (Jornada do Usuário)](#parte-5-user-journey-jornada-do-usuário)
6. [Modelo de Negócio Detalhado](#parte-6-modelo-de-negócio-detalhado)
7. [Elementos Legais e de Transparência](#parte-7-elementos-legais-e-de-transparência)

---

## PARTE 1: ARQUITETURA DA PLATAFORMA

### 1.1 Visão Geral do Sistema
A plataforma "Raspadinha do Gol" é concebida como um sistema moderno, focado em alta disponibilidade e concorrência em tempo real (já que os picos de tráfego ocorrem durante partidas ao vivo).

- **Frontend App:** Flutter (Android/iOS) ou React Native para alta fluidez e animações nativas. 
- **Frontend Web/Admin:** React (TypeScript) hospedado no Firebase Hosting ou Vercel.
- **Backend:** Node.js (com Express/NestJS) ou Python (FastAPI). Sugere-se uso de serverless functions (Firebase Cloud Functions / AWS Lambda) para escalabilidade automática em picos de gols.
- **Banco de Dados:** PostgreSQL (Relacional para usuários, histórico financeiro/tokens, prêmios) + Redis (cache em tempo real para ranking e processamento de quizzes ao vivo) ou Firebase Firestore (NoSQL, em tempo real).
- **APIs & Integrações:**
  - **API de Partidas:** Integração com serviços como API-Football ou Sportmonks para webhooks de eventos ao vivo (gols, cartões, fim de jogo).
  - **API de Inteligência Artificial:** OpenAI (GPT-4) ou Anthropic (Claude) para gerar perguntas contextuais da partida.
  - **Sistema de Pagamentos:** Stripe, Mercado Pago ou Pagar.me para compra de pacotes de tokens via PIX/Cartão.
  - **Notificações:** Firebase Cloud Messaging (FCM) para push notifications durante o jogo.

**Fluxo de Dados Principal (Ao Vivo):**
1. Partida acontece -> API de Partidas dispara webhook de evento (ex: Gol).
2. Backend recebe webhook -> Aciona IA para gerar pergunta com base no contexto -> Salva no Redis/Firestore.
3. Backend dispara Push Notification via FCM para usuários conectados.
4. Usuários acessam o app e respondem em X segundos -> Acerto gera tokens -> Salva no DB.

### 1.2 Módulos Principais
- **Módulo de Quiz:**
  - Motor de execução em tempo real sincronizado via WebSockets ou Firestore.
  - Gerador de perguntas baseado em prompts pré-definidos integrados à IA.
- **Módulo de Tokens (Ledger):**
  - Registro imutável de transações (ganho, compra, gasto em raspadinha).
  - Controle de balanço com prevenção a race-conditions.
- **Módulo de Raspadinha:**
  - Lógica algorítmica para determinar o resultado baseado nas configurações de probabilidade (RNG - Random Number Generator pseudo-aleatório seguro).
  - Renderização do grid 3x3 com animações gamificadas.
- **Módulo de Prêmios:**
  - Gestão de saques PIX solicitados pelos usuários e controle antifraude das conversões de Token para Real.
- **Módulo de Usuários:**
  - Autenticação JWT / Firebase Auth.
  - Perfil, avatares, sequências de login (streaks).
- **Módulo de Partidas:**
  - Crawler/cronjobs para manter agenda de jogos atualizada.
- **Módulo de Gamificação:**
  - Emblemas (Badges), XP, Níveis, Ranking Semanal/Mensal.

### 1.3 Fluxo de Navegação do Usuário
**Jornada:** Cadastro (Ganha Tokens Iniciais) -> Home (Vê jogos de hoje) -> Entra no modo "Ao Vivo" (Espera o gol) -> Notificação de Quiz -> Responde e ganha Tokens -> Vai para "Raspadinha" -> Raspa -> Ganha/Perde -> Resgata prêmio ou joga novamente.

### 1.4 Funcionalidades por Área
- **Quiz ao Vivo:** Timer sincronizado, feedback visual instantâneo (certo/errado), placar ao vivo da partida.
- **Raspadinha do Gol:** Botão "Raspar tudo", som de suspense, animação de partículas ao ganhar.
- **Loja de Tokens:** Pacotes promocionais, pagamento 1-click com PIX copia e cola.
- **Loja de Prêmios:** Vitrine de prêmios, formulário de endereço para entrega, status do envio.
- **Perfil do Usuário:** Saldo em destaque, histórico de raspadinhas, badges conquistados.
- **Rankings e Conquistas:** Leaderboard (Top Torcedores), barra de progresso para o próximo nível.

---

## PARTE 2: PAINEL ADMINISTRATIVO (COMPLETO)

### 2.1 Configurações de Quiz
- **Tipo de Quiz:** Alternar entre História do Futebol, Ao Vivo, Conhecimentos Gerais.
- **Fonte das Perguntas:** Manual, IA ou API externa.
- **Configuração de IA:** Campo para o prompt base (Ex: *"Você é um narrador. O jogador {player} acabou de fazer um gol. Crie uma pergunta sobre a carreira dele com 4 alternativas, onde a A é a correta..."*).
- **Parâmetros:** Nível de dificuldade (F/M/D), tempo limite da tela (ex: 15s), Tokens por acerto (+10) / erro (+0).
- **Gestão:** Visualização e moderação de perguntas geradas antes de irem ao ar (opcional).

### 2.2 Configurações de Tokens
- **Economia:** Bônus de boas-vindas (ex: 100 T), custo por raspadinha (ex: 50 T), bônus diário (+10 T/dia, acumulativo até o 7º dia).
- **Pacotes à venda:** Criar/Editar pacotes (ex: "Pacote Craque: 1000 Tokens por R$ 9,90").
- **Histórico Geral:** Tabela de logs globais de criação/destruição de tokens na economia.

### 2.3 Configurações de Prêmios
- **Catálogo (CRUD):** Foto, Nome, Descrição, Tipo (Físico, Digital/Cupom).
- **Motor de Probabilidades (RNG):** Ajuste de chances. Ex: Chuteira (0.01%), Camisa (0.1%), Cupom 10% (5%), Tokens Extras (20%), Nada (74.89%).
- **Estoque:** Quantidade disponível, alerta de limite (ex: "Avisar quando restar 1").
- **Parceiros:** Cadastro da loja emissora do cupom, validade e código base.

### 2.4 Configurações da Raspadinha
- **Design Dinâmico:** Alterar os assets do grid (Tema Copa, Tema Brasileirão).
- **Combinações:** Tabela de regras de vitória (Ex: ⚽⚽⚽ = Prêmio Físico; ⚽⚽⭐ = 500 Tokens).
- **Limites:** Trava antifraude (Máx. 20 raspadinhas / hora / IP).

### 2.5 Histórico de Ganhadores (OBRIGATÓRIO)
- **Tabela de Vencedores:** ID, Nickname, E-mail, Prêmio ganho, Data/Hora, Status do Envio (Pendente, Preparando, Enviado, Entregue).
- **Ações:** "Marcar como Enviado", "Inserir Código de Rastreio dos Correios".
- **Filtros e Exportação:** Relatórios detalhados em CSV/Excel para a equipe de logística.
- **Hall da Fama:** Toggle "Exibir na tela inicial do app?".

### 2.6 Gestão de Partidas
- **Calendário:** Seleção de jogos que terão cobertura do quiz.
- **Automação:** Ligar/Desligar webhook automático para uma partida específica.
- **Status Manual:** Forçar alteração de status em caso de atraso/falha da API.

### 2.7 Relatórios e Métricas
- **Dashboard Executivo:** Cards com Usuários Ativos (MAU/DAU), Total de Tokens em Circulação, Custo Agregado de Prêmios Entregues.
- **Gráficos:** Curva de engajamento durante o horário do jogo vs. fora do jogo.
- **Funil:** Visitas -> Cadastros -> Primeiro Quiz -> Primeira Raspadinha.

### 2.8 Gestão de Usuários e 2.9 Configurações Gerais
- **Usuários:** Lista completa, ferramenta de "Ban/Unban" manual, redefinição de senha, estorno de tokens.
- **Gerais:** Variáveis de ambiente, Chaves de API (OpenAI, Sportmonks, Stripe), Termos de Uso (editor de texto rico).

---

## PARTE 3: WIREFRAMES TEXTUAIS DE CADA TELA PRINCIPAL

### Telas do App (Usuário)

**1. Splash / Onboarding**
- *Corpo:* Logo animado "Raspadinha do Gol".
- *Botões:* "Pular", "Próximo". (Passos: 1. Assista aos jogos, 2. Responda rápido, 3. Raspe e ganhe prêmios de verdade!).
- *Rodapé:* Botão "Começar a Jogar".

**3. Home (Dashboard)**
- *Header:* Avatar, Nickname, Saldo [ 🟡 250 Tokens ] (com ícone de "+").
- *Destaque (Hero):* Card "Jogo de Hoje: Flamengo x Palmeiras - Às 21h. Fique ligado!".
- *Corpo:*
  - Botão Gigante: "Raspadinha do Gol - JOGAR AGORA (50 🟡)".
  - Lista Horizontal: "Prêmios em Destaque" (Camisa oficial, Bola, Cupons).
  - Banner: "Convide um amigo e ganhe 100 Tokens!".
- *Footer Menu (Bottom Nav):* Home | Partidas | Raspadinha | Loja | Perfil.

**5. Tela de Quiz (Ao Vivo)**
- *Header:* Placar do Jogo em tempo real, Timer regressivo [00:12].
- *Corpo:* 
  - Texto grande: "O juiz acabou de dar cartão amarelo. Para quem foi?"
  - 4 Botões grandes com as alternativas.
- *Feedback:* Ao clicar, botão fica azul, ao encerrar o tempo, a certa fica verde.

**7. Tela da Raspadinha do Gol**
- *Header:* Saldo atual.
- *Corpo:* Área cinza texturizada "Passe o dedo para raspar!".
- *Ações:* Botão "Raspar Tudo Imediatamente". Botão "Tentar Novamente (-50 🟡)".

**11. Tela de Loja de Prêmios (Resgate)**
- *Header:* "Vitrine de Prêmios".
- *Corpo:* Grid com fotos reais dos produtos. 
  - Ex: 1000 Tokens [Requer: Acertar 3 Bolas].
  - Cardápio de tokens extras.
- *Ação:* Botão "Ver Meus Prêmios Ganhos".

### Telas do Painel Admin

**1. Dashboard Principal**
- *Sidebar (Esquerda):* Dashboard, Quizzes, Tokens, Prêmios, Raspadinha, Ganhadores, Partidas, Usuários, Config.
- *Topo:* Resumo rápido (Tokens ativos, Receita Mês, Custos Mês).
- *Centro:* Gráfico de linha temporal (Usuários simultâneos hoje).
- *Avisos:* "⚠️ Estoque de Camisa do Brasil esgotado!".

---

## PARTE 4: ESTRUTURA DO SITE / LANDING PAGE

### 4.1 Header
- **Logo:** Raspadinha do Gol (com ícone de bola estilizado).
- **Menu:** Como Funciona | Prêmios | Transparência | FAQ.
- **CTA:** "Baixe o App Grátis" (destacado em verde neon).

### 4.2 Hero Section
- **Headline:** A emoção do futebol, a adrenalina de ganhar prêmios reais.
- **Subheadline:** Assista aos seus jogos favoritos, prove que você entende de futebol e raspe para ganhar camisas, bolas, cupons e muito mais. Tudo isso sem gastar nada!
- **CTA:** "Baixar para Android" / "Baixar para iOS".
- **Imagem:** Mockup de um smartphone mostrando o momento de uma vitória na raspadinha (3 bolas de futebol alinhadas) explodindo em confetes, com uma camisa de time saindo da tela.

### 4.3 Seção "Como Funciona"
- **Passo 1:** 📺 *Assista aos Jogos:* Acompanhe as partidas ao vivo.
- **Passo 2:** 🧠 *Mostre sua Habilidade:* Responda aos quizzes relâmpago que aparecem no app durante o jogo.
- **Passo 3:** 🟡 *Acumule Tokens:* Acertou? Ganhou tokens virtuais!
- **Passo 4:** 🎟️ *Raspe e Ganhe:* Use os tokens na Raspadinha do Gol e concorra a prêmios incríveis.

### 4.4 e 4.7 Seções de Benefícios e Transparência
- **Headline (Transparência):** Pura Habilidade, Zero Aposta.
- **Copy:** "A Raspadinha do Gol NÃO é uma casa de apostas. É uma plataforma de gamificação feita para os verdadeiros fãs de futebol. Seus tokens são conquistados com o seu conhecimento (ou adquiridos opcionalmente), e os prêmios são estritamente bens de consumo (camisas, produtos, cupons). Aqui, você não aposta seu dinheiro, você joga com a sua paixão!"

### 4.10 FAQ (Exemplos)
- **Q: É aposta? É legal?** 
  *R: Não somos casa de apostas. Somos um jogo de habilidade e conhecimentos gerais (quiz) onde a recompensa são tokens virtuais sem valor financeiro. Você troca esses tokens por chances em uma raspadinha promocional com prêmios físicos, em total conformidade com as leis de distribuição gratuita de prêmios/gamificação.*
- **Q: Como resgato meu prêmio?**
  *R: Ao ganhar um prêmio físico na raspadinha, você preencherá seu endereço no próprio app. Nossa equipe cuidará do envio e você receberá um código de rastreio em até 48 horas.*

---

## PARTE 5: USER JOURNEY (JORNADA DO USUÁRIO)

**1. Descoberta:** João (25, fã de futebol) vê um Reels no Instagram de um influenciador esportivo comemorando que ganhou uma camisa do seu time de graça só respondendo quiz durante o jogo. João clica no link e baixa o app.
**2. Cadastro/Onboarding:** João cria conta com o Google em 1 clique. O app explica "Você ganhou 100 tokens iniciais!". João vê um tutorial rápido da tela de raspadinha.
**3. Primeira Raspadinha (Hook):** João usa 50 tokens. Raspa a tela com o dedo... encontra 2 bolas e 1 cartão amarelo. Quase! Ele ainda tem 50 tokens.
**4. O Evento (Ao Vivo):** João recebe uma notificação às 21h30: "O São Paulo acabou de marcar! Responda rápido e ganhe Tokens!". Ele abre o app, responde "Quem deu a assistência?", acerta e ganha +100 tokens.
**5. A Vitória:** Com 150 tokens, ele faz 3 raspadinhas. Na última, a tela treme, toca o apito de juiz, animação de gol: ⚽⚽⚽! "VOCÊ GANHOU: CAMISA OFICIAL". 
**6. Resgate e Fidelização:** João insere o endereço. Uma semana depois a camisa chega. Ele tira foto, posta no Instagram marcando o app, ganha tokens de indicação e se torna um usuário fidelizado.

---

## PARTE 6: MODELO DE NEGÓCIO DETALHADO

### 6.1 Fontes de Receita
1. **In-App Purchases (Venda de Tokens):** Usuários impacientes que não querem esperar os jogos podem comprar tokens (ex: R$ 4,90 por 500 tokens). É a principal linha de receita.
2. **Publicidade e Patrocínios:** 
   - Anúncios (AdMob/Unity Ads) para ganhar tokens grátis (Rewarded Video).
   - "Raspadinha patrocinada pela marca X" (Onde o prêmio é exclusivo daquela marca).
3. **Afiliados / Cupons:** Comissão via link de afiliado quando usuários ganham "Cupons de Desconto de 20%" na raspadinha (Prêmios de consolação) e efetuam compra nas lojas parceiras (Centauro, Netshoes, etc).

### 6.2 Custos
- Servidores (Escaláveis para picos) / Banco de Dados.
- Custo de Aquisição de Prêmios Físicos e Logística (Frete).
- APIs (ChatGPT, API de Dados de Futebol).
- Marketing e CAC (Anúncios no Meta/Tiktok).

### 6.3 Métricas-Chave (KPIs)
- **CPA (Custo por Aquisição):** Ideal < R$ 2,00 por install.
- **Rácio de Conversão Free -> Paid:** Ideal > 3%.
- **Margem de Premiação:** O custo dos prêmios deve ser estritamente controlado pela probabilidade (RNG) para garantir que a receita dos tokens vendidos + ads seja sempre pelo menos 40% superior ao custo dos prêmios entregues.

### 6.4 Estratégia de Crescimento
Lançamento focado no Campeonato Brasileiro. Parceria com canais do YouTube e perfis focados no "cartola" e palpites. Criação do formato de "Drop de Prêmios": "Neste domingo de clássico, a Raspadinha do Gol vai sortear 10 PlayStation 5 durante o jogo".

---

## PARTE 7: ELEMENTOS LEGAIS E DE TRANSPARÊNCIA

### 7.1 Blindagem Jurídica (Brasil)
- **Não é Loteria/Sorteio Pagar-para-Entrar:** O app não vende bilhetes de sorteio (o que requereria autorização da SECAP/SRE). O app possui uma mecânica "Freemium" de habilidade (Quiz). Os tokens são a recompensa da habilidade. A compra de tokens é tratada como "compra de moeda virtual para entretenimento", comum em jogos de videogame (V-Bucks, Riot Points).
- **Prêmios Promocionais:** Os prêmios não têm conversibilidade em dinheiro.

### 7.2 Termos de Uso (Pontos Chaves)
- Idade Mínima: 18 anos (para evitar problemas de regulação infantil sobre gamificação).
- Conta Única: Proibição estrita de múltiplas contas por IP/CPF para abusar de bônus diários.
- Atrasos de Transmissão (Delay): Isenção de responsabilidade sobre delay de streaming vs app (O quiz reflete o tempo real dos provedores de dados, não o da TV do usuário).

### 7.3 Transparência e RNG
- A plataforma se compromete a fornecer mecânicas limpas.
- Não garantimos prêmios em nenhuma circunstância. A Raspadinha do Gol é baseada num sistema de probabilidades gerado matematicamente.
- É estritamente proibida a negociação, venda ou transferência de contas ou prêmios físicos não resgatados para terceiros.

---
*Fim do Documento de Especificação.*