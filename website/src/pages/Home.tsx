import { Link } from "react-router-dom";
import { useState, useEffect, useCallback } from "react";
import { PrizesSlider } from "../components/PrizesSlider";
import { DemoScratchcard } from "../components/DemoScratchcard";
import { SponsorsSection } from "../components/SponsorsSection";
import { ShareAppModal } from "../components/ShareAppModal";
import { PrizeModal } from "../components/PrizeModal";

const heroImages = [
  {
    src: "/stadium_maracana.jpg",
    name: "Estádio do Maracanã (Rio de Janeiro)",
    alt: "Estádio do Maracanã em dia de jogo no Raspadinha do Gol",
  },
  {
    src: "/stadium_morumbi.jpg",
    name: "Estádio do Morumbi (São Paulo)",
    alt: "Estádio do Morumbi lotado com a torcida",
  },
  {
    src: "/stadium_arena_mrv.jpg",
    name: "Arena MRV (Belo Horizonte)",
    alt: "Arena MRV em Belo Horizonte",
  },
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

const SHOWCASE_MATCHES: LiveMatchItem[] = [
  {
    id: "showcase-1",
    league: "Brasileirão Série A",
    leagueLogo: "https://crests.football-data.org/764.png",
    country: "Brasil",
    round: "Rodada Principal",
    homeTeam: "Flamengo",
    homeLogo: "https://crests.football-data.org/1783.png",
    awayTeam: "Palmeiras",
    awayLogo: "https://crests.football-data.org/1769.png",
    score: "2 - 1",
    halfTimeScore: "1 - 1",
    status: "RASPADINHA LIBERADA",
    isLive: true,
    venue: "Maracanã",
    city: "Rio de Janeiro",
  },
  {
    id: "showcase-2",
    league: "Brasileirão Série A",
    leagueLogo: "https://crests.football-data.org/764.png",
    country: "Brasil",
    round: "Rodada Principal",
    homeTeam: "Corinthians",
    homeLogo: "https://crests.football-data.org/1779.png",
    awayTeam: "São Paulo",
    awayLogo: "https://crests.football-data.org/1776.png",
    score: "1 - 1",
    halfTimeScore: "1 - 0",
    status: "QUIZ AO VIVO",
    isLive: true,
    venue: "Neo Química Arena",
    city: "São Paulo",
  },
  {
    id: "showcase-3",
    league: "Champions League",
    leagueLogo: "https://crests.football-data.org/CL.png",
    country: "Europa",
    round: "Fase Principal",
    homeTeam: "Real Madrid",
    homeLogo: "https://crests.football-data.org/86.png",
    awayTeam: "Manchester City",
    awayLogo: "https://crests.football-data.org/65.png",
    score: "—",
    halfTimeScore: null,
    status: "HOJE • 16:00",
    isLive: false,
    venue: "Santiago Bernabéu",
    city: "Madrid",
  },
];

const HOME_FAQS = [
  {
    q: "Qual o papel real dos Tokens no aplicativo?",
    a: "Os Tokens do Gol são o sistema de pontos e fidelidade do torcedor — NÃO são apostas nem dinheiro real. Você ganha Tokens gratuitamente acertando quizzes de IA durante os jogos, assistindo a vídeos e vibrando nos gols. Seus Tokens servem exclusivamente para trocar por Prêmios Físicos Reais (camisas oficiais, tênis, bolas, eletrônicos) na Loja de Prêmios e desbloquear raspadinhas extras!",
    badge: "🪙 Papel Real dos Tokens",
  },
  {
    q: "Como são entregues os prêmios e camisas oficiais?",
    a: "Assim que você acumula Tokens do Gol ou acerta 3 símbolos na raspadinha, basta solicitar o resgate direto pelo aplicativo. Todas as camisas oficiais, bolas e brindes são enviados diretamente com código de rastreamento para o seu endereço sem custo de frete!",
    badge: "🎁 Entrega Garantida",
  },
  {
    q: "Como funciona o Bolão do Gol para Galera e Bares?",
    a: "Você escolhe qualquer jogo do dia, define se o bolão é grátis ou com cota (ex: R$ 10) e compartilha o link no WhatsApp. Quem cravar o placar exato leva até 85% do pote da premiação! Bares e organizadores ganham comissão automática de 5% a 10% sobre o pote total.",
    badge: "🏆 Bolão do Gol",
  },
  {
    q: "O aplicativo é realmente 100% grátis e sem apostas?",
    a: "Sim! O Raspadinha do Gol NÃO é uma casa de apostas e não opera odds. Você nunca precisa depositar dinheiro para participar dos quizzes ao vivo, raspar cartelas nos gols ou resgatar seus prêmios patrocinados.",
    badge: "⚽ Sem Apostas",
  },
  {
    q: "Quais campeonatos são cobertos em tempo real?",
    a: "Cobrimos em tempo real o Brasileirão Série A e B, Copa do Brasil, Libertadores, Sul-Americana, Champions League, Premier League, La Liga, Serie A Italiana e jogos da Seleção Brasileira.",
    badge: "🌎 Campeonatos",
  },
];

function TeamCrest({ name, logo }: { name: string; logo?: string }) {
  const [imgError, setImgError] = useState(false);
  const initials = name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase())
    .join("");

  if (!logo || imgError) {
    return (
      <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-emerald-700 to-emerald-950 border border-amber-400/40 flex items-center justify-center font-black text-sm text-amber-300 mb-2 shadow-md">
        {initials || "⚽"}
      </div>
    );
  }

  return (
    <div className="w-12 h-12 rounded-2xl bg-gray-50 p-1.5 flex items-center justify-center mb-2 shadow-sm border border-gray-200">
      <img
        src={logo}
        alt={`Escudo do ${name}`}
        loading="lazy"
        onError={() => setImgError(true)}
        className="w-9 h-9 object-contain"
      />
    </div>
  );
}

function LeagueBadge({ league, logo }: { league: string; logo?: string }) {
  const [imgError, setImgError] = useState(false);

  return (
    <span className="uppercase tracking-wider truncate max-w-[190px] flex items-center gap-2 text-emerald-800 font-extrabold text-xs">
      {logo && !imgError ? (
        <span className="w-5 h-5 rounded bg-gray-100 p-0.5 flex items-center justify-center shrink-0 border border-gray-200">
          <img
            src={logo}
            alt={`Logo ${league}`}
            onError={() => setImgError(true)}
            className="w-4 h-4 object-contain"
          />
        </span>
      ) : (
        <span>🏆</span>
      )}
      <span className="truncate">{league}</span>
    </span>
  );
}

export function Home() {
  const [currentImage, setCurrentImage] = useState(0);
  const [matches, setMatches] = useState<LiveMatchItem[]>(SHOWCASE_MATCHES);
  const [matchesState, setMatchesState] = useState<"loading" | "success">("loading");
  const [isRefreshingMatches, setIsRefreshingMatches] = useState(false);
  const [matchFilter, setMatchFilter] = useState<"brazil" | "live">("brazil");
  const [selectedBolaoMatch, setSelectedBolaoMatch] = useState<string>("Flamengo x Palmeiras");

  // Interactive Bolão Simulator states
  const [bolaoMode, setBolaoMode] = useState<"friends" | "bar">("friends");
  const [entryFee, setEntryFee] = useState<number>(10);
  const [participantsCount, setParticipantsCount] = useState<number>(20);
  const [isHomeShareModalOpen, setIsHomeShareModalOpen] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImage((prev) => (prev + 1) % heroImages.length);
    }, 5000);
    return () => clearInterval(timer);
  }, []);

  const fetchPublicMatches = useCallback(async (signal?: AbortSignal, manual = false) => {
    if (manual) setIsRefreshingMatches(true);
    try {
      const matchesUrl =
        "https://southamerica-east1-raspadinhadogol.cloudfunctions.net/getPublicMatches";
      const res = await fetch(matchesUrl, { signal });
      if (!res.ok) throw new Error("Fallback para vitrine");
      const data = await res.json();
      if (data.success && Array.isArray(data.matches) && data.matches.length > 0) {
        setMatches(data.matches);
        const first = data.matches[0];
        if (first?.homeTeam && first?.awayTeam) {
          setSelectedBolaoMatch(`${first.homeTeam} x ${first.awayTeam}`);
        }
      } else {
        setMatches(SHOWCASE_MATCHES);
      }
    } catch (error: any) {
      if (error?.name !== "AbortError") {
        setMatches((prev) => (prev.length > 0 ? prev : SHOWCASE_MATCHES));
      }
    } finally {
      setMatchesState("success");
      if (manual) setIsRefreshingMatches(false);
    }
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    fetchPublicMatches(controller.signal, false);
    return () => controller.abort();
  }, [fetchPublicMatches]);

  const filteredMatches = matches.filter((m) => {
    if (matchFilter === "live") {
      return Boolean(m.isLive);
    }
    if (matchFilter === "brazil") {
      const text = `${m.league} ${m.country}`.toLowerCase();
      return text.includes("brasil") || text.includes("copa") || text.includes("libertadores");
    }
    return true;
  });

  const displayedMatches = filteredMatches.length > 0 ? filteredMatches : matches;

  // Bolão Simulator math
  const totalPot = entryFee * participantsCount;
  const winnerPct = bolaoMode === "friends" ? 0.85 : 0.80;
  const organizerPct = bolaoMode === "friends" ? 0.05 : 0.10;
  const winnerPrize = totalPot * winnerPct;
  const organizerCommission = totalPot * organizerPct;

  return (
    <div className="w-full bg-[#041d10] text-white font-sans overflow-hidden">
      {/* 1. HERO SECTION */}
      <section className="relative w-full pt-28 pb-16 px-4 md:px-8 flex items-center justify-center overflow-hidden">
        {/* Background Images Slider - Estádios Reais (Maracanã, Morumbi, Arena MRV) */}
        {heroImages.map((img, index) => (
          <img
            key={index}
            src={img.src}
            alt={img.alt}
            loading={index === 0 ? "eager" : "lazy"}
            className={`absolute inset-0 w-full h-full object-cover z-0 transition-opacity duration-1000 ${
              index === currentImage ? "opacity-80 scale-105" : "opacity-0"
            }`}
          />
        ))}

        {/* Gradiente sutil e neutro: destaca os estádios e mantém texto legível */}
        <div className="absolute inset-0 bg-gradient-to-r from-black/80 via-black/55 to-black/25 z-0" />
        <div className="absolute inset-0 bg-gradient-to-t from-[#041d10] via-transparent to-black/50 z-0" />

        {/* Indicador do Estádio Atual */}
        <div className="absolute bottom-3 left-4 sm:left-8 z-10 hidden sm:flex items-center gap-2 bg-black/60 backdrop-blur-md border border-white/20 text-white text-xs font-semibold px-3.5 py-1.5 rounded-full shadow-lg">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>📍 {heroImages[currentImage].name}</span>
        </div>

        <div className="relative z-10 max-w-7xl mx-auto grid lg:grid-cols-12 gap-8 items-center w-full">
          {/* Left Column: Headline, Social Proof & Primary Call to Actions */}
          <div className="lg:col-span-8 flex flex-col items-center lg:items-start text-center lg:text-left">
            <div className="inline-flex items-center gap-2 bg-emerald-500/15 border border-emerald-400/30 text-emerald-300 text-xs font-bold px-3.5 py-1.5 rounded-full mb-5 uppercase tracking-wider backdrop-blur-md">
              <span className="w-2 h-2 rounded-full bg-emerald-400" />
              App Oficial de Futebol & Bolão
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black tracking-tight leading-[1.1] mb-5 text-white">
              Seu conhecimento de futebol vale{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-300 to-amber-500">
                Prêmios Reais!
              </span>
            </h1>

            <p className="text-base sm:text-lg text-emerald-100/80 mb-8 max-w-xl leading-relaxed">
              Quizzes esportivos ao vivo, raspadinhas instantâneas a cada gol e Bolão entre amigos e bares. Fature camisas oficiais, bolas e brindes exclusivos sem apostas.
            </p>

            {/* Primary CTA - Clean & Direct */}
            <div className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto mb-6">
              <a
                href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Baixe Grátis o Aplicativo Raspadinha do Gol na Google Play Store"
                className="w-full sm:w-auto bg-gradient-to-r from-amber-400 to-amber-500 hover:from-amber-300 hover:to-amber-400 text-[#03150b] text-base font-black px-8 py-4 rounded-xl shadow-lg hover:scale-[1.02] transition-all text-center uppercase tracking-wide"
              >
                📲 Baixar na Google Play
              </a>
              <a
                href="#bolao"
                className="w-full sm:w-auto text-emerald-200 hover:text-white border border-emerald-600/50 hover:border-emerald-400 bg-emerald-950/40 text-sm font-bold px-6 py-4 rounded-xl hover:bg-emerald-900/40 transition-all text-center cursor-pointer"
              >
                🏆 Conhecer o Bolão →
              </a>
            </div>

            {/* Clean Social Proof (Single line, no heavy boxed clutter) */}
            <div className="flex items-center gap-3 text-xs text-emerald-200/70 font-medium">
              <span className="text-amber-400 tracking-wider">★★★★★</span>
              <span>Mais de 15.000 torcedores</span>
              <span className="text-emerald-700">•</span>
              <span>100% Gratuito & Seguro</span>
            </div>
          </div>

          {/* Right Column: Interactive Demo Scratchcard */}
          <div className="lg:col-span-4 flex justify-center lg:justify-end w-full">
            <DemoScratchcard />
          </div>
        </div>
      </section>

      {/* 2. SPONSORS BAR */}
      <SponsorsSection />

      {/* 3. JOGOS DE HOJE & PARTIDAS AO VIVO (INTERACTIVE & RESILIENT) */}
      <section id="jogos-hoje" className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-10">
          <span className="bg-emerald-500/15 text-emerald-300 border border-emerald-400/30 text-xs font-bold px-3.5 py-1.5 rounded-full uppercase tracking-wider inline-flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            Cobertura em Tempo Real no Aplicativo
          </span>
          <h2 className="text-3xl md:text-4xl font-black text-white mt-3">
            Jogos de Hoje & Partidas Ao Vivo
          </h2>
          <p className="text-emerald-100/75 max-w-2xl mx-auto mt-2 text-base">
            Enquanto a bola rola nos gramados, nosso sistema libera raspadinhas a cada gol, quizzes com IA e apura automaticamente os vencedores do Bolão!
          </p>

          {/* Filter Pills & Refresh Button */}
          <div className="flex flex-wrap items-center justify-center gap-3 mt-6">
            <button
              type="button"
              onClick={() => setMatchFilter("brazil")}
              className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer border ${
                matchFilter === "brazil"
                  ? "bg-amber-400 text-[#03150b] border-amber-300 shadow-[0_0_15px_rgba(251,191,36,0.4)]"
                  : "bg-[#072917] text-emerald-200 border-emerald-700/60 hover:border-emerald-400/60"
              }`}
            >
              🇧🇷 Brasileirão & Copas
            </button>
            <button
              type="button"
              onClick={() => setMatchFilter("live")}
              className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer border ${
                matchFilter === "live"
                  ? "bg-amber-400 text-[#03150b] border-amber-300 shadow-[0_0_15px_rgba(251,191,36,0.4)]"
                  : "bg-[#072917] text-emerald-200 border-emerald-700/60 hover:border-emerald-400/60"
              }`}
            >
              🔴 Ao Vivo / Destaque
            </button>
            <button
              type="button"
              onClick={() => fetchPublicMatches(undefined, true)}
              disabled={isRefreshingMatches}
              className="px-4 py-2 rounded-xl text-xs font-bold bg-emerald-800/50 hover:bg-emerald-700/60 text-emerald-200 border border-emerald-500/40 transition-all cursor-pointer flex items-center gap-1.5"
            >
              <span className={isRefreshingMatches ? "animate-spin inline-block" : ""}>🔄</span>
              {isRefreshingMatches ? "Atualizando..." : "Atualizar Placares"}
            </button>
          </div>
        </div>

        {matchesState === "loading" ? (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6" aria-label="Carregando jogos de hoje">
            {[0, 1, 2].map((item) => (
              <div key={item} className="h-80 rounded-3xl bg-[#072917]/80 border border-emerald-800/60 animate-pulse" />
            ))}
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {displayedMatches.map((match, idx) => {
              const matchTitle = `${match.homeTeam} x ${match.awayTeam}`;
              return (
                <div
                  key={match.id || idx}
                  className="bg-white text-gray-900 border border-gray-100 rounded-3xl p-6 relative overflow-hidden shadow-xl hover:shadow-2xl transition-all flex flex-col justify-between group"
                >
                  {/* Top Bar: League & Status */}
                  <div className="flex justify-between items-center text-xs font-bold mb-4 border-b border-gray-100 pb-3 gap-2">
                    <LeagueBadge league={match.league} logo={match.leagueLogo} />
                    <span
                      className={`font-black px-2.5 py-1 rounded-full text-[11px] flex items-center gap-1.5 shrink-0 ${
                        match.isLive
                          ? "bg-red-50 text-red-600 border border-red-200 animate-pulse"
                          : "bg-amber-50 text-amber-800 border border-amber-200"
                      }`}
                    >
                      {match.isLive && <span className="w-2 h-2 rounded-full bg-red-500" />}
                      {match.status}
                    </span>
                  </div>

                  {/* Teams & Scoreboard */}
                  <div className="grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-3 my-3">
                    <div className="flex min-w-0 flex-col items-center text-center">
                      <TeamCrest name={match.homeTeam} logo={match.homeLogo} />
                      <span className="text-sm font-black text-gray-950 line-clamp-2 leading-tight">
                        {match.homeTeam}
                      </span>
                    </div>

                    <div className="text-center flex flex-col items-center">
                      <span className="inline-flex min-w-[4.8rem] items-center justify-center whitespace-nowrap text-2xl font-black text-amber-400 bg-gray-950 px-3.5 py-2 rounded-2xl shadow-md">
                        {match.score}
                      </span>
                      {match.halfTimeScore && (
                        <span className="text-[10px] text-gray-500 font-semibold mt-1">
                          1ºT: {match.halfTimeScore}
                        </span>
                      )}
                    </div>

                    <div className="flex min-w-0 flex-col items-center text-center">
                      <TeamCrest name={match.awayTeam} logo={match.awayLogo} />
                      <span className="text-sm font-black text-gray-950 line-clamp-2 leading-tight">
                        {match.awayTeam}
                      </span>
                    </div>
                  </div>

                  {/* Match Metadata */}
                  <div className="mt-3 pt-3 border-t border-gray-100 grid grid-cols-2 gap-x-3 gap-y-1.5 text-xs">
                    <div>
                      <span className="block text-gray-400 uppercase font-bold text-[10px]">Competição</span>
                      <span className="text-gray-700 font-semibold truncate block">
                        {[match.country, match.round].filter(Boolean).join(" • ") || "Temporada Oficial"}
                      </span>
                    </div>
                    <div>
                      <span className="block text-gray-400 uppercase font-bold text-[10px]">Local / Status</span>
                      <span className="text-gray-700 font-semibold truncate block">
                        {[match.venue, match.city].filter(Boolean).join(", ") || match.statusLong || "Cobertura Oficial"}
                      </span>
                    </div>
                  </div>

                  {/* Action inside each Match Card */}
                  <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-center">
                    <a
                      href="#bolao"
                      onClick={() => setSelectedBolaoMatch(matchTitle)}
                      className="w-full bg-gradient-to-r from-amber-400 to-amber-500 hover:from-amber-300 hover:to-amber-400 text-gray-950 font-black text-xs py-3 px-4 rounded-xl uppercase tracking-wide text-center transition-all flex items-center justify-center gap-1.5 shadow-md"
                    >
                      🏆 Criar Bolão do Jogo
                    </a>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div className="mt-10 flex items-center justify-center">
          <a
            href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-[#03150b] font-black text-sm px-8 py-4 rounded-xl shadow-[0_0_25px_rgba(16,185,129,0.4)] transition-all uppercase tracking-wide"
          >
            📲 Baixar App Grátis na Play Store
          </a>
        </div>
      </section>

      {/* 4. NOVO: BOLÃO DO GOL (AMIGOS, CHURRASCO & BARES) */}
      <section
        id="bolao"
        className="py-20 px-4 bg-gradient-to-b from-[#062615] via-[#072e19] to-[#041d10] border-y border-emerald-700/50 relative overflow-hidden"
      >
        <div className="max-w-6xl mx-auto relative z-10">
          <div className="text-center mb-14">
            <span className="bg-amber-400/15 text-amber-300 border border-amber-400/40 text-xs font-black px-4 py-1.5 rounded-full uppercase tracking-wider inline-flex items-center gap-2 mb-3">
              🏆 Funcionalidade Exclusiva no App
            </span>
            <h2 className="text-3xl md:text-5xl font-black text-white tracking-tight">
              Bolão do Gol:{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-300 via-amber-400 to-emerald-300">
                Para a Galera & Para Bares!
              </span>
            </h2>
            <p className="text-emerald-100/85 max-w-2xl mx-auto mt-3 text-base md:text-lg">
              Acabou a planilha confusa no grupo! Crie o bolão de qualquer partida em 30 segundos, compartilhe o link no WhatsApp e deixe o app apurar o placar exato ao vivo.
            </p>
          </div>

          <div className="grid lg:grid-cols-12 gap-8 items-stretch">
            {/* Left Column: Cards for Friends & Bars */}
            <div className="lg:col-span-6 flex flex-col justify-between gap-6">
              {/* Card 1: Galera & Amigos */}
              <div className="bg-white text-gray-900 border border-gray-100 rounded-3xl p-7 shadow-xl hover:shadow-2xl transition-all">
                <div className="flex items-center justify-between mb-4">
                  <span className="bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-black px-3 py-1 rounded-full uppercase">
                    👥 Modo Amigos & Grupos
                  </span>
                  <span className="text-emerald-600 font-black text-sm">Comissão: 5%</span>
                </div>
                <h3 className="text-2xl font-black text-gray-950 mb-2">
                  Bolão da Resenha, Churrasco ou Trabalho
                </h3>
                <p className="text-gray-600 text-sm leading-relaxed mb-4">
                  Crie um bolão <strong className="text-gray-900">Grátis</strong> (valendo a zoeira) ou com cota em reais. Cada amigo escolhe seu placar exato antes do apito inicial. Quem cravar o placar divide <strong className="text-emerald-700 font-black">85% do pote da premiação</strong> e você ainda ganha <strong className="text-emerald-700 font-black">5% de comissão</strong> por organizar!
                </p>
                <div className="flex flex-wrap gap-2 text-xs text-gray-700 font-semibold">
                  <span className="bg-gray-50 border border-gray-200 px-3 py-1 rounded-lg">✅ Convite direto no WhatsApp</span>
                  <span className="bg-gray-50 border border-gray-200 px-3 py-1 rounded-lg">✅ Placar ao vivo automático</span>
                </div>
              </div>

              {/* Card 2: Bares & Restaurantes */}
              <div className="bg-white text-gray-900 border-2 border-amber-400 rounded-3xl p-7 shadow-xl hover:shadow-2xl transition-all">
                <div className="flex items-center justify-between mb-4">
                  <span className="bg-amber-50 text-amber-800 border border-amber-300 text-xs font-black px-3 py-1 rounded-full uppercase">
                    🍺 Modo Bares, Espetinhos & Eventos
                  </span>
                  <span className="text-amber-600 font-black text-sm">Comissão do Bar: 10%</span>
                </div>
                <h3 className="text-2xl font-black text-gray-950 mb-2">
                  Lote seu Bar em Dia de Jogo e Lucre Mais!
                </h3>
                <p className="text-gray-600 text-sm leading-relaxed mb-4">
                  Transforme a transmissão do futebol no seu bar! Crie o <strong className="text-gray-900">Bolão Oficial da Casa</strong>, divulgue o código para as mesas e mantenha os clientes consumindo até o apito final. Os clientes que cravarem levam <strong className="text-amber-700 font-black">80% do pote</strong> e o seu bar fatura <strong className="text-emerald-700 font-black">10% de comissão garantida</strong>!
                </p>
                <div className="flex flex-wrap gap-2 text-xs text-gray-700 font-semibold">
                  <span className="bg-amber-50/80 border border-amber-200 px-3 py-1 rounded-lg">🍻 Aumenta o ticket médio das mesas</span>
                  <span className="bg-amber-50/80 border border-amber-200 px-3 py-1 rounded-lg">🏆 Destaque na aba "Bares" do App</span>
                </div>
              </div>
            </div>

            {/* Right Column: Interactive Pote & Comissão Calculator */}
            <div className="lg:col-span-6 bg-white text-gray-900 border border-gray-100 rounded-3xl p-7 md:p-8 shadow-2xl flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between gap-2 mb-4">
                  <span className="text-xs font-black uppercase tracking-wider text-emerald-700 bg-emerald-50 border border-emerald-200 px-3 py-1 rounded-full">
                    🧮 Simulador de Pote & Premiação
                  </span>
                  <span className="text-xs text-gray-600 font-bold truncate max-w-[180px] bg-gray-100 px-2.5 py-1 rounded-full">
                    ⚽ {selectedBolaoMatch}
                  </span>
                </div>

                <h3 className="text-xl md:text-2xl font-black text-gray-950 mb-5">
                  Simule Quanto seu Bolão Pode Pagar:
                </h3>

                {/* Mode Selector */}
                <div className="grid grid-cols-2 gap-3 mb-5">
                  <button
                    type="button"
                    onClick={() => setBolaoMode("friends")}
                    className={`py-3 px-4 rounded-2xl font-black text-xs uppercase tracking-wider border transition-all cursor-pointer ${
                      bolaoMode === "friends"
                        ? "bg-emerald-600 text-white border-emerald-600 shadow-md"
                        : "bg-gray-50 text-gray-700 border-gray-200 hover:bg-gray-100"
                    }`}
                  >
                    👥 Entre Amigos (5% Org.)
                  </button>
                  <button
                    type="button"
                    onClick={() => setBolaoMode("bar")}
                    className={`py-3 px-4 rounded-2xl font-black text-xs uppercase tracking-wider border transition-all cursor-pointer ${
                      bolaoMode === "bar"
                        ? "bg-amber-500 text-gray-950 border-amber-500 shadow-md"
                        : "bg-gray-50 text-gray-700 border-gray-200 hover:bg-gray-100"
                    }`}
                  >
                    🍺 Modo Bar (10% Bar)
                  </button>
                </div>

                {/* Entry Fee Chips */}
                <div className="mb-5">
                  <label className="block text-xs font-bold text-gray-600 uppercase mb-2">
                    Valor da Cota por Participante:
                  </label>
                  <div className="grid grid-cols-4 gap-2.5">
                    {[5, 10, 20, 50].map((val) => (
                      <button
                        key={val}
                        type="button"
                        onClick={() => setEntryFee(val)}
                        className={`py-2.5 rounded-xl font-black text-sm border transition-all cursor-pointer ${
                          entryFee === val
                            ? "bg-amber-400 text-gray-950 border-amber-400 shadow"
                            : "bg-gray-50 text-gray-800 border-gray-200 hover:bg-gray-100"
                        }`}
                      >
                        R$ {val}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Participants Slider */}
                <div className="mb-6">
                  <div className="flex justify-between items-center text-xs font-bold mb-2">
                    <span className="text-gray-600 uppercase">Número de Participantes:</span>
                    <span className="text-emerald-700 text-base font-black">{participantsCount} pessoas</span>
                  </div>
                  <input
                    type="range"
                    min={5}
                    max={150}
                    step={5}
                    value={participantsCount}
                    onChange={(e) => setParticipantsCount(Number(e.target.value))}
                    aria-label="Número de participantes no bolão"
                    className="w-full accent-emerald-600 cursor-pointer h-2 bg-gray-200 rounded-lg"
                  />
                  <div className="flex justify-between text-[10px] text-gray-400 font-semibold mt-1">
                    <span>5 amigos</span>
                    <span>50 pessoas</span>
                    <span>150 torcedores</span>
                  </div>
                </div>

                {/* Results Box */}
                <div className="bg-gradient-to-br from-gray-900 to-gray-950 border border-gray-800 rounded-2xl p-5 space-y-3 text-white shadow-inner">
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-300 font-semibold">💰 Pote Total Arrecadado:</span>
                    <span className="text-white font-black text-lg">
                      R$ {totalPot.toFixed(2).replace(".", ",")}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm border-t border-gray-800 pt-2.5">
                    <span className="text-amber-400 font-bold">
                      🏆 Prêmio do Vencedor ({Math.round(winnerPct * 100)}%):
                    </span>
                    <span className="text-amber-400 font-black text-2xl">
                      R$ {winnerPrize.toFixed(2).replace(".", ",")}
                    </span>
                  </div>
                  <div className="flex justify-between items-center text-sm border-t border-gray-800 pt-2.5">
                    <span className="text-emerald-400 font-bold">
                      {bolaoMode === "friends"
                        ? "🤝 Sua Comissão de Organizador (5%):"
                        : "🍺 Comissão do Seu Bar (10%):"}
                    </span>
                    <span className="text-emerald-400 font-black text-lg">
                      R$ {organizerCommission.toFixed(2).replace(".", ",")}
                    </span>
                  </div>
                </div>
              </div>

              <div className="mt-6">
                <a
                  href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-gray-950 font-black text-sm py-4 px-6 rounded-2xl text-center uppercase tracking-wide shadow-lg hover:scale-[1.02] transition-all block w-full"
                >
                  📲 Baixar o App para Criar seu Bolão
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 5. SLIDER DE PRÊMIOS */}
      <section className="w-full">
        <PrizesSlider />
      </section>

      {/* 6. COMO FUNCIONA (PASSO A PASSO Visual) */}
      <section id="como-funciona" className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-black text-white">
            Como Funciona em 3 Passos Simples
          </h2>
          <p className="text-emerald-100/75 max-w-xl mx-auto mt-2 text-base">
            Qualquer torcedor pode participar gratuitamente e concorrer a prêmios reais.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          <div className="bg-white text-gray-900 border border-gray-100 p-8 rounded-3xl text-center relative hover:shadow-2xl transition-all shadow-xl">
            <div className="w-16 h-16 bg-amber-50 border border-amber-200 text-amber-600 text-2xl font-black rounded-2xl flex items-center justify-center mx-auto mb-6">
              01
            </div>
            <h3 className="text-xl font-black text-gray-950 mb-3">Baixe o App & Escolha o Jogo</h3>
            <p className="text-gray-600 text-sm leading-relaxed">
              Instale grátis na Google Play, crie sua conta em segundos e marque a partida que você está assistindo.
            </p>
          </div>

          <div className="bg-white text-gray-900 border border-gray-100 p-8 rounded-3xl text-center relative hover:shadow-2xl transition-all shadow-xl">
            <div className="w-16 h-16 bg-emerald-50 border border-emerald-200 text-emerald-700 text-2xl font-black rounded-2xl flex items-center justify-center mx-auto mb-6">
              02
            </div>
            <h3 className="text-xl font-black text-gray-950 mb-3">Quizzes IA & Bolão da Galera</h3>
            <p className="text-gray-600 text-sm leading-relaxed">
              Responda perguntas geradas por Inteligência Artificial durante o jogo e desafie seus amigos no Bolão de placar exato.
            </p>
          </div>

          <div className="bg-white text-gray-900 border border-gray-100 p-8 rounded-3xl text-center relative hover:shadow-2xl transition-all shadow-xl">
            <div className="w-16 h-16 bg-amber-50 border border-amber-200 text-amber-600 text-2xl font-black rounded-2xl flex items-center justify-center mx-auto mb-6">
              03
            </div>
            <h3 className="text-xl font-black text-gray-950 mb-3">Raspe & Resgate Prêmios</h3>
            <p className="text-gray-600 text-sm leading-relaxed">
              Raspe cartelas a cada gol ou troque seus Tokens na Loja por camisas oficiais, bolas e brindes incríveis.
            </p>
          </div>
        </div>

        {/* Callout: O Papel Real dos Tokens */}
        <div className="mt-12 bg-gradient-to-r from-emerald-950 via-[#072f1a] to-emerald-950 border border-amber-400/50 rounded-3xl p-8 md:p-10 shadow-2xl text-left">
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
            <div className="max-w-2xl">
              <div className="flex items-center gap-2 mb-2">
                <span className="bg-amber-400 text-gray-950 text-xs font-black px-3 py-1 rounded-full uppercase tracking-wider">
                  🪙 Transparência Total
                </span>
                <span className="text-amber-400 font-black text-sm">Sem Apostas • 100% Grátis</span>
              </div>
              <h3 className="text-2xl md:text-3xl font-black text-white mb-3">
                Qual o Papel Real dos Tokens do Gol?
              </h3>
              <p className="text-emerald-100/85 text-sm md:text-base leading-relaxed">
                Tokens do Gol são a <strong>moeda de fidelidade e pontuação do torcedor</strong>. NÃO são dinheiro e NÃO envolvem apostas. Você ganha tokens gratuitamente jogando quizzes gerados por IA durante os jogos, assistindo vídeos e vibrando nos gols. O papel real dos Tokens é <strong>ser trocado por Prêmios Físicos Reais (camisas oficiais de time, tênis, bolas, brindes de patrocinadores)</strong> na Loja do App e liberar novas raspadinhas!
              </p>
            </div>
            <div className="shrink-0 w-full md:w-auto">
              <a
                href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 w-full md:w-auto px-6 py-4 rounded-2xl bg-amber-400 hover:bg-amber-300 text-gray-950 font-black text-sm uppercase tracking-wide transition-all shadow-lg hover:scale-105"
              >
                <span>🎁</span> Comece a Pontuar Grátis
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* 7. SEÇÃO DE PERGUNTAS FREQUENTES (FAQ) DIRETO NA HOME */}
      <section id="faq-home" className="py-20 px-4 max-w-5xl mx-auto border-t border-emerald-800/60">
        <div className="text-center mb-14">
          <span className="bg-amber-400/15 text-amber-300 border border-amber-400/30 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider inline-block mb-3">
            Tire Suas Dúvidas
          </span>
          <h2 className="text-3xl md:text-4xl font-black text-white">
            Perguntas Frequentes (FAQ)
          </h2>
          <p className="text-emerald-100/75 max-w-xl mx-auto mt-2 text-base">
            Tudo o que você precisa saber sobre a entrega dos prêmios, Bolão do Gol, gratuidade e campeonatos.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          {HOME_FAQS.map((item, idx) => (
            <div
              key={idx}
              className="bg-white text-gray-900 border border-gray-100 hover:shadow-xl p-6 rounded-3xl transition-all shadow-lg text-left"
            >
              <span className="text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-3 py-1 rounded-full uppercase tracking-wider inline-block mb-3">
                {item.badge}
              </span>
              <h3 className="text-lg font-black text-gray-950 mb-2">{item.q}</h3>
              <p className="text-gray-600 text-sm leading-relaxed">{item.a}</p>
            </div>
          ))}
        </div>

        <div className="text-center mt-8">
          <Link
            to="/faq"
            onClick={() => window.scrollTo(0, 0)}
            className="text-sm font-bold text-emerald-300 hover:text-amber-300 underline underline-offset-4"
          >
            Ver todas as dúvidas frequentes →
          </Link>
        </div>
      </section>

      {/* 8. REDES SOCIAIS OFICIAIS */}
      <section className="py-14 px-4 max-w-5xl mx-auto text-center border-t border-emerald-900/40">
        <span className="bg-amber-400/15 text-amber-300 border border-amber-400/30 text-xs font-bold px-3.5 py-1.5 rounded-full uppercase tracking-wider inline-flex items-center gap-2">
          <span>📲</span> Comunidade & Conteúdos Exclusivos
        </span>
        <h2 className="text-3xl md:text-4xl font-black text-white mt-3">
          Siga Nossas Redes Oficiais
        </h2>
        <p className="text-emerald-100/75 max-w-xl mx-auto mt-2 text-sm sm:text-base mb-8">
          Acompanhe análises de rodadas, vídeos de gols, bastidores e novidades sobre os prêmios no canal oficial.
        </p>

        <div className="grid sm:grid-cols-2 gap-4 max-w-2xl mx-auto">
          {/* YouTube */}
          <a
            href="https://www.youtube.com/@guiadoplayeroficial"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-4 p-5 rounded-2xl bg-[#062916] border border-red-500/30 hover:border-red-500 hover:bg-[#0a3820] transition-all group shadow-lg hover:scale-[1.02]"
          >
            <div className="w-14 h-14 rounded-2xl bg-red-600/20 border border-red-500/30 flex items-center justify-center text-red-500 group-hover:bg-red-600 group-hover:text-white transition-all text-2xl shadow-inner">
              ▶
            </div>
            <div className="text-left flex-1">
              <span className="text-xs font-bold text-red-400 uppercase tracking-wider block">Canal Oficial</span>
              <span className="text-lg font-black text-white group-hover:text-red-300 transition-colors block">
                YouTube
              </span>
              <span className="text-xs text-emerald-200/60 font-medium">@guiadoplayeroficial</span>
            </div>
            <span className="text-gray-400 group-hover:text-white group-hover:translate-x-1 transition-all">→</span>
          </a>

          {/* TikTok */}
          <a
            href="https://www.tiktok.com/@guiadoplayeroficial"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-4 p-5 rounded-2xl bg-[#062916] border border-cyan-400/30 hover:border-cyan-400 hover:bg-[#0a3820] transition-all group shadow-lg hover:scale-[1.02]"
          >
            <div className="w-14 h-14 rounded-2xl bg-black border border-white/20 flex items-center justify-center text-cyan-400 group-hover:border-cyan-400 group-hover:shadow-[0_0_15px_rgba(34,211,238,0.4)] transition-all text-2xl shadow-inner">
              🎵
            </div>
            <div className="text-left flex-1">
              <span className="text-xs font-bold text-cyan-400 uppercase tracking-wider block">Vídeos Curtos</span>
              <span className="text-lg font-black text-white group-hover:text-cyan-300 transition-colors block">
                TikTok
              </span>
              <span className="text-xs text-emerald-200/60 font-medium">@guiadoplayeroficial</span>
            </div>
            <span className="text-gray-400 group-hover:text-white group-hover:translate-x-1 transition-all">→</span>
          </a>
        </div>
      </section>

      {/* 9. FINAL CTA BANNER */}
      <section className="py-20 px-4 text-center bg-gradient-to-r from-[#03170c] via-[#07301a] to-[#03170c] border-t border-emerald-500/30 relative">
        <div className="max-w-4xl mx-auto relative z-10">
          <h2 className="text-3xl sm:text-5xl font-black text-white mb-6">
            Pronto para transformar cada gol em festa?
          </h2>
          <p className="text-lg text-emerald-100/85 mb-8 max-w-xl mx-auto">
            Junte-se a mais de 15 mil torcedores, crie o Bolão da sua galera e conquiste camisas oficiais e prêmios hoje mesmo!
          </p>
          <a
            href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-[#03150b] text-xl font-black px-10 py-5 rounded-2xl shadow-[0_0_40px_rgba(251,191,36,0.6)] hover:scale-105 transition-all duration-300 uppercase tracking-wide"
          >
            JOGUE AGORA E GANHE CAMISAS OFICIAIS!
          </a>
        </div>
      </section>

      {/* Modal de Compartilhamento acionado pela Home */}
      <ShareAppModal 
        isOpen={isHomeShareModalOpen} 
        onClose={() => setIsHomeShareModalOpen(false)} 
      />

      {/* Modal de Prêmio Ativo da Rodada */}
      <PrizeModal />
    </div>
  );
}
