import { useState, useEffect } from 'react';

interface ShareAppModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function ShareAppModal({ isOpen, onClose }: ShareAppModalProps) {
  const [copied, setCopied] = useState(false);

  // Link oficial da Google Play Store
  const playStoreUrl = 'https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol';

  // Mensagem pronta e completa com prêmio e campeonatos
  const readyMessage = `🏆🔥 GANHEI PRÊMIO NA RASPADINHA DO GOL!

Acabei de resgatar prêmio oficial acertando palpites e raspando cartelas nos jogos do Brasileirão e Libertadores! ⚽👕

Mostre que você também entende de futebol, venha dar seus palpites nos jogos de hoje e crie o Bolão da galera comigo:

📲 Baixe grátis na Google Play:
${playStoreUrl}`;

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
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
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const handleCopy = async () => {
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(readyMessage);
      } else {
        const textarea = document.createElement('textarea');
        textarea.value = readyMessage;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch (err) {
      console.error('Falha ao copiar:', err);
    }
  };

  const handleNativeShare = async () => {
    if (typeof navigator !== 'undefined' && navigator.share) {
      try {
        await navigator.share({
          title: 'Raspadinha do Gol ⚽',
          text: readyMessage,
          url: playStoreUrl,
        });
      } catch (err) {
        // Usuário cancelou
      }
    } else {
      handleCopy();
    }
  };

  const whatsappUrl = `https://api.whatsapp.com/send?text=${encodeURIComponent(readyMessage)}`;
  const telegramUrl = `https://t.me/share/url?url=${encodeURIComponent(playStoreUrl)}&text=${encodeURIComponent('🏆 Ganhei prêmio na Raspadinha do Gol! Baixe grátis e venha jogar comigo:')}`;

  return (
    <div 
      className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fadeIn"
      onClick={onClose}
    >
      <div 
        className="relative w-full max-w-md bg-white border border-gray-100 rounded-3xl p-6 sm:p-7 shadow-[0_25px_70px_rgba(0,0,0,0.5)] text-gray-900"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Botão Fechar */}
        <button
          onClick={onClose}
          aria-label="Fechar"
          className="absolute top-4 right-4 w-9 h-9 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-900 flex items-center justify-center transition-all cursor-pointer z-10"
        >
          ✕
        </button>

        {/* Header */}
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-amber-400 to-amber-500 flex items-center justify-center text-2xl shadow-md shrink-0">
            📢
          </div>
          <div>
            <h3 className="text-xl font-black text-gray-950">Compartilhe com Amigos</h3>
            <p className="text-xs text-gray-500 font-semibold">Mensagem pronta para grupos e resenhas!</p>
          </div>
        </div>

        {/* Balão de Mensagem Pronta (Estilo WhatsApp) */}
        <div className="mb-5 bg-gray-50 border border-gray-200 rounded-2xl p-4 shadow-sm">
          <div className="flex items-center justify-between mb-2 pb-2 border-b border-gray-200">
            <span className="text-[11px] font-black uppercase tracking-wider text-emerald-700">
              💬 Mensagem Pronta para Envio:
            </span>
            <span className="text-[10px] text-amber-800 font-bold bg-amber-100 px-2 py-0.5 rounded-full border border-amber-200">
              Prêmio & Campeonatos
            </span>
          </div>

          <p className="text-xs text-gray-700 leading-relaxed whitespace-pre-line font-sans">
            <strong className="text-gray-950 font-black">🏆🔥 GANHEI PRÊMIO NA RASPADINHA DO GOL!</strong>
            {'\n\n'}
            Acabei de resgatar prêmio oficial acertando palpites e raspando cartelas nos jogos do Brasileirão e Libertadores! ⚽👕
            {'\n\n'}
            Mostre que você também entende de futebol, venha dar seus palpites e disputar o Bolão comigo!
          </p>

          <div className="mt-3 pt-2 border-t border-gray-200 text-[11px] text-emerald-700 font-mono break-all font-bold">
            📲 {playStoreUrl}
          </div>
        </div>

        {/* Botões de Ação Direta */}
        <div className="space-y-2.5">
          <a
            href={whatsappUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center gap-2.5 w-full bg-[#25D366] hover:bg-[#20ba59] text-white font-black text-sm py-3.5 px-4 rounded-xl shadow-md transition-all hover:scale-[1.01] text-center"
          >
            <span className="text-xl">💬</span> Enviar no WhatsApp
          </a>

          <div className="grid grid-cols-2 gap-2.5">
            <a
              href={telegramUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2 bg-[#0088cc] hover:bg-[#0077b5] text-white font-black text-xs py-3 px-3 rounded-xl shadow transition-all text-center"
            >
              <span className="text-lg">✈️</span> Telegram
            </a>

            {typeof navigator !== 'undefined' && 'share' in navigator ? (
              <button
                type="button"
                onClick={handleNativeShare}
                className="flex items-center justify-center gap-2 bg-gray-900 hover:bg-gray-800 text-white font-black text-xs py-3 px-3 rounded-xl transition-all cursor-pointer shadow"
              >
                <span className="text-lg">📲</span> Mais Opções
              </button>
            ) : (
              <button
                type="button"
                onClick={handleCopy}
                className="flex items-center justify-center gap-2 bg-gray-900 hover:bg-gray-800 text-white font-black text-xs py-3 px-3 rounded-xl transition-all cursor-pointer shadow"
              >
                <span>📋</span> {copied ? '✓ Copiado!' : 'Copiar'}
              </button>
            )}
          </div>

          <button
            type="button"
            onClick={handleCopy}
            className={`w-full py-2.5 px-4 rounded-xl text-xs font-black uppercase tracking-wider transition-all cursor-pointer border ${
              copied
                ? 'bg-emerald-600 text-white border-emerald-600'
                : 'bg-white hover:bg-gray-50 text-gray-700 border-gray-300'
            }`}
          >
            {copied ? '✓ Mensagem e Link Copiados!' : '📋 Copiar Mensagem Completa'}
          </button>
        </div>
      </div>
    </div>
  );
}
