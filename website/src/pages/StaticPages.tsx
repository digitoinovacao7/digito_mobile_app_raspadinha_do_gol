export function Regulamento() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Regulamento Oficial</h1>
      <div className="prose prose-lg max-w-none text-gray-700 space-y-6">
        <p>Bem-vindo ao Regulamento Oficial da <strong>Raspadinha do Gol</strong>. Este documento estabelece as regras e mecânicas de participação na nossa plataforma de entretenimento baseada em eventos esportivos.</p>
        
        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">1. Elegibilidade e Participação</h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>A participação é estritamente restrita a pessoas físicas maiores de 18 (dezoito) anos no momento do cadastro.</li>
          <li>É obrigatório possuir um CPF válido e regular junto à Receita Federal do Brasil.</li>
          <li>Cada usuário poderá manter apenas uma conta ativa na plataforma. Contas duplicadas serão bloqueadas e os prêmios retidos.</li>
          <li>A conta deve estar obrigatoriamente vinculada a uma chave PIX correspondente ao CPF do titular para recebimento de prêmios.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">2. Mecânica do Jogo e Gatilhos de Liberação</h2>
        <p>A Raspadinha do Gol é um jogo de cota fixa e prêmios instantâneos atrelado a partidas de futebol reais transmitidas ou acompanhadas pelo sistema.</p>
        <ul className="list-disc pl-6 space-y-2">
          <li><strong>Liberação de Bilhetes:</strong> O usuário ganha a oportunidade de raspar um bilhete ("Raspadinha") toda vez que um dos seguintes "Gatilhos" ocorrer em uma partida selecionada: Gol marcado, Fim do 1º Tempo (Intervalo) e Fim de Jogo.</li>
          <li><strong>O Grid:</strong> A raspadinha virtual consiste em um grid 3x3 com elementos ocultos.</li>
          <li><strong>Critério de Vitória:</strong> Para ser premiado, o usuário deve revelar, ao "raspar" a tela, exatamente <strong>3 bolas de futebol</strong> (ou símbolo equivalente previamente anunciado) na mesma cartela.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">3. Premiação e Pagamentos</h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>Todos os prêmios anunciados são valores brutos e serão creditados diretamente na carteira digital do usuário na plataforma.</li>
          <li>O saque é realizado exclusivamente via <strong>PIX</strong>, processado em até 10 minutos após a solicitação, desde que a chave cadastrada seja o CPF do titular da conta.</li>
          <li>Não serão realizados pagamentos para contas de terceiros (CPFs divergentes).</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">4. Disposições Gerais</h2>
        <p>A empresa operadora reserva-se o direito de anular bilhetes que resultem de falhas no sistema, bugs, ou fraudes comprovadas. Situações não previstas neste regulamento serão resolvidas pela administração da plataforma, cujas decisões serão soberanas e irrecorríveis.</p>
      </div>
    </div>
  );
}

export function Privacidade() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Política de Privacidade</h1>
      <div className="prose prose-lg max-w-none text-gray-700 space-y-6">
        <p>A <strong>Raspadinha do Gol</strong> está comprometida em proteger a sua privacidade. Esta política está em conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018) e explica como seus dados são coletados e utilizados.</p>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">1. Dados Coletados</h2>
        <p>Coletamos dados estritamente necessários para o funcionamento seguro da plataforma:</p>
        <ul className="list-disc pl-6 space-y-2">
          <li><strong>Dados Cadastrais:</strong> Nome completo, CPF, E-mail, Data de Nascimento e número de telefone.</li>
          <li><strong>Dados Financeiros:</strong> Chave PIX (limitada ao CPF cadastrado) e histórico de transações.</li>
          <li><strong>Dados de Navegação:</strong> Endereço IP, tipo de dispositivo, navegador e logs de acesso por motivos de segurança e prevenção a fraudes.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">2. Uso das Informações</h2>
        <p>Seus dados são utilizados exclusivamente para:</p>
        <ul className="list-disc pl-6 space-y-2">
          <li>Processamento de depósitos, saques e pagamentos de prêmios.</li>
          <li>Verificação de idade (maioridade) e autenticação de identidade.</li>
          <li>Melhoria contínua da sua experiência no aplicativo.</li>
          <li>Envio de comunicações importantes sobre segurança, atualizações e promoções (com opção de <em>opt-out</em>).</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">3. Compartilhamento de Dados</h2>
        <p>A Raspadinha do Gol <strong>não vende ou aluga</strong> seus dados pessoais. Compartilhamos informações apenas com:</p>
        <ul className="list-disc pl-6 space-y-2">
          <li>Provedores de pagamento parceiros autorizados pelo Banco Central para o processamento do PIX.</li>
          <li>Autoridades legais, quando exigido por lei ou ordem judicial.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">4. Seus Direitos</h2>
        <p>Como titular dos dados, você tem o direito de solicitar o acesso, retificação, ou exclusão dos seus dados pessoais da nossa base, bastando entrar em contato com o nosso suporte. Note que a exclusão dos dados pode acarretar no encerramento de sua conta.</p>
      </div>
    </div>
  );
}

export function Termos() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Termos de Uso</h1>
      <div className="prose prose-lg max-w-none text-gray-700 space-y-6">
        <p>Ao utilizar o aplicativo e site da <strong>Raspadinha do Gol</strong>, você concorda expressamente com todos os Termos de Uso aqui descritos. Caso não concorde com qualquer parte destes termos, por favor, não utilize nossos serviços.</p>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">1. Natureza do Serviço</h2>
        <p>A Raspadinha do Gol é uma plataforma de entretenimento digital baseada na mecânica de bilhetes raspáveis (raspadinhas). Não garantimos ganhos financeiros ou rendimentos. Os prêmios são baseados em um sorteio aleatório (RNG - Gerador de Números Aleatórios) no momento da jogada.</p>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">2. Cadastro e Responsabilidade</h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>O cadastro de menores de 18 anos é <strong>terminantemente proibido</strong>. O usuário declara e garante ter capacidade civil plena.</li>
          <li>É responsabilidade do usuário manter a confidencialidade de suas credenciais de acesso (login e senha). Qualquer ação tomada através de sua conta será de sua exclusiva responsabilidade.</li>
          <li>A utilização de <em>bots</em>, scripts automatizados, VPNs para mascarar localidade ou qualquer método de engenharia reversa para fraudar o sistema de raspadinhas resultará no banimento imediato e retenção de fundos.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">3. Transações Financeiras</h2>
        <p>Todas as transações ocorrem em moeda corrente nacional (BRL - Reais). O usuário é o único responsável pelos impostos e tributos incidentes sobre os valores recebidos a título de prêmio, de acordo com a legislação tributária vigente.</p>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">4. Modificações nos Termos</h2>
        <p>Estes termos podem ser atualizados periodicamente para refletir mudanças operacionais ou legais. O uso continuado da plataforma após as alterações constitui sua aceitação tácita das novas regras.</p>
      </div>
    </div>
  );
}

export function JogoResponsavel() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Política de Jogo Responsável</h1>
      <div className="prose prose-lg max-w-none text-gray-700 space-y-6">
        <p>A diversão deve ser o único objetivo ao acessar a <strong>Raspadinha do Gol</strong>. Apostar ou jogar com dinheiro real não deve ser encarado como uma forma de gerar renda ou pagar dívidas.</p>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">Aviso de Risco (+18)</h2>
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <p className="text-red-700 font-bold m-0">A plataforma é estritamente proibida para menores de 18 anos.</p>
          <p className="text-red-700 text-sm mt-2">Jogos de probabilidade podem causar dependência. Jogue com moderação.</p>
        </div>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">Nossas Ferramentas de Proteção</h2>
        <p>Para garantir um ambiente seguro, disponibilizamos as seguintes ferramentas:</p>
        <ul className="list-disc pl-6 space-y-2">
          <li><strong>Limites de Depósito:</strong> O usuário pode definir limites diários, semanais ou mensais de depósitos em sua conta.</li>
          <li><strong>Alertas de Tempo:</strong> Notificações em tela após longos períodos de atividade contínua.</li>
          <li><strong>Pausa (Time-out):</strong> Bloqueio temporário da conta (de 24h a 30 dias), conforme solicitação.</li>
          <li><strong>Autoexclusão:</strong> O usuário pode solicitar a suspensão por tempo indeterminado ou encerramento definitivo da conta através do suporte. Durante esse período, o acesso será negado e não enviaremos e-mails promocionais.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">Dicas para um Jogo Seguro</h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>Jogue apenas o que você pode perder sem afetar seu padrão de vida.</li>
          <li>Estabeleça um limite de tempo e de dinheiro antes de começar.</li>
          <li>Nunca tente "recuperar" perdas com novas compras.</li>
          <li>Se o jogo deixar de ser divertido ou gerar ansiedade, pare imediatamente.</li>
        </ul>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">Precisa de Ajuda?</h2>
        <p>Se você ou alguém que você conhece está enfrentando problemas com jogos, procure ajuda especializada. Recomendamos o portal <a href="https://jogadoresanonimos.com.br" target="_blank" rel="noopener noreferrer" className="text-accent underline font-bold">Jogadores Anônimos do Brasil</a>.</p>
      </div>
    </div>
  );
}

export function SobreNos() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Sobre Nós: Raspadinha do Gol</h1>
      <div className="prose prose-lg max-w-none text-gray-700 space-y-6">
        <p className="text-xl">É com imenso entusiasmo que apresentamos a <strong>Raspadinha do Gol</strong>, uma plataforma inovadora de gamificação focada em fãs de futebol, que une a emoção das partidas ao vivo, testes de conhecimento e prêmios reais.</p>
        
        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">Nosso Propósito</h2>
        <p>No mercado atual, somos bombardeados por inúmeras casas de aposta (Betting), que exigem risco financeiro dos usuários e têm gerado discussões severas sobre vício e regulação. A <strong>Raspadinha do Gol</strong> nasce como uma alternativa saudável, transparente e 100% focada em <strong>habilidade e engajamento</strong>.</p>
        <p>Nós criamos uma experiência Freemium onde <strong>você não aposta o seu dinheiro para jogar</strong>. Você joga com o seu conhecimento esportivo e paixão pelo seu time!</p>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">Como Revolucionamos a Dinâmica</h2>
        <p>O funcionamento é empolgante e sincronizado com a emoção das partidas em tempo real:</p>
        <ol className="list-decimal pl-6 space-y-3">
          <li><strong>O Gatilho:</strong> O torcedor acompanha as partidas de futebol no nosso app. Quando um evento relevante acontece no mundo real (um gol, um cartão amarelo, o intervalo do jogo), o app reage instantaneamente.</li>
          <li><strong>O Quiz Relâmpago:</strong> Uma pergunta de conhecimentos gerais sobre futebol ou sobre a partida aparece na tela, gerada por nossa IA.</li>
          <li><strong>A Recompensa em Tokens:</strong> Os torcedores que respondem corretamente e rapidamente são recompensados com nossa moeda virtual: os Tokens.</li>
          <li><strong>O Grande Prêmio:</strong> Com esses Tokens, o usuário joga a tradicional "Raspadinha do Gol" para concorrer a recompensas físicas (Camisas de Time Oficiais), cupons de desconto ou até transferências via PIX.</li>
        </ol>

        <h2 className="text-2xl font-bold text-primary mt-8 mb-4">A Oportunidade</h2>
        <p>Convidamos você a fazer parte dessa revolução gamificada. A Raspadinha do Gol converte a audiência passiva dos jogos de futebol em participantes ativos e engajados, trazendo retenção e a chance de transformar o Brasil em líder no modelo ético de "Play-to-Earn" de conhecimento.</p>
      </div>
    </div>
  );
}
