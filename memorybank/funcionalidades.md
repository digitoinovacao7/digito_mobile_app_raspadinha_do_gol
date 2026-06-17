# Funcionalidades do App "Raspadinha do Gol"

Este documento descreve todas as funcionalidades e regras de negócio presentes no aplicativo móvel e seu respectivo backend (Firebase).

## 1. Autenticação e Usuários

- **Login com Google:** O usuário deve obrigatoriamente fazer login usando a sua conta do Gmail para acessar o aplicativo.
- **Sistema de Perfis (Roles):** Existem dois tipos de usuário no sistema: `user` (padrão) e `admin`. Essa regra é gravada diretamente na base de dados (Firestore).
- **Configurações e Notificações:** O usuário tem acesso a uma tela de Configurações (via barra de navegação inferior) onde pode ativar o Opt-in de notificações via WhatsApp. Esse status é salvo diretamente em seu documento no Firestore (`wants_whatsapp_notifications`), permitindo que a equipe de marketing faça envios seguros.

## 2. Painel Administrativo (Acesso Restrito)

Apenas usuários com a role `admin` podem acessar a tela de Painel Administrativo, que fica disponível diretamente na Barra de Navegação Inferior (Bottom Navigation Bar). Esta tela permite gerenciar diversas áreas do app:

- **Integrações e API:** Gerenciamento de chaves (ex: API-Football, Mercado Pago, Z-API para WhatsApp, e chave da API do **Google Gemini**).
- **Regras de Economia:** Controle da economia do jogo, incluindo o custo da raspadinha em tokens, a recompensa em tokens por acerto no quiz, e a **taxa de conversão de Tokens para Dinheiro Real (PIX)** (ex: definir que 100 Tokens = R$ 1,00).
- **Gestão de Prêmios:** Cadastro de prêmios (Pix, Camisas, etc). O admin define a **Probabilidade** de o prêmio sair na raspadinha (ex: 1 a cada 1000) e o **Custo na Loja** em Tokens (para resgate direto sem raspadinha). Também é possível definir se o prêmio é Global, para um Campeonato específico ou para uma Partida específica.
- **Histórico e Ganhadores (Futuro/Planejado):** Acompanhamento dos usuários que ganharam prêmios físicos ou digitais, além do status de entrega.

## 3. Tela Principal (Home / Placares Ao Vivo)

- O aplicativo exibe as partidas em andamento.
- Durante a partida, o usuário acompanha o tempo e eventos importantes.
- **Gatilhos Dinâmicos (Eventos Reais):** O aplicativo monitora os eventos da partida ao vivo (Ex: Fim do 1º Tempo, Fim de Jogo, ou Gols de qualquer um dos times). Cada evento desses gera 1 "Chance" para o usuário responder a um Quiz.
- **Acúmulo de Chances:** Se saírem 3 gols rápido, o usuário acumula 3 chances. A chance só é "gasta" e contabilizada quando o usuário **acerta** a resposta. Se ele errar, ele pode tentar de novo (gerando um novo quiz).

## 4. Dinâmica do Quiz e Tokens (Motor Gemini)

- **Geração do Quiz (Inteligência Artificial):** O backend utiliza a API do **Google Gemini** para gerar perguntas de múltipla escolha exclusivas baseadas no contexto da partida em tempo real. O modelo elabora a pergunta, 4 opções e a resposta correta de forma inteligente, armazenando os dados no Firestore.
- **Quiz ao Vivo e Segurança:** Ao ser notificado do evento na partida, o usuário vê a pergunta e as opções geradas pelo Gemini. Para garantir a segurança e evitar fraudes (ou custos altos de API), a conferência da resposta é feita localmente no backend comparando o índice selecionado com o índice correto previamente salvo no banco de dados. O Gemini não é chamado novamente para validar a resposta do usuário.
- **Recompensa em Tokens:** Se o usuário responder corretamente (dentro da janela de tempo/tentativas), ele ganha uma quantidade pré-configurada de **Tokens Virtuais**. Um controle interno impede que o mesmo usuário ganhe tokens mais de uma vez para o mesmo quiz.

## 5. O Jogo (A Raspadinha)

- **Custo da Raspadinha:** Para jogar, o usuário precisa gastar uma quantidade pré-determinada de seus Tokens acumulados (Ex: 1000 Tokens por jogada, definido pelo Admin).
- **Mecânica:** O usuário "esfrega" o dedo na tela para remover a tinta prateada da raspadinha ou clica no botão para descobrir o resultado rapidamente.
- **Grid Oculto:** O painel revela 9 espaços. O resultado é calculado via Motor de Probabilidades (RNG), de acordo com as probabilidades dos prêmios configurados no painel admin.
- **Condição de Vitória:** O usuário ganha ao alinhar combinações específicas (ex: 3 imagens iguais do prêmio). Do contrário, revela ícones variados de "tente novamente".

## 6. Carteira, Loja de Prêmios e Extrato Seguro

- **Carteira e Saque PIX:** O usuário acessa sua carteira pela barra superior. Nela, ele vê seu saldo de Tokens e pode solicitar um saque via PIX instantâneo informando sua chave, respeitando a taxa de conversão configurada.
- **Loja de Prêmios (Resgate Físico):** A vitrine exibe produtos físicos. Se o usuário tiver Tokens suficientes, ele pode resgatar o prêmio diretamente.
- **Extrato de Tokens (Histórico):** Há uma tela de extrato cronológico (como uma conta bancária) que mostra tudo o que o usuário ganhou (Acertos no Quiz: +250), perdeu (Compras na loja: -500), e inclusive os **erros nos quizzes** (0 Tokens), permitindo total transparência e gamificação.
- **Transações Seguras (Anti-Fraude):** O motor financeiro utiliza *Transações Atômicas* no Firestore. O ato de comprar/sacar verifica o saldo direto no banco de forma isolada, deduz o valor e cria o recibo ao mesmo tempo. Isso blinda o app contra fraudes de manipulação de saldo no celular.
- **Cadastro Completo:** Para resgatar prêmios, o app exige CPF e Telefone do usuário.

## 7. Plano de Melhorias Futuras (Carteira e Resgate)

Para aumentar a segurança e melhorar a experiência do usuário durante o resgate de prêmios, as seguintes melhorias estão planejadas para a tela de Carteira/Loja:

### A. Fluxo de Resgate de Produto (Voucher/Link Externo)
- Em vez de coletar endereços e gerenciar logística de envio internamente, o administrador pode cadastrar um **Link de Resgate / Voucher** ao criar o prêmio no painel (opcional).
- Ao resgatar ou ganhar na raspadinha um prêmio que possua esse link, o usuário será direcionado diretamente para o e-commerce parceiro ou página de voucher.
- Isso elimina a necessidade de preenchimento de endereço e simplifica a operação de distribuição de prêmios do aplicativo.

### B. Fluxo de Saque PIX (Validação OTP)
- Para garantir que a conta e a chave PIX pertencem ao usuário e evitar fraudes de saque, a solicitação de PIX passará por uma camada extra de segurança.
- Ao cadastrar/informar a chave PIX para saque, o sistema enviará um **Código OTP (One-Time Password)** de 6 dígitos para o E-mail ou WhatsApp cadastrado do usuário.
- O saque só será efetivado e descontado do saldo de tokens após o usuário inserir o código OTP correto em uma tela de verificação.
- Isso protege a carteira do usuário contra acessos não autorizados.