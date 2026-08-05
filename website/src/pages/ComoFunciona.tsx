import { Link } from "react-router-dom";

export function ComoFunciona() {
  return (
    <div className="w-full bg-slate-950 text-white font-sans min-h-screen pt-24 pb-20 overflow-hidden">
      {/* Hero Header */}
      <section className="relative py-16 px-4 text-center border-b border-slate-800 bg-gradient-to-b from-slate-900/80 to-slate-950">
        <div className="max-w-4xl mx-auto relative z-10">
          <span className="bg-amber-400/10 text-amber-400 border border-amber-400/30 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider inline-block mb-4">
            Guia Completo do Torcedor
          </span>
          <h1 className="text-4xl md:text-6xl font-black mb-6 text-white tracking-tight">
            Como Funciona o <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-300 via-amber-400 to-amber-500">Raspadinha do Gol?</span>
          </h1>
          <p className="text-lg md:text-xl text-gray-300 max-w-2xl mx-auto leading-relaxed">
            Entenda como transformar o seu conhecimento de futebol e a sua torcida em camisas oficiais, prêmios em Pix e brindes 100% gratuitos.
          </p>
        </div>
      </section>

      {/* Step by Step Visual Guide */}
      <section className="py-20 px-4 max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-black text-white">
            Passo a Passo para Jogar & Ganhar
          </h2>
          <p className="text-gray-400 max-w-lg mx-auto mt-2 text-sm md:text-base">
            Sem apostas em dinheiro e sem mensalidade. Apenas diversão e recompensas reais!
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Step 1 */}
          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-left relative hover:border-amber-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-amber-400/10 border border-amber-400/30 text-amber-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                01
              </div>
              <h3 className="text-xl font-black text-white mb-3">Baixe o App Grátis</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Instale o aplicativo no seu celular Android pela Google Play Store ou acesse a versão web pelo navegador.
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-slate-800/80 text-xs text-amber-400/80 font-bold uppercase tracking-wider">
              100% Gratuito
            </div>
          </div>

          {/* Step 2 */}
          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-left relative hover:border-emerald-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-emerald-400/10 border border-emerald-400/30 text-emerald-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                02
              </div>
              <h3 className="text-xl font-black text-white mb-3">Escolha a Partida</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Navegue pelas partidas ao vivo do dia (Brasileirão, Copa do Brasil, Champions League, etc.) e acompanhe os lances.
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-slate-800/80 text-xs text-emerald-400/80 font-bold uppercase tracking-wider">
              Jogos ao Vivo
            </div>
          </div>

          {/* Step 3 */}
          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-left relative hover:border-amber-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-amber-400/10 border border-amber-400/30 text-amber-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                03
              </div>
              <h3 className="text-xl font-black text-white mb-3">Quizzes & Raspadinhas</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Responda perguntas geradas por IA sobre o jogo e ganhe raspadinhas automáticas instantâneas sempre que sair um gol!
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-slate-800/80 text-xs text-amber-400/80 font-bold uppercase tracking-wider">
              Quizzes com IA
            </div>
          </div>

          {/* Step 4 */}
          <div className="bg-slate-900/60 border border-slate-800 p-8 rounded-3xl text-left relative hover:border-emerald-400/50 transition-all group flex flex-col justify-between">
            <div>
              <div className="w-14 h-14 bg-emerald-400/10 border border-emerald-400/30 text-emerald-400 text-2xl font-black rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                04
              </div>
              <h3 className="text-xl font-black text-white mb-3">Resgate Seus Prêmios</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Acumule Tokens do Gol ou encontre 3 símbolos iguais na raspadinha para resgatar camisas oficiais, Pix e prêmios na loja.
              </p>
            </div>
            <div className="mt-6 pt-4 border-t border-slate-800/80 text-xs text-emerald-400/80 font-bold uppercase tracking-wider">
              Prêmios Reais
            </div>
          </div>
        </div>
      </section>

      {/* Rules & Transparency Section */}
      <section className="py-16 px-4 bg-slate-900/50 border-y border-slate-800">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-black text-white mb-3">
              Garantias e Transparência
            </h2>
            <p className="text-gray-400 text-sm">
              Tudo o que você precisa saber para jogar com tranquilidade.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            <div className="p-6 bg-slate-950/80 border border-slate-800 rounded-2xl">
              <h4 className="text-base font-bold text-amber-400 mb-2">Sem Custos Ocultos</h4>
              <p className="text-xs text-gray-400 leading-relaxed">
                O aplicativo é 100% grátis. Você ganha moedas e raspadinhas participando dos quizzes e interagindo durante as partidas.
              </p>
            </div>
            <div className="p-6 bg-slate-950/80 border border-slate-800 rounded-2xl">
              <h4 className="text-base font-bold text-emerald-400 mb-2">Entregas Garantidas</h4>
              <p className="text-xs text-gray-400 leading-relaxed">
                Todos os prêmios físicos (camisas oficiais, brindes) e Pix são processados e entregues diretamente aos torcedores contemplados.
              </p>
            </div>
            <div className="p-6 bg-slate-950/80 border border-slate-800 rounded-2xl">
              <h4 className="text-base font-bold text-amber-400 mb-2">Patrocinadores Oficiais</h4>
              <p className="text-xs text-gray-400 leading-relaxed">
                As premiações são mantidas graças a parcerias com marcas patrocinadoras que financiam os prêmios para os torcedores.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Box */}
      <section className="py-20 px-4 text-center">
        <div className="max-w-3xl mx-auto bg-gradient-to-r from-emerald-950 via-slate-900 to-emerald-950 border border-emerald-500/30 rounded-3xl p-10 md:p-14 shadow-2xl">
          <h2 className="text-3xl md:text-4xl font-black text-white mb-4">
            Pronto para testar seu conhecimento?
          </h2>
          <p className="text-gray-300 text-base mb-8 max-w-xl mx-auto">
            Baixe agora o app oficial na Play Store e comece a pontuar nos próximos jogos do seu time!
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-slate-950 text-lg font-black px-8 py-4 rounded-2xl shadow-lg hover:scale-105 transition-all uppercase tracking-wide"
            >
              📱 Baixar na Google Play Store
            </a>
            <Link
              to="/"
              onClick={() => window.scrollTo(0, 0)}
              className="w-full sm:w-auto bg-slate-900 border border-white/20 text-white text-lg font-bold px-8 py-4 rounded-2xl hover:bg-white/10 transition-all text-center"
            >
              Voltar ao Início
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
