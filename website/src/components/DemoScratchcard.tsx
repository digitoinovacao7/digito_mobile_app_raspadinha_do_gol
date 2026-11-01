import { useState } from "react";

export function DemoScratchcard() {
  const [scratched, setScratched] = useState(false);

  return (
    <div className="w-full max-w-md bg-white/95 backdrop-blur-xl border border-white/80 p-6 sm:p-7 rounded-3xl shadow-[0_25px_60px_rgba(0,0,0,0.6)] text-center relative text-gray-900">
      <div className="inline-flex items-center gap-2 bg-emerald-100 text-emerald-800 text-xs font-black px-3.5 py-1.5 rounded-full border border-emerald-200 mb-4 uppercase tracking-wider">
        <span className="w-2 h-2 rounded-full bg-emerald-600 animate-ping" />
        Demonstração Interativa
      </div>
      <h2 className="text-2xl font-black text-gray-950 mb-2">
        Experimente Raspar Agora!
      </h2>
      <p className="text-sm text-gray-600 mb-6 font-medium leading-relaxed">
        Clique no cartão abaixo para simular a raspadinha que você ganha a cada gol.
      </p>

      <div
        onClick={() => setScratched(true)}
        role="button"
        tabIndex={0}
        aria-label="Simulador de Raspadinha do Gol - Clique para raspar e revelar prêmio"
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") setScratched(true);
        }}
        className={`relative w-full h-56 rounded-2xl cursor-pointer overflow-hidden transition-all duration-500 transform hover:scale-[1.02] shadow-2xl border-2 ${
          scratched ? "border-amber-400" : "border-emerald-400/50"
        }`}
      >
        {/* Layer 1: Content Revealed */}
        <div className="absolute inset-0 bg-gradient-to-br from-emerald-900 via-[#052313] to-emerald-950 flex flex-col items-center justify-center p-6 text-center">
          <div className="text-5xl mb-2 animate-bounce" aria-hidden="true">🏆</div>
          <span className="text-amber-400 font-black text-2xl drop-shadow-md uppercase">
            VOCÊ GANHOU!
          </span>
          <span className="text-white font-bold text-lg mt-1">
            +500 TOKENS DO GOL
          </span>
          <span className="text-xs text-emerald-200 mt-2 bg-emerald-900/70 px-3 py-1 rounded-full border border-emerald-500/40">
            Baixe o App agora para resgatar seu bônus inicial!
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
          <div className="w-16 h-16 bg-black/20 rounded-full flex items-center justify-center mb-3 text-2xl text-[#03150b] font-bold border border-black/10" aria-hidden="true">
            ✨
          </div>
          <span className="text-[#03150b] font-black text-xl tracking-tight uppercase">
            RASPE AQUI
          </span>
          <span className="text-[#041d10] text-xs font-semibold mt-1 bg-black/10 px-3 py-1 rounded-full">
            Clique para revelar seu prêmio!
          </span>
        </div>
      </div>

      <div className="mt-4">
        {scratched ? (
          <div className="animate-fadeIn">
            <a
              href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 w-full bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-[#03150b] font-black text-sm py-3 px-6 rounded-xl shadow-[0_0_25px_rgba(251,191,36,0.5)] transition-all uppercase tracking-wide hover:scale-[1.02]"
            >
              🎁 Resgatar Bônus no App →
            </a>
            <p className="text-[11px] text-emerald-200/80 mt-2 font-medium">
              Instale grátis na Google Play para começar com tokens!
            </p>
          </div>
        ) : (
          <p className="text-xs text-gray-700 font-bold flex items-center justify-center gap-1.5 py-2">
            <span>👆</span> Clique na cartela dourada acima para testar
          </p>
        )}
      </div>
    </div>
  );
}
