import { Link } from "react-router-dom";
import { useState, useEffect } from "react";
import { PrizesSlider } from "../components/PrizesSlider";
import { DemoScratchcard } from "../components/DemoScratchcard";

const heroImages = [
  "/hero-football.png?v=2",
  "/stadium_crowd.png",
  "/player_kicking.png",
];

const liveMatchesMock = [
  {
    league: "Brasileirão Série A",
    homeTeam: "Flamengo",
    awayTeam: "Palmeiras",
    score: "2 - 1",
    minute: "78'",
    status: "EM ANDAMENTO",
    event: "GOL DA RODADA! RASPADINHA DISPONÍVEL ⚽",
  },
  {
    league: "Copa Libertadores",
    homeTeam: "Atlético-MG",
    awayTeam: "River Plate",
    score: "1 - 0",
    minute: "45+2'",
    status: "INTERVALO",
    event: "QUIZ DA IA LIBERADO! +250 TOKENS 🧠",
  },
];

const faqs = [
  {
    question: "O Raspadinha do Gol é pago ou é casa de apostas?",
    answer:
      "Não! O Raspadinha do Gol é 100% gratuito e não envolve apostas em dinheiro. É um jogo de entretenimento e habilidade onde você responde perguntas sobre futebol, ganha tokens e concorrem a prêmios reais entregues na sua casa.",
  },
  {
    question: "Como funcionam as raspadinhas ao vivo?",
    answer:
      "Durante os jogos dos principais campeonatos, sempre que sai um gol, o jogo vai para o intervalo ou termina, o aplicativo libera raspadinhas especiais instantâneas. Basta abrir o app e raspar!",
  },
  {
    question: "Como recebo os prêmios que ganho?",
    answer:
      "Prêmios físicos (como camisas oficiais e bolas) são entregues diretamente no seu endereço via Correios ou Transportadora sem custo. Prêmios digitais ou valores de PIX são enviados diretamente pelo WhatsApp cadastrado.",
  },
  {
    question: "O que são os Quizzes da IA?",
    answer:
      "Nossa Inteligência Artificial analisa os lances do jogo em tempo real e faz perguntas interativas sobre a partida. Acertando os palpites e curiosidades, você ganha Tokens do Gol para resgatar mais raspadinhas e prêmios na loja.",
  },
];

export function Home() {
  const [currentImage, setCurrentImage] = useState(0);
  const [activeFaqIndex, setActiveFaqIndex] = useState<number | null>(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImage((prev) => (prev + 1) % heroImages.length);
    }, 5000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="w-full bg-slate-950 text-white font-sans overflow-hidden">
      {/* 1. HERO SECTION */}
      <section className="relative w-full min-h-[92vh] pt-32 pb-20 px-4 md:px-8 flex items-center justify-center overflow-hidden">
        {/* Background Images Slider with Smooth Blur */}
        {heroImages.map((img, index) => (
          <img
            key={index}
            src={img}
            alt={`Background Hero ${index + 1}`}
            className={`absolute inset-0 w-full h-full object-cover z-0 transition-opacity duration-1000 ${
              index === currentImage ? "opacity-35 scale-105" : "opacity-0"
            }`}
          />
        ))}

        {/* Dynamic Dark Gradients Overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-slate-950/80 via-slate-950/90 to-slate-950 z-0" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-emerald-900/20 via-transparent to-transparent z-0 pointer-events-none" />

        <div className="relative z-10 max-w-7xl mx-auto grid lg:grid-cols-12 gap-12 items-center w-full">
          {/* Left Column: Headline & Call to Actions */}
          <div className="lg:col-span-7 flex flex-col items-center lg:items-start text-center lg:text-left">
            <div className="inline-flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold px-4 py-2 rounded-full mb-6 uppercase tracking-wider backdrop-blur-md">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
              App Oficial de Futebol & Prêmios Grátis
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black tracking-tight leading-[1.1] mb-6 text-white">
              Seu conhecimento de futebol vale{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-300 via-amber-400 to-amber-500 drop-shadow-[0_0_25px_rgba(251,191,36,0.5)]">
                Prêmios Reais!
              </span>
            </h1>

            <p className="text-lg sm:text-xl text-gray-300 mb-8 max-w-2xl leading-relaxed">
              Acompanhe partidas ao vivo, ganhe raspadinhas instantâneas a cada gol e participe de quizzes com Inteligência Artificial para resgatar camisas oficiais e brindes sem pagar nada.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto">
              <a
                href="https://app-raspadinhadogol.web.app"
                className="w-full sm:w-auto bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-slate-950 text-xl font-black px-8 py-4 rounded-2xl shadow-[0_0_35px_rgba(251,191,36,0.6)] hover:scale-105 transition-all duration-300 text-center uppercase tracking-wide border border-amber-300/50"
              >
                🎮 JOGAR AGORA GRÁTIS
              </a>
              <Link
                to="/como-funciona"
                onClick={() => window.scrollTo(0, 0)}
                className="w-full sm:w-auto bg-slate-900/80 border border-white/20 text-white text-lg font-bold px-8 py-4 rounded-2xl hover:bg-white/10 hover:border-white/40 transition-all text-center backdrop-blur-md"
              >
                Como Funciona
              </Link>
            </div>

            <div className="mt-8 flex items-center gap-6 text-xs text-gray-400 font-medium">
              <span className="flex items-center gap-1.5">
                <svg className="w-4 h-4 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                100% Gratuito
              </span>
              <span className="flex items-center gap-1.5">
                <svg className="w-4 h-4 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Sem Apostas em Dinheiro
              </span>
              <span className="flex items-center gap-1.5">
                <svg className="w-4 h-4 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
                Entrega Garantida
              </span>
            </div>
          </div>

          {/* Right Column: Interactive Demo Scratchcard */}
          <div className="lg:col-span-5 flex justify-center w-full">
            <DemoScratchcard />
          </div>
        </div>
      </section>

      {/* 2. STATS FLOATING BAR */}
      <section className="w-full bg-slate-900 border-y border-slate-800 py-8 px-4">
        <div className="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
          <div className="p-4 bg-slate-950/40 rounded-2xl border border-white/5">
            <span className="block text-3xl md:text-4xl font-black text-emerald-400">+50 MIL</span>
            <span className="text-xs text-gray-400 font-semibold uppercase mt-1">Raspadinhas Entregues</span>
          </div>
          <div className="p-4 bg-slate-950/40 rounded-2xl border border-white/5">
            <span className="block text-3xl md:text-4xl font-black text-amber-400">100%</span>
            <span className="text-xs text-gray-400 font-semibold uppercase mt-1">Gratuito e Sem Risco</span>
          </div>
          <div className="p-4 bg-slate-950/40 rounded-2xl border border-white/5">
            <span className="block text-3xl md:text-4xl font-black text-emerald-400">4.9 ★</span>
            <span className="text-xs text-gray-400 font-semibold uppercase mt-1">Avaliação dos Torcedores</span>
          </div>
          <div className="p-4 bg-slate-950/40 rounded-2xl border border-white/5">
            <span className="block text-3xl md:text-4xl font-black text-amber-400">24/7</span>
            <span className="text-xs text-gray-400 font-semibold uppercase mt-1">Jogos e Quizzes com IA</span>
          </div>
        </div>
      </section>

      {/* 3. LIVE MATCH SIMULATOR SECTION */}
      <section className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-bold px-3 py-1.5 rounded-full uppercase tracking-wider">
            Tempo Real
          </span>
          <h2 className="text-3xl md:text-4xl font-black text-white mt-3">
            Gols ao Vivo = Raspadinhas Instantâneas
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto mt-2 text-base">
            Enquanto a bola rola nos campeonatos, nosso sistema detecta os lances e envia oportunidades de raspar diretamente para o seu celular.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          {liveMatchesMock.map((match, idx) => (
            <div
              key={idx}
              className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 relative overflow-hidden shadow-xl hover:border-emerald-500/40 transition-all"
            >
              <div className="flex justify-between items-center text-xs text-gray-400 font-bold mb-4 border-b border-slate-800 pb-3">
                <span className="uppercase tracking-wider">{match.league}</span>
                <span className="text-emerald-400 font-black animate-pulse flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-400" />
                  {match.status} ({match.minute})
                </span>
              </div>

              <div className="flex justify-between items-center my-4 px-4">
                <span className="text-xl font-black text-white w-1/3 text-left">{match.homeTeam}</span>
                <span className="text-3xl font-black text-amber-400 bg-slate-950 px-4 py-2 rounded-xl border border-slate-800">
                  {match.score}
                </span>
                <span className="text-xl font-black text-white w-1/3 text-right">{match.awayTeam}</span>
              </div>

              <div className="mt-4 bg-emerald-950/60 border border-emerald-500/30 rounded-xl p-3 text-center">
                <span className="text-xs font-black text-emerald-300 uppercase tracking-wide">
                  {match.event}
                </span>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 4. SLIDER DE PRÊMIOS */}
      <section className="w-full">
        <PrizesSlider />
      </section>

      {/* 5. COMO FUNCIONA (PASSO A PASSO Visual) */}
      <section className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-black text-white">
            Como Funciona em 3 Passos Simples
          </h2>
          <p className="text-gray-400 max-w-xl mx-auto mt-2 text-base">
            Qualquer torcedor pode participar sem pagar taxa de inscrição.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-center relative hover:border-amber-400/40 transition-all">
            <div className="w-16 h-16 bg-amber-400/10 border border-amber-400/30 text-amber-400 text-2xl font-black rounded-2xl flex items-center justify-center mx-auto mb-6">
              01
            </div>
            <h3 className="text-xl font-black text-white mb-3">Abra o App & Escolha o Jogo</h3>
            <p className="text-gray-400 text-sm leading-relaxed">
              Acesse o aplicativo web pelo celular ou computador e selecione a partida do seu time no dia.
            </p>
          </div>

          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-center relative hover:border-amber-400/40 transition-all">
            <div className="w-16 h-16 bg-emerald-400/10 border border-emerald-400/30 text-emerald-400 text-2xl font-black rounded-2xl flex items-center justify-center mx-auto mb-6">
              02
            </div>
            <h3 className="text-xl font-black text-white mb-3">Responda aos Quizzes com IA</h3>
            <p className="text-gray-400 text-sm leading-relaxed">
              Responda perguntas geradas pela nossa Inteligência Artificial durante o jogo e acumule Tokens do Gol.
            </p>
          </div>

          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-center relative hover:border-amber-400/40 transition-all">
            <div className="w-16 h-16 bg-amber-400/10 border border-amber-400/30 text-amber-400 text-2xl font-black rounded-2xl flex items-center justify-center mx-auto mb-6">
              03
            </div>
            <h3 className="text-xl font-black text-white mb-3">Raspe & Resgate Prêmios</h3>
            <p className="text-gray-400 text-sm leading-relaxed">
              Raspe nos momentos de Gol ou troque seus Tokens na Loja por camisas oficiais e brindes incríveis.
            </p>
          </div>
        </div>
      </section>

      {/* 6. FAQ ACCORDION SECTION */}
      <section className="py-20 px-4 max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-black text-white">
            Perguntas Frequentes (FAQ)
          </h2>
          <p className="text-gray-400 text-base mt-2">
            Tire todas as suas dúvidas sobre o funcionamento do aplicativo.
          </p>
        </div>

        <div className="space-y-4">
          {faqs.map((faq, index) => {
            const isOpen = activeFaqIndex === index;
            return (
              <div
                key={index}
                className="bg-slate-900/80 border border-slate-800 rounded-2xl overflow-hidden transition-all"
              >
                <button
                  onClick={() => setActiveFaqIndex(isOpen ? null : index)}
                  className="w-full text-left p-6 flex justify-between items-center font-bold text-lg text-white hover:text-amber-400 transition-colors"
                >
                  <span>{faq.question}</span>
                  <span className="text-2xl text-amber-400 ml-4 font-black">
                    {isOpen ? "−" : "+"}
                  </span>
                </button>
                {isOpen && (
                  <div className="px-6 pb-6 text-gray-300 text-sm leading-relaxed border-t border-slate-800/50 pt-4">
                    {faq.answer}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </section>

      {/* 7. FINAL CTA BANNER */}
      <section className="py-20 px-4 text-center bg-gradient-to-r from-emerald-950 via-slate-900 to-emerald-950 border-t border-emerald-500/20 relative">
        <div className="max-w-4xl mx-auto relative z-10">
          <h2 className="text-3xl sm:text-5xl font-black text-white mb-6">
            Pronto para testar sua paixão pelo futebol?
          </h2>
          <p className="text-lg text-gray-300 mb-8 max-w-xl mx-auto">
            Junte-se a milhares de torcedores, acompanhe seu time e conquiste prêmios oficiais hoje mesmo.
          </p>
          <a
            href="https://app-raspadinhadogol.web.app"
            className="inline-block bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-slate-950 text-xl font-black px-10 py-5 rounded-2xl shadow-[0_0_40px_rgba(251,191,36,0.6)] hover:scale-105 transition-all duration-300 uppercase tracking-wide"
          >
            JOGAR AGORA NO APP GRÁTIS
          </a>
        </div>
      </section>
    </div>
  );
}
