# Funcionalidades do App "Raspadinha do Gol"

Este documento descreve todas as funcionalidades e regras de negócio presentes no aplicativo móvel e seu respectivo backend (Firebase).

## 1. Autenticação e Usuários

- **Login com Google:** O usuário deve obrigatoriamente fazer login usando a sua conta do Gmail para acessar o aplicativo.
- **Sistema de Perfis (Roles):** Existem dois tipos de usuário no sistema: `user` (padrão) e `admin`. Essa regra é gravada diretamente na base de dados (Firestore).

## 2. Painel Administrativo (Acesso Restrito)

Apenas usuários com a role `admin` podem acessar a tela `/admin`. Esta tela possui duas sessões principais:

- **Configurações de Integração:** O admin pode alterar dinamicamente (em tempo real) as chaves de API:
  - API-Football (Para gatilhos das partidas ao vivo).
  - Mercado Pago (Para transações Pix de compra e premiação).
  - Z-API (Para disparos e notificações).
- **Regras de Premiação (Sistema de Lotes):** O admin define as probabilidades e o caixa do sorteio configurando:
  - **Valor do Prêmio:** (Ex: R$ 50,00).
  - **Quantidade de Prêmios:** Total disponível para distribuir (Ex: 10 prêmios).
  - **Tamanho do Lote:** Qual a probabilidade fixa. (Ex: Um lote de 100 significa que a cada 100 jogadas, 1 usuário aleatório dentro desse grupo de 100 ganhará obrigatoriamente).

## 3. Tela Principal (Home / Placares Ao Vivo)

- O aplicativo consome a **api-football** (de forma simulada/escutada) para trazer informações sobre uma partida selecionada em tempo real (Home Score, Away Score, Tempo Decorrido e Status).
- **Bloqueio Padrão:** O botão de jogar ("Jogar Agora") permanece inativo exibindo "Aguardando próximo lance...".
- **Liberação (Gatilhos):** A raspadinha é ativada APENAS se houver uma mudança de status chave no jogo. Exemplos: Saída de um Gol, Intervalo de jogo (Halftime) e Fim de jogo (Fulltime).

## 4. O Jogo (A Raspadinha)

- **Mecânica Híbrida:** O usuário pode "esfregar" o dedo na tela para remover a tinta prateada da raspadinha ou, se estiver sem tempo, clicar no botão **"Revelar Tudo Rapidão"** para descobrir instantaneamente.
- **Visualização Oculta:** Atrás da capa da raspadinha (que pode exibir o logo de um patrocinador), existe um grid de 3x3 com 9 espaços.
- **Condição de Vitória:** O algoritmo do jogo avalia se a raspadinha atual foi a premiada pelo _Sistema de Lotes_. Se sim, o grid revelará 3 "Bolas de Futebol". Do contrário, revelará ícones incorretos.
- **Feedback Visual:** Caso seja vitorioso, confetes saltam na tela e o usuário recebe um alerta de que ganhou.

## 5. Monetização e Transações Financeiras

- **Jogada Gratuita:** A primeira jogada que o usuário realiza em uma partida (no primeiro evento que ocorrer) é gratuita.
- **Pagamento para Jogar (Microtransação):** Quando o usuário esgota a sua tentativa grátis em uma partida e ocorre um segundo evento (ex: sai um novo gol), o app o direciona para a Tela de Checkout.
- **Checkout via Pix:** A tela mostra a chave Pix (Copia e Cola). O usuário deve pagar **R$ 1,00** para desbloquear uma nova raspadinha.
- **Saque de Prêmios:** O saldo ganho nas raspadinhas fica atrelado ao usuário. Ele pode clicar no saldo, abrir a tela de "Saque", informar a sua chave Pix (CPF, Telefone, E-mail) e solicitar o resgate automático.
