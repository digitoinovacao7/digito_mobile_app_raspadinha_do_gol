import { useState } from "react";

export function DemoScratchcard() {
  const [scratched, setScratched] = useState(false);

  return (
    <div className="w-full max-w-md bg-slate-900/90 backdrop-blur-xl border border-emerald-500/30 p-6 rounded-3xl shadow-[0_0_50px_rgba(16,185,129,0.2)] text-center relative">
      <div className="inline-flex items-center gap-2 bg-emerald-500/20 text-emerald-400 text-xs font-bold px-3 py-1.5 rounded-full border border-emerald-500/30 mb-4 uppercase tracking-wider">
        <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
        Demonstração Interativa
      </div>
      <h4 className="text-xl font-black text-white mb-2">
        Experimente Raspar Agora!
      </h4>
      <p className="text-sm text-gray-300 mb-6">
        Clique no cartão abaixo para simular a raspadinha que você ganha a cada gol.
      </p>

      <div
        onClick={() => setScratched(true)}
        className={`relative w-full h-56 rounded-2xl cursor-pointer overflow-hidden transition-all duration-500 transform hover:scale-[1.02] shadow-2xl border-2 ${
          scratched ? "border-amber-400" : "border-emerald-400/50"
        }`}
      >
        {/* Layer 1: Content Revealed */}
        <div className="absolute inset-0 bg-gradient-to-br from-emerald-900 via-slate-900 to-emerald-950 flex flex-col items-center justify-center p-6 text-center">
          <div className="text-5xl mb-2 animate-bounce">🏆</div>
          <span className="text-amber-400 font-black text-2xl drop-shadow-md uppercase">
            VOCÊ GANHOU!
          </span>
          <span className="text-white font-bold text-lg mt-1">
            +500 TOKENS DO GOL
          </span>
          <span className="text-xs text-emerald-300 mt-2 bg-emerald-900/60 px-3 py-1 rounded-full border border-emerald-500/30">
            Resgate camisas e prêmios reais no App!
          </span>
        </div>

        {/* Layer 2: Scratch Foil */}
        <div
          className={`absolute inset-0 bg-gradient-to-tr from-amber-500 via-yellow-400 to-amber-600 flex flex-col items-center justify-center p-6 transition-all duration-700 ${
            scratched
              ? "opacity-0 pointer-events-none scale-110"
              : "opacity-100"
          }`}
        >
          <div className="w-16 h-16 bg-black/20 rounded-full flex items-center justify-center mb-3 text-2xl text-slate-900 font-bold border border-black/10">
            ✨
          </div>
          <span className="text-slate-950 font-black text-xl tracking-tight uppercase">
            RASPE AQUI
          </span>
          <span className="text-slate-900 text-xs font-semibold mt-1 bg-black/10 px-3 py-1 rounded-full">
            Clique para revelar seu prêmio!
          </span>
        </div>
      </div>

      {scratched && (
        <div className="mt-4 animate-fade-in">
          <a
            href="https://app-raspadinhadogol.web.app"
            className="inline-block w-full bg-gradient-to-r from-amber-400 to-yellow-500 text-slate-950 font-black text-base py-3.5 px-6 rounded-xl shadow-[0_0_20px_rgba(251,191,36,0.6)] hover:brightness-110 transition-all uppercase tracking-wide"
          >
            USAR TOKENS NO APP GRÁTIS 🚀
          </a>
        </div>
      )}
    </div>
  );
}
