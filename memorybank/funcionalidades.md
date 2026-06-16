# Funcionalidades do App "Raspadinha do Gol"

Este documento descreve todas as funcionalidades e regras de negócio presentes no aplicativo móvel e seu respectivo backend (Firebase).

## 1. Autenticação e Usuários

- **Login com Google:** O usuário deve obrigatoriamente fazer login usando a sua conta do Gmail para acessar o aplicativo.
- **Sistema de Perfis (Roles):** Existem dois tipos de usuário no sistema: `user` (padrão) e `admin`. Essa regra é gravada diretamente na base de dados (Firestore).

## 2. Painel Administrativo (Acesso Restrito)

Apenas usuários com a role `admin` podem acessar a tela de Painel Administrativo, que fica disponível diretamente na Barra de Navegação Inferior (Bottom Navigation Bar). Esta tela permite gerenciar diversas áreas do app:

- **Integrações e API:** Gerenciamento de chaves (ex: API-Football, Mercado Pago, Z-API para WhatsApp, e chave da API do **Google Gemini**).
- **Regras de Economia:** Controle da economia do jogo, incluindo o custo da raspadinha em tokens, a recompensa em tokens por acerto no quiz, e a **taxa de conversão de Tokens para Dinheiro Real (PIX)** (ex: definir que 100 Tokens = R$ 1,00).
- **Gestão de Prêmios:** Cadastro de prêmios (Pix, Camisas, etc). O admin define a **Probabilidade** de o prêmio sair na raspadinha (ex: 1 a cada 1000) e o **Custo na Loja** em Tokens (para resgate direto sem raspadinha). Também é possível definir se o prêmio é Global, para um Campeonato específico ou para uma Partida específica.
- **Histórico e Ganhadores (Futuro/Planejado):** Acompanhamento dos usuários que ganharam prêmios físicos ou digitais, além do status de entrega.

## 3. Tela Principal (Home / Placares Ao Vivo)

- O aplicativo exibe as partidas em andamento.
- Durante a partida, o usuário acompanha o tempo e eventos importantes.
- **Gatilhos (Eventos):** Quando ocorre um evento relevante na partida ao vivo (ex: Gol, Fim do Primeiro Tempo, Cartões), o backend gera um evento que aciona um **Quiz Relâmpago** para os usuários conectados.

## 4. Dinâmica do Quiz e Tokens (Motor Gemini)

- **Geração do Quiz (Inteligência Artificial):** O backend utiliza a API do **Google Gemini** para gerar perguntas de múltipla escolha exclusivas baseadas no contexto da partida em tempo real. O modelo elabora a pergunta, 4 opções e a resposta correta de forma inteligente, armazenando os dados no Firestore.
- **Quiz ao Vivo e Segurança:** Ao ser notificado do evento na partida, o usuário vê a pergunta e as opções geradas pelo Gemini. Para garantir a segurança e evitar fraudes (ou custos altos de API), a conferência da resposta é feita localmente no backend comparando o índice selecionado com o índice correto previamente salvo no banco de dados. O Gemini não é chamado novamente para validar a resposta do usuário.
- **Recompensa em Tokens:** Se o usuário responder corretamente (dentro da janela de tempo/tentativas), ele ganha uma quantidade pré-configurada de **Tokens Virtuais**. Um controle interno impede que o mesmo usuário ganhe tokens mais de uma vez para o mesmo quiz.

## 5. O Jogo (A Raspadinha)

- **Custo da Raspadinha:** Para jogar, o usuário precisa gastar uma quantidade pré-determinada de seus Tokens acumulados (Ex: 1000 Tokens por jogada, definido pelo Admin).
- **Mecânica:** O usuário "esfrega" o dedo na tela para remover a tinta prateada da raspadinha ou clica no botão para descobrir o resultado rapidamente.
- **Grid Oculto:** O painel revela 9 espaços. O resultado é calculado via Motor de Probabilidades (RNG), de acordo com as probabilidades dos prêmios configurados no painel admin.
- **Condição de Vitória:** O usuário ganha ao alinhar combinações específicas (ex: 3 imagens iguais do prêmio). Do contrário, revela ícones variados de "tente novamente".

## 6. Carteira, Loja de Prêmios e Resgate

- **Carteira e Saque PIX:** O usuário acessa sua carteira tocando no saldo de Tokens na barra superior. Na carteira, ele pode ver a conversão direta de seus Tokens para dinheiro real (com base na taxa configurada no Painel Admin) e solicitar um saque via PIX instantâneo informando sua chave.
- **Loja de Prêmios (Resgate Físico):** Além do saque PIX, a vitrine de prêmios exibe produtos físicos (ex: camisas, chuteiras). Se o usuário acumular Tokens suficientes (definido pelo admin no "Custo na Loja"), ele pode resgatar o prêmio diretamente, sem precisar tentar a sorte na raspadinha.
- **Cadastro Completo:** Para resgatar prêmios físicos, o aplicativo exige que o usuário complete o seu perfil com CPF e Telefone.
- **Processamento:** Ao ganhar ou resgatar um prêmio físico, o processo passa para análise e envio pela equipe admin, que entrará em contato (via WhatsApp, por exemplo). Para PIX, a liberação/integração ocorre conforme regras de segurança.