import { Link } from "react-router-dom";
import { useState, useEffect } from "react";
import { PrizesSlider } from "../components/PrizesSlider";
import { DemoScratchcard } from "../components/DemoScratchcard";
import { SponsorsSection } from "../components/SponsorsSection";

const heroImages = [
  "/hero-football.png?v=2",
  "/stadium_crowd.png",
  "/player_kicking.png",
];

interface LiveMatchItem {
  id: number | string;
  league: string;
  leagueLogo?: string;
  country?: string;
  round?: string;
  homeTeam: string;
  homeLogo?: string;
  awayTeam: string;
  awayLogo?: string;
  score: string;
  halfTimeScore?: string | null;
  status: string;
  statusLong?: string;
  isLive?: boolean;
  isFinished?: boolean;
  kickoff?: string | null;
  venue?: string;
  city?: string;
  referee?: string;
}

export function Home() {
  const [currentImage, setCurrentImage] = useState(0);
  const [matches, setMatches] = useState<LiveMatchItem[]>([]);
  const [matchesState, setMatchesState] = useState<"loading" | "success" | "error">("loading");

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImage((prev) => (prev + 1) % heroImages.length);
    }, 5000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    const matchesUrl =
      "https://southamerica-east1-raspadinhadogol.cloudfunctions.net/getPublicMatches";

    async function loadMatches() {
      try {
        const res = await fetch(matchesUrl, { signal: controller.signal });
        if (!res.ok) throw new Error("Não foi possível carregar os jogos.");
        const data = await res.json();
        if (data.success && Array.isArray(data.matches)) {
          setMatches(data.matches);
          setMatchesState("success");
          return;
        }
        throw new Error("Resposta inválida do serviço de jogos.");
      } catch (error: any) {
        if (error.name !== "AbortError") setMatchesState("error");
      }
    }

    loadMatches();
    return () => controller.abort();
  }, []);

  return (
    <div className="w-full bg-slate-950 text-white font-sans overflow-hidden">
      {/* 1. HERO SECTION */}
      <section className="relative w-full pt-28 pb-10 px-4 md:px-8 flex items-center justify-center overflow-hidden">
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
                href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-slate-950 text-xl font-black px-8 py-4 rounded-2xl shadow-[0_0_35px_rgba(251,191,36,0.6)] hover:scale-105 transition-all duration-300 text-center uppercase tracking-wide border border-amber-300/50"
              >
                📱 BAIXAR NA PLAY STORE
              </a>
              <Link
                to="/como-funciona"
                onClick={() => window.scrollTo(0, 0)}
                className="w-full sm:w-auto bg-slate-900/80 border border-white/20 text-white text-lg font-bold px-8 py-4 rounded-2xl hover:bg-white/10 hover:border-white/40 transition-all text-center backdrop-blur-md cursor-pointer"
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

      {/* 2. SPONSORS BAR */}
      <SponsorsSection />

      {/* 3. LIVE MATCH SIMULATOR / API-FOOTBALL REAL TIME SECTION */}
      <section className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-bold px-3 py-1.5 rounded-full uppercase tracking-wider inline-flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            Dados oficiais da API-Football
          </span>
          <h2 className="text-3xl md:text-4xl font-black text-white mt-3">
            Jogos de Hoje & Partidas Ao Vivo
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto mt-2 text-base">
            Enquanto a bola rola nos campeonatos, nosso sistema detecta os lances e envia oportunidades de raspar diretamente para o seu celular.
          </p>
        </div>

        {matchesState === "loading" && (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6" aria-label="Carregando jogos">
            {[0, 1, 2].map((item) => (
              <div key={item} className="h-72 rounded-3xl bg-slate-900/80 border border-slate-800 animate-pulse" />
            ))}
          </div>
        )}

        {matchesState === "error" && (
          <div className="rounded-3xl border border-amber-400/20 bg-amber-400/5 p-8 text-center">
            <p className="font-bold text-amber-300">Os dados dos jogos estão temporariamente indisponíveis.</p>
            <p className="text-sm text-gray-400 mt-2">Tente novamente em alguns minutos.</p>
          </div>
        )}

        {matchesState === "success" && matches.length === 0 && (
          <div className="rounded-3xl border border-slate-800 bg-slate-900/60 p-8 text-center">
            <p className="font-bold text-white">Nenhuma partida encontrada para hoje.</p>
            <p className="text-sm text-gray-400 mt-2">A programação é atualizada automaticamente pela API-Football.</p>
          </div>
        )}

        {matchesState === "success" && matches.length > 0 && (
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {matches.map((match, idx) => (
            <div
              key={match.id || idx}
              className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 relative overflow-hidden shadow-xl hover:border-emerald-500/40 transition-all flex flex-col justify-between"
            >
              <div className="flex justify-between items-center text-xs text-gray-400 font-bold mb-4 border-b border-slate-800 pb-3">
                <span className="uppercase tracking-wider truncate max-w-[170px] flex items-center gap-2">
                  {match.leagueLogo && <img src={match.leagueLogo} alt="" className="w-5 h-5 object-contain" />}
                  {match.league}
                </span>
                <span className={`font-black flex items-center gap-1.5 ${match.isLive ? 'text-emerald-400 animate-pulse' : 'text-amber-400'}`}>
                  {match.isLive && <span className="w-2 h-2 rounded-full bg-emerald-400" />}
                  {match.status}
                </span>
              </div>

              <div className="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-3 my-4">
                <div className="flex min-w-0 flex-col items-center text-center">
                  {match.homeLogo ? (
                    <img src={match.homeLogo} alt={match.homeTeam} className="w-10 h-10 object-contain mb-2" />
                  ) : (
                    <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center font-bold text-xs mb-2">⚽</div>
                  )}
                  <span className="text-sm font-black text-white line-clamp-2">{match.homeTeam}</span>
                </div>

                <div className="text-center">
                  <span className="inline-flex min-w-[4.5rem] items-center justify-center whitespace-nowrap text-xl font-black text-amber-400 bg-slate-950 px-3 py-2 rounded-xl border border-slate-800">
                    {match.score}
                  </span>
                </div>

                <div className="flex min-w-0 flex-col items-center text-center">
                  {match.awayLogo ? (
                    <img src={match.awayLogo} alt={match.awayTeam} className="w-10 h-10 object-contain mb-2" />
                  ) : (
                    <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center font-bold text-xs mb-2">⚽</div>
                  )}
                  <span className="text-sm font-black text-white line-clamp-2">{match.awayTeam}</span>
                </div>
              </div>

              <div className="mt-4 pt-4 border-t border-slate-800 grid grid-cols-2 gap-x-3 gap-y-2 text-xs">
                <div>
                  <span className="block text-gray-500 uppercase font-bold">Competição</span>
                  <span className="text-gray-300">{[match.country, match.round].filter(Boolean).join(" • ") || "—"}</span>
                </div>
                <div>
                  <span className="block text-gray-500 uppercase font-bold">Estádio</span>
                  <span className="text-gray-300">{[match.venue, match.city].filter(Boolean).join(", ") || "A definir"}</span>
                </div>
                {match.halfTimeScore && (
                  <div>
                    <span className="block text-gray-500 uppercase font-bold">Intervalo</span>
                    <span className="text-gray-300">{match.halfTimeScore}</span>
                  </div>
                )}
                {match.referee && (
                  <div>
                    <span className="block text-gray-500 uppercase font-bold">Árbitro</span>
                    <span className="text-gray-300">{match.referee}</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
        )}
      </section>

      {/* 4. SLIDER DE PRÊMIOS */}
      <section className="w-full">
        <PrizesSlider />
      </section>

      {/* 5. COMO FUNCIONA (PASSO A PASSO Visual) */}
      <section id="como-funciona" className="py-20 px-4 max-w-6xl mx-auto">
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



      {/* 6. FINAL CTA BANNER */}
      <section className="py-20 px-4 text-center bg-gradient-to-r from-emerald-950 via-slate-900 to-emerald-950 border-t border-emerald-500/20 relative">
        <div className="max-w-4xl mx-auto relative z-10">
          <h2 className="text-3xl sm:text-5xl font-black text-white mb-6">
            Pronto para testar sua paixão pelo futebol?
          </h2>
          <p className="text-lg text-gray-300 mb-8 max-w-xl mx-auto">
            Junte-se a milhares de torcedores, acompanhe seu time e conquiste prêmios oficiais hoje mesmo.
          </p>
          <a
            href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-slate-950 text-xl font-black px-10 py-5 rounded-2xl shadow-[0_0_40px_rgba(251,191,36,0.6)] hover:scale-105 transition-all duration-300 uppercase tracking-wide"
          >
            BAIXAR APP NA PLAY STORE
          </a>
        </div>
      </section>
    </div>
  );
}
