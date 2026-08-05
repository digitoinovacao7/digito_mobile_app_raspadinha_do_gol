export function Regulamento() {
  return (
    <div className="w-full bg-slate-950 text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Regulamento Oficial</h1>
        <div className="bg-slate-900/60 border border-slate-800 p-8 md:p-10 rounded-3xl text-gray-300 space-y-6 leading-relaxed">
          <p>Bem-vindo ao Regulamento Oficial da <strong>Raspadinha do Gol</strong>. Este documento estabelece as regras e mecânicas de participação na nossa plataforma de entretenimento baseada em eventos esportivos.</p>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">1. Elegibilidade e Participação</h2>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li>A participação é estritamente restrita a pessoas físicas maiores de 18 (dezoito) anos no momento do cadastro.</li>
            <li>É obrigatório possuir um CPF válido e regular junto à Receita Federal do Brasil.</li>
            <li>Cada usuário poderá manter apenas uma conta ativa na plataforma. Contas duplicadas serão bloqueadas e os prêmios retidos.</li>
            <li>A conta deve estar devidamente preenchida com os dados corretos (Telefone e Endereço) para o recebimento de prêmios físicos.</li>
          </ul>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">2. Mecânica do Jogo e Liberação</h2>
          <p>A Raspadinha do Gol é um jogo de entretenimento e prêmios instantâneos atrelado a partidas de futebol reais transmitidas ou acompanhadas pelo sistema.</p>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li><strong>Liberação de Bilhetes:</strong> O usuário ganha a oportunidade de raspar um bilhete ("Raspadinha") toda vez que um dos seguintes "Gatilhos" ocorrer em uma partida selecionada: Gol marcado, Fim do 1º Tempo (Intervalo) e Fim de Jogo.</li>
            <li><strong>O Grid:</strong> A raspadinha virtual consiste em um grid 3x3 com elementos ocultos.</li>
            <li><strong>Critério de Vitória:</strong> Para ser premiado, o usuário deve revelar, ao "raspar" a tela, exatamente <strong>3 bolas de futebol</strong> (ou símbolo equivalente previamente anunciado) na mesma cartela.</li>
          </ul>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">3. Premiação e Entregas</h2>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li>Todos os prêmios anunciados são valores brutos e serão creditados diretamente na carteira digital do usuário na plataforma.</li>
            <li>A entrega de prêmios físicos é realizada após verificação dos dados, podendo levar alguns dias úteis dependendo da sua localidade.</li>
            <li>Não serão realizados pagamentos para contas de terceiros (CPFs divergentes).</li>
          </ul>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">4. Disposições Gerais</h2>
          <p>A empresa operadora reserva-se o direito de anular bilhetes que resultem de falhas no sistema, bugs, ou fraudes comprovadas. Situações não previstas neste regulamento serão resolvidas pela administração da plataforma, cujas decisões serão soberanas e irrecorríveis.</p>
        </div>
      </div>
    </div>
  );
}

export function Privacidade() {
  return (
    <div className="w-full bg-slate-950 text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Política de Privacidade</h1>
        <div className="bg-slate-900/60 border border-slate-800 p-8 md:p-10 rounded-3xl text-gray-300 space-y-6 leading-relaxed">
          <p>A <strong>Raspadinha do Gol</strong> está comprometida em proteger a sua privacidade. Esta política está em conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018) e explica como seus dados são coletados e utilizados.</p>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">1. Dados Coletados</h2>
          <p>Coletamos dados estritamente necessários para o funcionamento seguro da plataforma:</p>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li><strong>Dados Cadastrais:</strong> Nome completo, CPF, E-mail, Data de Nascimento e número de telefone.</li>
            <li><strong>Dados Básicos:</strong> Telefone e endereço para recebimento de prêmios.</li>
            <li><strong>Dados de Navegação:</strong> Endereço IP, tipo de dispositivo, navegador e logs de acesso por motivos de segurança e prevenção a fraudes.</li>
          </ul>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">2. Uso das Informações</h2>
          <p>Seus dados são utilizados exclusivamente para:</p>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li>Processamento e envio de prêmios.</li>
            <li>Verificação de idade (maioridade) e autenticação de identidade.</li>
            <li>Melhoria contínua da sua experiência no aplicativo.</li>
            <li>Envio de comunicações importantes sobre segurança e atualizações.</li>
          </ul>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">3. Compartilhamento de Dados</h2>
          <p>A Raspadinha do Gol <strong>não vende ou aluga</strong> seus dados pessoais. Compartilhamos informações apenas com parceiros logísticos responsáveis pelo envio dos prêmios físicos ou autoridades legais quando exigido por lei.</p>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">4. Seus Direitos</h2>
          <p>Como titular dos dados, você tem o direito de solicitar o acesso, retificação ou exclusão dos seus dados pessoais da nossa base, bastando entrar em contato com o nosso suporte.</p>
        </div>
      </div>
    </div>
  );
}

export function Termos() {
  return (
    <div className="w-full bg-slate-950 text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Termos de Uso</h1>
        <div className="bg-slate-900/60 border border-slate-800 p-8 md:p-10 rounded-3xl text-gray-300 space-y-6 leading-relaxed">
          <p>Ao utilizar o aplicativo e site da <strong>Raspadinha do Gol</strong>, você concorda expressamente com todos os Termos de Uso aqui descritos.</p>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">1. Natureza do Serviço</h2>
          <p>A Raspadinha do Gol é uma plataforma de entretenimento digital baseada na mecânica de bilhetes raspáveis (raspadinhas) e quizzes. Não garantimos ganhos financeiros ou rendimentos.</p>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">2. Cadastro e Responsabilidade</h2>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li>O cadastro de menores de 18 anos é <strong>terminantemente proibido</strong>.</li>
            <li>É responsabilidade do usuário manter a confidencialidade de suas credenciais de acesso.</li>
            <li>A utilização de bots, scripts automatizados ou métodos para fraudar o sistema resultará no banimento imediato.</li>
          </ul>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">3. Modificações nos Termos</h2>
          <p>Estes termos podem ser atualizados periodicamente para refletir mudanças operacionais ou legais.</p>
        </div>
      </div>
    </div>
  );
}

export function JogoResponsavel() {
  return (
    <div className="w-full bg-slate-950 text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Política de Jogo Responsável</h1>
        <div className="bg-slate-900/60 border border-slate-800 p-8 md:p-10 rounded-3xl text-gray-300 space-y-6 leading-relaxed">
          <p>A diversão deve ser o único objetivo ao acessar a <strong>Raspadinha do Gol</strong>. Jogar não deve ser encarado como uma forma de gerar renda ou lucro.</p>

          <div className="bg-amber-400/10 border-l-4 border-amber-400 p-4 rounded-r-xl my-6">
            <p className="text-amber-400 font-bold">A plataforma é estritamente proibida para menores de 18 anos (+18).</p>
            <p className="text-gray-300 text-xs mt-1">Jogos de probabilidade devem ser encarados como entretenimento. Jogue com moderação.</p>
          </div>

          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">Dicas para um Jogo Seguro</h2>
          <ul className="list-disc pl-6 space-y-2 text-gray-300">
            <li>Estabeleça um limite de tempo antes de começar a jogar.</li>
            <li>Se o jogo deixar de ser divertido ou gerar ansiedade, pare imediatamente.</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export function SobreNos() {
  return (
    <div className="w-full bg-slate-950 text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Sobre Nós: Raspadinha do Gol</h1>
        <div className="bg-slate-900/60 border border-slate-800 p-8 md:p-10 rounded-3xl text-gray-300 space-y-6 leading-relaxed">
          <p className="text-lg text-white">É com imenso entusiasmo que apresentamos a <strong>Raspadinha do Gol</strong>, uma plataforma inovadora de gamificação focada em fãs de futebol, que une a emoção das partidas ao vivo, testes de conhecimento e prêmios reais.</p>
          
          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">Nosso Propósito</h2>
          <p>A <strong>Raspadinha do Gol</strong> nasce como uma alternativa saudável, transparente e 100% focada em <strong>habilidade e engajamento</strong>.</p>
          <p>Nós criamos uma experiência 100% gratuita onde <strong>você não precisa pagar para jogar</strong>. Você joga com o seu conhecimento esportivo e paixão pelo seu time!</p>
        </div>
      </div>
    </div>
  );
}
