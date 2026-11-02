import { useState, useEffect } from 'react';
import { collection, query, where, limit, getDocs } from 'firebase/firestore';
import { db } from '../firebase';

interface PrizeData {
  id: string;
  name: string;
  image_url?: string;
  imageUrl?: string;
  leagueName?: string;
  matchLabel?: string;
  token_cost?: number;
  type?: string;
}

export function PrizeModal() {
  const [isOpen, setIsOpen] = useState(false);
  const [prize, setPrize] = useState<PrizeData | null>(null);

  useEffect(() => {

    async function loadPrize() {
      try {
        const q = query(
          collection(db, 'prizes'),
          where('active', '==', true),
          limit(1)
        );
        const snap = await getDocs(q);
        if (!snap.empty) {
          const doc = snap.docs[0];
          setPrize({ id: doc.id, ...(doc.data() as any) });
        } else {
          // Fallback para exibir o prêmio de destaque
          setPrize({
            id: 'default-prize',
            name: 'Camisa Oficial de Time ou Tênis Modelo Premium',
            image_url: 'https://firebasestorage.googleapis.com/v0/b/shop-isa-314113.firebasestorage.app/o/products%2FZRac5rRanI4x1c7iCP58%2F1786329822895-imported.jpg?alt=media&token=8be4663d-e083-43fb-9e84-01fd101c898e',
            leagueName: 'Brasileirão & Copas',
            token_cost: 1200,
          });
        }
      } catch (err) {
        console.error('Erro ao buscar prêmio para o modal:', err);
        setPrize({
          id: 'default-prize',
          name: 'Camisa Oficial de Clube ou Tênis Premium',
          image_url: 'https://firebasestorage.googleapis.com/v0/b/shop-isa-314113.firebasestorage.app/o/products%2FZRac5rRanI4x1c7iCP58%2F1786329822895-imported.jpg?alt=media&token=8be4663d-e083-43fb-9e84-01fd101c898e',
          leagueName: 'Brasileirão & Copas',
          token_cost: 1200,
        });
      }

      // Pequeno delay para a página carregar suavemente
      const timer = setTimeout(() => {
        setIsOpen(true);
      }, 800);
      return () => clearTimeout(timer);
    }

    loadPrize();
  }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setIsOpen(false);
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen]);

  if (!isOpen || !prize) return null;

  const prizeImage = prize.image_url || prize.imageUrl || '';
  const championship = prize.leagueName || prize.matchLabel || 'Brasileirão & Copas';
  const playStoreUrl = 'https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
      <div 
        className="relative w-full max-w-lg bg-[#062414] border border-amber-400/40 rounded-3xl shadow-2xl overflow-hidden text-white"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Header */}
        <div className="bg-gradient-to-r from-emerald-950 via-[#0a381f] to-emerald-950 p-5 border-b border-emerald-800/80 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="w-10 h-10 rounded-2xl bg-amber-400/20 border border-amber-400/50 flex items-center justify-center text-amber-400 text-xl font-black shadow-md">
              🏆
            </span>
            <div>
              <span className="text-[10px] uppercase font-black tracking-widest text-amber-400 block">
                PRÊMIO ATIVO DA RODADA ⚽
              </span>
              <h3 className="text-base font-black text-white leading-tight">
                Concorra ao Vivo Assistindo ao Jogo!
              </h3>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setIsOpen(false)}
            className="w-8 h-8 rounded-full bg-emerald-900/60 hover:bg-emerald-800 border border-emerald-700/60 text-white flex items-center justify-center transition-all cursor-pointer"
            aria-label="Fechar"
          >
            ✕
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6">
          {/* Championship Tag */}
          <div className="flex items-center justify-center mb-3">
            <span className="bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs font-bold px-3 py-1 rounded-full flex items-center gap-1.5">
              <span>⚽</span> {championship}
            </span>
          </div>

          {/* Prize Image */}
          {prizeImage && (
            <div className="w-full h-44 bg-white/5 rounded-2xl border border-white/10 flex items-center justify-center p-3 mb-4 overflow-hidden shadow-inner">
              <img
                src={prizeImage}
                alt={prize.name}
                className="max-h-full max-w-full object-contain rounded-xl hover:scale-105 transition-transform"
              />
            </div>
          )}

          {/* Prize Title */}
          <h4 className="text-xl font-black text-center text-white mb-2 leading-snug">
            {prize.name}
          </h4>

          {/* Physical Prize Badge */}
          <div className="flex items-center justify-center gap-2 mb-4">
            <span className="bg-amber-400/20 border border-amber-400/40 text-amber-300 text-xs font-bold px-3 py-1 rounded-lg">
              📦 Prêmio Físico Entregue na Sua Casa
            </span>
          </div>

          {/* O PAPEL REAL DOS TOKENS */}
          <div className="bg-[#03180c] border border-emerald-700/60 rounded-2xl p-4 mb-5 text-left">
            <div className="flex items-center gap-2 mb-1.5">
              <span className="text-amber-400 font-black text-sm">🪙 Qual o Papel Real dos Tokens?</span>
            </div>
            <p className="text-xs text-emerald-100/80 leading-relaxed">
              Tokens <strong>NÃO são dinheiro e NÃO são apostas!</strong> Você ganha Tokens 100% grátis acertando quizzes com IA e participando da torcida. O papel real dos Tokens é <strong>trocar por cartelas de Raspadinha</strong>, onde você raspa e concorre a prêmios físicos reais (como este!) entregues na sua casa com frete e rastreio!
            </p>
          </div>

          {/* Actions */}
          <div className="flex flex-col gap-2.5">
            <a
              href={playStoreUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-amber-400 via-amber-500 to-yellow-500 text-gray-950 font-black text-sm uppercase tracking-wider text-center shadow-lg hover:scale-[1.02] transition-all flex items-center justify-center gap-2"
            >
              <span>⚡</span> BAIXAR APP & CONCORRER NA GOOGLE PLAY
            </a>
            <button
              type="button"
              onClick={() => setIsOpen(false)}
              className="w-full py-2.5 text-xs font-bold text-emerald-300/80 hover:text-white transition-colors cursor-pointer text-center"
            >
              Continuar navegando no site
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
