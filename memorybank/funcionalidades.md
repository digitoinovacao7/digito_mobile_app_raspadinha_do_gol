# Funcionalidades do App "Raspadinha do Gol"

Este documento descreve todas as funcionalidades e regras de negócio presentes no aplicativo móvel e seu respectivo backend (Firebase).

## 1. Autenticação e Usuários

- **Login com Google:** O usuário deve obrigatoriamente fazer login usando a sua conta do Gmail para acessar o aplicativo.
- **Sistema de Perfis (Roles):** Existem dois tipos de usuário no sistema: `user` (padrão) e `admin`. Essa regra é gravada diretamente na base de dados (Firestore).

## 2. Painel Administrativo (Acesso Restrito)

Apenas usuários com a role `admin` podem acessar a tela de Painel Administrativo. Esta tela permite gerenciar diversas áreas do app:

- **Configurações de Quizzes:** Gerenciamento das perguntas e configurações do Quiz (integração IA, dificuldade, tempo de resposta).
- **Gestão de Tokens:** Controle da economia do jogo (custo da raspadinha, recompensas, bônus e venda de pacotes).
- **Gestão de Prêmios:** Cadastro de prêmios disponíveis no catálogo (Pix, Camisas, Cupons, etc) e a definição das probabilidades.
- **Integrações e API:** Gerenciamento de chaves (ex: API-Football, Mercado Pago, chave da API do **Google Gemini**).
- **Histórico e Ganhadores:** Acompanhamento dos usuários que ganharam prêmios físicos ou digitais, além do status de entrega.

## 3. Tela Principal (Home / Placares Ao Vivo)

- O aplicativo exibe as partidas em andamento.
- Durante a partida, o usuário acompanha o tempo e eventos importantes.
- **Gatilhos (Eventos):** Quando ocorre um evento relevante na partida ao vivo (ex: Gol, Fim do Primeiro Tempo, Cartões), o backend gera um evento que aciona um **Quiz Relâmpago** para os usuários conectados.

## 4. Dinâmica do Quiz e Tokens (Motor Gemini)

- **Geração do Quiz (Inteligência Artificial):** O backend utiliza a API do **Google Gemini** para gerar perguntas de múltipla escolha exclusivas baseadas no contexto da partida em tempo real. O modelo elabora a pergunta, 4 opções e a resposta correta de forma inteligente, armazenando os dados no Firestore.
- **Quiz ao Vivo e Segurança:** Ao ser notificado do evento na partida, o usuário vê a pergunta e as opções geradas pelo Gemini. Para garantir a segurança e evitar fraudes (ou custos altos de API), a conferência da resposta é feita localmente no backend comparando o índice selecionado com o índice correto previamente salvo no banco de dados. O Gemini não é chamado novamente para validar a resposta do usuário.
- **Recompensa em Tokens:** Se o usuário responder corretamente (dentro da janela de tempo/tentativas), ele ganha uma quantidade pré-configurada de **Tokens Virtuais**. Um controle interno impede que o mesmo usuário ganhe tokens mais de uma vez para o mesmo quiz.
- **Loja de Tokens (Opcional):** Usuários que desejam mais tentativas sem aguardar as partidas podem adquirir pacotes de Tokens (via Pix / In-App Purchase).

## 5. O Jogo (A Raspadinha)

- **Custo da Raspadinha:** Para jogar, o usuário precisa gastar uma quantidade pré-determinada de seus Tokens acumulados (Ex: 50 Tokens por jogada).
- **Mecânica:** O usuário "esfrega" o dedo na tela para remover a tinta prateada da raspadinha ou clica no botão para descobrir o resultado rapidamente.
- **Grid Oculto:** O painel revela 9 espaços. O resultado é calculado via Motor de Probabilidades (RNG), de acordo com os prêmios configurados no painel admin.
- **Condição de Vitória:** O usuário ganha ao alinhar combinações específicas (ex: 3 Bolas de Futebol iguais revelam o prêmio máximo). Do contrário, revela ícones variados de "tente novamente".

## 6. Loja de Prêmios e Resgate

- **Vitrine de Prêmios:** Os prêmios (Pix, físicas como camisas ou chuteiras, e cupons digitais) ficam expostos no aplicativo.
- Ao ganhar um prêmio físico, o usuário preenche o seu endereço diretamente no app e o processo passa para análise e envio pela equipe admin.
- Ao ganhar Pix ou prêmio digital, a transferência ou disponibilização do voucher ocorre após verificação de segurança no painel admin.
