import { Link } from 'react-router-dom';
import { useState } from 'react';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';

export function Regulamento() {
  return (
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Regulamento Oficial</h1>
        <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 md:p-10 rounded-3xl text-emerald-100/85 space-y-6 leading-relaxed">
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
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Política de Privacidade</h1>
        <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 md:p-10 rounded-3xl text-emerald-100/85 space-y-6 leading-relaxed">
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
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Termos de Uso</h1>
        <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 md:p-10 rounded-3xl text-emerald-100/85 space-y-6 leading-relaxed">
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
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Política de Jogo Responsável</h1>
        <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 md:p-10 rounded-3xl text-emerald-100/85 space-y-6 leading-relaxed">
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
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl md:text-5xl font-black text-amber-400 mb-8 tracking-tight">Sobre Nós: Raspadinha do Gol</h1>
        <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 md:p-10 rounded-3xl text-emerald-100/85 space-y-6 leading-relaxed">
          <p className="text-lg text-white">É com imenso entusiasmo que apresentamos a <strong>Raspadinha do Gol</strong>, uma plataforma inovadora de gamificação focada em fãs de futebol, que une a emoção das partidas ao vivo, testes de conhecimento e prêmios reais.</p>
          
          <h2 className="text-2xl font-bold text-emerald-400 mt-8 mb-4">Nosso Propósito</h2>
          <p>A <strong>Raspadinha do Gol</strong> nasce como uma alternativa saudável, transparente e 100% focada em <strong>habilidade e engajamento</strong>.</p>
          <p>Nós criamos uma experiência 100% gratuita onde <strong>você não precisa pagar para jogar</strong>. Você joga com o seu conhecimento esportivo e paixão pelo seu time!</p>
        </div>
      </div>
    </div>
  );
}

export function Suporte() {
  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [descricao, setDescricao] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [sentSuccess, setSentSuccess] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!nome.trim() || !email.trim() || !descricao.trim()) {
      setErrorMessage('Por favor, preencha seu nome, e-mail e a descrição do seu chamado.');
      return;
    }

    setIsSubmitting(true);
    try {
      await addDoc(collection(db, 'support_tickets'), {
        nome: nome.trim(),
        email: email.trim(),
        descricao: descricao.trim(),
        status: 'aberto',
        createdAt: serverTimestamp(),
        origem: 'website',
      });
      setSentSuccess(true);
      setNome('');
      setEmail('');
      setDescricao('');
    } catch (err: any) {
      console.error('Erro ao enviar chamado de suporte:', err);
      setErrorMessage('Falha ao enviar a mensagem. Verifique sua conexão ou tente novamente.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20">
      <div className="max-w-2xl mx-auto px-4">
        <div className="text-center mb-8">
          <span className="bg-amber-400/15 text-amber-300 border border-amber-400/30 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider inline-block mb-3">
            Atendimento ao Torcedor
          </span>
          <h1 className="text-3xl md:text-5xl font-black text-white tracking-tight">
            Suporte Raspadinha do Gol
          </h1>
          <p className="text-emerald-100/75 max-w-lg mx-auto mt-2 text-sm md:text-base">
            Envie sua dúvida, elogio ou solicitação de atendimento. Nossa equipe responde direto no seu e-mail!
          </p>
        </div>

        {/* Card do Formulário Branco de Alto Contraste */}
        <div className="bg-white text-gray-900 border border-gray-100 p-8 sm:p-10 rounded-3xl shadow-2xl">
          {sentSuccess ? (
            <div className="text-center py-8 space-y-4">
              <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center text-3xl mx-auto shadow-md">
                ✓
              </div>
              <h3 className="text-2xl font-black text-gray-950">
                Mensagem Enviada com Sucesso!
              </h3>
              <p className="text-gray-600 text-sm max-w-md mx-auto leading-relaxed">
                Recebemos seu chamado de suporte. Nossa equipe irá analisar e responder o mais breve possível no e-mail informado.
              </p>
              <button
                type="button"
                onClick={() => setSentSuccess(false)}
                className="mt-4 bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-sm px-6 py-3 rounded-xl transition-all cursor-pointer shadow"
              >
                Enviar Outro Chamado
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              {errorMessage && (
                <div className="p-4 bg-red-50 border border-red-200 text-red-700 text-xs font-bold rounded-xl flex items-center gap-2">
                  <span>⚠️</span> {errorMessage}
                </div>
              )}

              <div>
                <label className="block text-xs font-bold uppercase text-gray-700 mb-2">
                  Seu Nome Completo *
                </label>
                <input
                  type="text"
                  required
                  value={nome}
                  onChange={(e) => setNome(e.target.value)}
                  placeholder="Ex: Carlos Eduardo da Silva"
                  className="w-full px-4 py-3.5 rounded-xl border border-gray-300 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 text-gray-900 placeholder-gray-400 text-sm outline-none transition-all bg-gray-50/50"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase text-gray-700 mb-2">
                  Seu E-mail para Contato *
                </label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Ex: seuemail@gmail.com"
                  className="w-full px-4 py-3.5 rounded-xl border border-gray-300 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 text-gray-900 placeholder-gray-400 text-sm outline-none transition-all bg-gray-50/50"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase text-gray-700 mb-2">
                  Descrição do Problema ou Dúvida *
                </label>
                <textarea
                  required
                  rows={4}
                  value={descricao}
                  onChange={(e) => setDescricao(e.target.value)}
                  placeholder="Descreva detalhadamente sua dúvida, problema com prêmio, bolão ou sugestão..."
                  className="w-full px-4 py-3.5 rounded-xl border border-gray-300 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 text-gray-900 placeholder-gray-400 text-sm outline-none transition-all bg-gray-50/50 resize-y"
                />
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 hover:from-amber-300 hover:to-amber-400 text-[#03150b] font-black text-sm py-4 px-6 rounded-2xl shadow-lg transition-all hover:scale-[1.01] uppercase tracking-wide cursor-pointer disabled:opacity-50"
              >
                {isSubmitting ? 'Gravando Chamado...' : '📩 Enviar Mensagem para o Suporte'}
              </button>
            </form>
          )}
        </div>

        {/* Informações rápidas de rodapé */}
        <div className="mt-8 text-center text-xs text-emerald-200/70 space-y-1">
          <p>E-mail direto da administração: <a href="mailto:contato@digitoinovacao.com.br" className="text-amber-300 underline font-semibold">contato@digitoinovacao.com.br</a></p>
          <p>Dúvidas frequentes sobre camisas oficiais e envio de prêmios? <Link to="/faq" className="text-emerald-300 underline">Acesse o FAQ</Link></p>
        </div>
      </div>
    </div>
  );
}
