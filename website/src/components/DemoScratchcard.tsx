import { useState } from "react";

export function DemoScratchcard() {
  const [scratched, setScratched] = useState(false);

  return (
    <div className="w-full max-w-xs sm:max-w-sm bg-[#062414]/90 backdrop-blur-xl border border-emerald-500/40 p-4 sm:p-5 rounded-2xl shadow-2xl text-center relative text-white">
      {/* Compact Header */}
      <div className="flex items-center justify-between mb-3 px-1">
        <span className="inline-flex items-center gap-1.5 text-amber-400 text-[11px] font-black uppercase tracking-wider bg-amber-400/15 border border-amber-400/30 px-2.5 py-0.5 rounded-full">
          <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-ping" />
          Simulação
        </span>
        <span className="text-xs font-bold text-emerald-200/80">
          Gols = Raspadinhas ⚽
        </span>
      </div>

      {/* Interactive Scratch Foil - Compact Height */}
      <div
        onClick={() => setScratched(true)}
        role="button"
        tabIndex={0}
        aria-label="Simulador de Raspadinha - Toque para raspar"
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") setScratched(true);
        }}
        className={`relative w-full h-36 rounded-xl cursor-pointer overflow-hidden transition-all duration-300 transform hover:scale-[1.02] shadow-lg border ${
          scratched ? "border-amber-400" : "border-amber-400/60"
        }`}
      >
        {/* Layer 1: Content Revealed */}
        <div className="absolute inset-0 bg-gradient-to-br from-emerald-900 via-[#052313] to-emerald-950 flex flex-col items-center justify-center p-3 text-center">
          <div className="text-3xl mb-1 animate-bounce" aria-hidden="true">🏆</div>
          <span className="text-amber-400 font-black text-lg drop-shadow uppercase leading-none">
            GOL! VOCÊ GANHOU!
          </span>
          <span className="text-white font-extrabold text-sm mt-1">
            +500 TOKENS DO GOL
          </span>
          <span className="text-[10px] text-emerald-200 mt-1 bg-emerald-900/80 px-2 py-0.5 rounded-full border border-emerald-500/30">
            Troque por prêmios físicos no app!
          </span>
        </div>

        {/* Layer 2: Scratch Foil */}
        <div
          className={`absolute inset-0 bg-gradient-to-tr from-amber-500 via-yellow-400 to-amber-600 flex flex-col items-center justify-center p-3 transition-all duration-500 ${
            scratched
              ? "opacity-0 pointer-events-none scale-110"
              : "opacity-100"
          }`}
        >
          <div className="w-10 h-10 bg-black/15 rounded-full flex items-center justify-center mb-1 text-lg text-[#03150b] font-bold border border-black/10">
            ✨
          </div>
          <span className="text-[#03150b] font-black text-base tracking-tight uppercase">
            TOQUE PARA RASPAR
          </span>
          <span className="text-[#041d10] text-[11px] font-bold mt-0.5 bg-black/10 px-2 py-0.5 rounded-full">
            Simule o prêmio de um gol
          </span>
        </div>
      </div>

      {/* Bottom Action / Feedback */}
      <div className="mt-3">
        {scratched ? (
          <div className="animate-fadeIn">
            <a
              href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-1.5 w-full bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-[#03150b] font-black text-xs py-2.5 px-4 rounded-xl shadow-md transition-all uppercase tracking-wide hover:scale-[1.02]"
            >
              🎁 Resgatar Bônus no App →
            </a>
          </div>
        ) : (
          <p className="text-[11px] text-emerald-100/70 font-semibold flex items-center justify-center gap-1">
            <span>👆</span> Toque no cartão acima para testar
          </p>
        )}
      </div>
    </div>
  );
}
