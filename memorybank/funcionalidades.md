# Funcionalidades do App "Raspadinha do Gol"

Este documento descreve todas as funcionalidades e regras de negócio presentes no aplicativo móvel e seu respectivo backend (Firebase).

## 1. Autenticação e Usuários

- **Login com Google:** O usuário deve obrigatoriamente fazer login usando a sua conta do Gmail para acessar o aplicativo.
- **Sistema de Perfis (Roles):** Existem dois tipos de usuário no sistema: `user` (padrão) e `admin`. Essa regra é gravada diretamente na base de dados (Firestore).
- **Configurações e Notificações:** O usuário tem acesso a uma tela de Configurações (via barra de navegação inferior) onde pode ativar o Opt-in de notificações via WhatsApp. Esse status é salvo diretamente em seu documento no Firestore (`wants_whatsapp_notifications`), permitindo que a equipe de marketing faça envios seguros.

## 2. Painel Administrativo (Acesso Restrito)

Apenas usuários com a role `admin` podem acessar a tela de Painel Administrativo, que fica disponível diretamente na Barra de Navegação Inferior (Bottom Navigation Bar). Esta tela permite gerenciar diversas áreas do app:

- **Integrações e API:** Gerenciamento de chaves (ex: API-Football, Z-API para WhatsApp, e chave da API do **Google Gemini**).
- **Gestão de Prêmios:** Cadastro de prêmios físicos (Camisas, Brindes, etc) e vouchers de desconto. É possível definir se o prêmio é Global, para um Campeonato específico ou para uma Partida específica.
- **Histórico e Ganhadores (Futuro/Planejado):** Acompanhamento dos usuários que ganharam prêmios físicos ou digitais, além do status de entrega.

## 3. Tela Principal (Home / Placares Ao Vivo)

- O aplicativo exibe as partidas em andamento e os campeonatos disponíveis.
- Durante a partida, o usuário acessa a "Sala da Partida" para acompanhar o tempo e eventos importantes.
- **Gatilhos Dinâmicos (Eventos Reais):** O aplicativo monitora os eventos da partida ao vivo (Ex: Fim do 1º Tempo, Fim de Jogo, ou Gols de qualquer um dos times). 
- **Raspadinha Imediata:** Cada evento real desses gera 1 "Chance" para o usuário jogar a Raspadinha do Gol. O botão da raspadinha surge em tempo real na tela da partida.
- **Acúmulo de Chances:** Se saírem 3 gols, o usuário ganha 3 chances de raspar cartelas. A chance é consumida assim que o usuário abre e joga a Raspadinha referente àquele evento.

## 4. O Jogo (A Raspadinha do Gol)

- **Acesso Gratuito via Jogos:** O usuário não gasta "Tokens" ou dinheiro para raspar. Ele ganha o direito de jogar puramente por estar acompanhando a partida e presenciar um evento (gol, intervalo, fim de jogo).
- **Mecânica:** O usuário "esfrega" o dedo na tela para remover a tinta prateada da raspadinha ou clica no botão para descobrir o resultado rapidamente.
- **Grid Oculto:** O painel revela 9 espaços. O resultado é determinado por um sorteio aleatório (RNG via Cloud Functions) no momento da jogada, onde todos os prêmios ativos têm uma chance de sair.
- **Condição de Vitória:** O usuário ganha ao alinhar combinações específicas (ex: 3 imagens iguais do prêmio). Do contrário, revela ícones variados de "tente novamente".

## 5. Quiz Extra (Diversão com Inteligência Artificial)

- **Aba de Quiz Independente:** O aplicativo conta com uma aba secundária dedicada aos fãs que desejam testar seus conhecimentos gerais de futebol.
- **Geração Dinâmica:** O servidor utiliza a API do **Google Gemini** para gerar perguntas de múltipla escolha de forma ilimitada e inteligente.
- **Foco no Engajamento:** O Quiz não concede prêmios ou chances na Raspadinha. Ele serve como uma ferramenta de retenção e diversão enquanto o usuário aguarda o próximo gol nas partidas ao vivo.

## 6. Vitrine de Prêmios e Resgate

- **Vitrine de Prêmios:** O aplicativo possui uma aba onde o usuário pode visualizar todos os prêmios físicos e vouchers que estão disponíveis para serem ganhos nas Raspadinhas (ex: camisas oficiais, chuteiras, copos personalizados).
- **Cadastro Completo:** Para receber prêmios físicos ganhos na raspadinha, o aplicativo exige que o usuário complete o seu perfil com informações de contato e endereço.
- **Fluxo de Resgate de Produto (Voucher/Link Externo):** Em vez de coletar endereços e gerenciar logística de envio internamente, o administrador pode cadastrar um **Link de Resgate / Voucher** ao criar o prêmio no painel. Ao ganhar na raspadinha um prêmio que possua esse link, o usuário é direcionado diretamente para o parceiro.

## 7. Estratégia de Monetização e Parcerias

O aplicativo foca na entrega de prêmios físicos e engajamento, com o seguinte plano de monetização e expansão B2B:

### A. Parcerias B2B e Marcas Patrocinadoras
- **Raspadinhas Patrocinadas:** Marcas parceiras podem comprar o espaço visual de uma raspadinha ou de um evento específico (ex: "Raspadinha Zé Delivery no Gol do Flamengo") oferecendo prêmios da própria marca.
- **Cupons de Afiliados (CPA):** A Vitrine de Prêmios pode distribuir vouchers de desconto para grandes e-commerces como prêmios menores da raspadinha. A plataforma recebe uma comissão (Custo Por Aquisição) sempre que o usuário utilizar o cupom.
- **Naming Rights de Salas:** Possibilidade de comercializar "espaços" e banners dentro da Sala da Partida de jogos de alto tráfego.

### B. Publicidade Gamificada (Ads)
- **Vídeos Premiados:** Futura integração onde o usuário pode assistir a um vídeo publicitário para ganhar chances extras na raspadinha caso a partida termine sem gols.
- **Banners e Interstitiais:** Exibição de anúncios tradicionais no rodapé do aplicativo ou em telas de transição.