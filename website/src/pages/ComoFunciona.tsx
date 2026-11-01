import { Link } from "react-router-dom";

export function ComoFunciona() {
  return (
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20 overflow-hidden">
      {/* Hero Header */}
      <section className="relative py-16 px-4 text-center border-b border-emerald-800/60 bg-gradient-to-b from-[#062414] to-[#041d10]">
        <div className="max-w-4xl mx-auto relative z-10">
          <span className="bg-amber-400/10 text-amber-400 border border-amber-400/30 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider inline-block mb-4">
            Guia Completo do Torcedor
          </span>
          <h1 className="text-4xl md:text-6xl font-black mb-6 text-white tracking-tight">
            Como Funciona o <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-300 via-amber-400 to-amber-500">Raspadinha do Gol?</span>
          </h1>
          <p className="text-lg md:text-xl text-emerald-100/80 max-w-2xl mx-auto leading-relaxed">
            Entenda como transformar o seu conhecimento de futebol e a sua torcida em camisas oficiais, Bolões da Galera, prêmios físicos e brindes 100% gratuitos.
          </p>
        </div>
      </section>

      {/* Step by Step Visual Guide */}
      <section className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-black text-white">
            Passo a Passo para Jogar & Ganhar
          </h2>
          <p className="text-emerald-100/75 max-w-lg mx-auto mt-2 text-sm md:text-base">
            Sem apostas esportivas e sem mensalidade. Apenas diversão e recompensas reais!
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Step 1 */}
          <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 rounded-3xl text-left relative hover:border-amber-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-amber-400/10 border border-amber-400/30 text-amber-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                01
              </div>
              <h3 className="text-xl font-black text-white mb-3">Baixe o App Grátis</h3>
              <p className="text-emerald-100/75 text-sm leading-relaxed">
                Instale gratuitamente o aplicativo oficial no seu celular Android pela Google Play Store.
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-emerald-800/60 text-xs text-amber-400/90 font-bold uppercase tracking-wider">
              100% Gratuito
            </div>
          </div>

          {/* Step 2 */}
          <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 rounded-3xl text-left relative hover:border-emerald-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-emerald-400/10 border border-emerald-400/30 text-emerald-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                02
              </div>
              <h3 className="text-xl font-black text-white mb-3">Escolha a Partida</h3>
              <p className="text-emerald-100/75 text-sm leading-relaxed">
                Navegue pelas partidas ao vivo do dia (Brasileirão, Copa do Brasil, Libertadores, Champions League) e acompanhe os lances.
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-emerald-800/60 text-xs text-emerald-400/90 font-bold uppercase tracking-wider">
              Jogos ao Vivo
            </div>
          </div>

          {/* Step 3 */}
          <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 rounded-3xl text-left relative hover:border-amber-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-amber-400/10 border border-amber-400/30 text-amber-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                03
              </div>
              <h3 className="text-xl font-black text-white mb-3">Quizzes, Raspadinhas & Bolão</h3>
              <p className="text-emerald-100/75 text-sm leading-relaxed">
                Responda perguntas geradas por IA, ganhe raspadinhas a cada gol e crie ou participe do Bolão do Gol com amigos e bares!
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-emerald-800/60 text-xs text-amber-400/90 font-bold uppercase tracking-wider">
              IA & Bolão da Galera
            </div>
          </div>

          {/* Step 4 */}
          <div className="bg-[#072917]/75 border border-emerald-800/60 p-8 rounded-3xl text-left relative hover:border-emerald-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-emerald-400/10 border border-emerald-400/30 text-emerald-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                04
              </div>
              <h3 className="text-xl font-black text-white mb-3">Resgate Seus Prêmios</h3>
              <p className="text-emerald-100/75 text-sm leading-relaxed">
                Acumule Tokens do Gol ou encontre 3 símbolos iguais na raspadinha para resgatar camisas oficiais, bolas e prêmios na loja.
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-emerald-800/60 text-xs text-emerald-400/90 font-bold uppercase tracking-wider">
              Prêmios Reais
            </div>
          </div>
        </div>
      </section>

      {/* Bolão do Gol Highlight Section */}
      <section className="py-16 px-4 bg-[#062414]/80 border-y border-emerald-800/60">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-12">
            <span className="bg-amber-400/15 text-amber-300 border border-amber-400/30 text-xs font-bold px-3.5 py-1.5 rounded-full uppercase tracking-wider inline-block mb-3">
              🏆 Novidade no Aplicativo
            </span>
            <h2 className="text-3xl font-black text-white mb-3">
              Como Funciona o Bolão do Gol (Amigos & Bares)
            </h2>
            <p className="text-emerald-100/75 text-sm max-w-2xl mx-auto">
              Organize bolões de placar exato para o grupo de WhatsApp, churrasco da galera ou clientes do seu bar com transparência total e apuração automática ao apito final.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <div className="p-7 bg-[#041d10]/90 border border-emerald-700/60 rounded-3xl">
              <h4 className="text-lg font-black text-amber-400 mb-3">👥 Bolão entre Amigos</h4>
              <p className="text-sm text-emerald-100/80 leading-relaxed mb-4">
                Crie um bolão grátis (valendo a resenha) ou com premiação da galera. O organizador ganha <strong className="text-emerald-300">5% de comissão</strong>, <strong className="text-amber-300">85% vai para a premiação</strong> de quem cravar o placar exato e 10% mantém a plataforma.
              </p>
              <span className="text-xs font-bold text-emerald-300 bg-emerald-500/15 border border-emerald-500/30 px-3 py-1 rounded-full">
                Link exclusivo para compartilhar no WhatsApp
              </span>
            </div>

            <div className="p-7 bg-[#041d10]/90 border border-amber-400/40 rounded-3xl">
              <h4 className="text-lg font-black text-amber-400 mb-3">🍺 Bolão Oficial para Bares & Restaurantes</h4>
              <p className="text-sm text-emerald-100/80 leading-relaxed mb-4">
                Donos de bares e espetinhos podem criar o Bolão da Casa em dias de jogo! O bar recebe <strong className="text-amber-300">10% de comissão</strong> sobre todo o pote arrecadado, movimenta o salão até o apito final e os clientes que cravarem o placar dividem <strong className="text-emerald-300">80% do prêmio na hora</strong>.
              </p>
              <span className="text-xs font-bold text-amber-300 bg-amber-400/15 border border-amber-400/30 px-3 py-1 rounded-full">
                Apuração 100% automática no apito final
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* Rules & Transparency Section */}
      <section className="py-16 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-black text-white mb-3">
              Garantias e Transparência
            </h2>
            <p className="text-emerald-100/75 text-sm">
              Tudo o que você precisa saber para jogar com tranquilidade.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            <div className="p-6 bg-[#072917]/80 border border-emerald-800/60 rounded-2xl">
              <h4 className="text-base font-bold text-amber-400 mb-2">Sem Apostas Esportivas</h4>
              <p className="text-xs text-emerald-100/75 leading-relaxed">
                Não somos casa de apostas nem operamos odds. Você ganha tokens e raspadinhas gratuitamente participando dos quizzes e eventos ao vivo.
              </p>
            </div>
            <div className="p-6 bg-[#072917]/80 border border-emerald-800/60 rounded-2xl">
              <h4 className="text-base font-bold text-emerald-400 mb-2">Entregas Garantidas</h4>
              <p className="text-xs text-emerald-100/75 leading-relaxed">
                Todos os prêmios físicos (camisas oficiais, bolas, produtos parceiros) são processados e entregues diretamente com código de rastreio aos torcedores contemplados.
              </p>
            </div>
            <div className="p-6 bg-[#072917]/80 border border-emerald-800/60 rounded-2xl">
              <h4 className="text-base font-bold text-amber-400 mb-2">Patrocinadores Oficiais</h4>
              <p className="text-xs text-emerald-100/75 leading-relaxed">
                As premiações são mantidas graças a parcerias com marcas patrocinadoras que financiam os prêmios para os torcedores.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Box */}
      <section className="py-20 px-4 text-center">
        <div className="max-w-3xl mx-auto bg-gradient-to-r from-emerald-950 via-[#062615] to-emerald-950 border border-emerald-500/40 rounded-3xl p-10 md:p-14 shadow-2xl">
          <h2 className="text-3xl md:text-4xl font-black text-white mb-4">
            Pronto para testar seu conhecimento?
          </h2>
          <p className="text-emerald-100/85 text-base mb-8 max-w-xl mx-auto">
            Baixe agora o app oficial na Play Store e comece a pontuar nos próximos jogos do seu time!
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-[#03150b] text-lg font-black px-8 py-4 rounded-2xl shadow-lg hover:scale-105 transition-all uppercase tracking-wide"
            >
              📱 Baixar na Google Play Store
            </a>
            <Link
              to="/"
              onClick={() => window.scrollTo(0, 0)}
              className="w-full sm:w-auto bg-[#041d10] border border-emerald-600/40 text-white text-lg font-bold px-8 py-4 rounded-2xl hover:bg-emerald-900/50 transition-all text-center"
            >
              Voltar ao Início
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
