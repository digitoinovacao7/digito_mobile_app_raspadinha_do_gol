import { Link, Outlet, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { ShareAppModal } from './ShareAppModal';

export function Layout() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isShareModalOpen, setIsShareModalOpen] = useState(false);
  const location = useLocation();
  const isHome = location.pathname === '/';

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 50) {
        setIsScrolled(true);
      } else {
        setIsScrolled(false);
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const headerClass = `w-full text-white py-4 transition-all duration-300 fixed top-0 z-50 ${
    isHome && !isScrolled ? 'bg-transparent' : 'bg-[#052313]/95 border-b border-emerald-800/50 backdrop-blur-md shadow-lg'
  }`;

  return (
    <div className="min-h-screen flex flex-col items-center bg-[#041d10]">
      <header className={headerClass}>
        <div className="container mx-auto px-4 flex justify-between items-center">
          <Link to="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <img src="/logo_transparent.png" alt="Logo oficial da Raspadinha do Gol - App de futebol e prêmios grátis" className="w-12 h-12 object-contain" />
            <span className="text-2xl font-bold tracking-tight drop-shadow-md">Raspadinha do Gol</span>
          </Link>
          <nav className="hidden md:flex gap-5 font-semibold items-center drop-shadow-md">
            <Link to="/" onClick={() => window.scrollTo(0, 0)} className="hover:text-accent transition-colors">Início</Link>
            <a href="/#jogos-hoje" className="hover:text-accent transition-colors">Jogos de Hoje</a>
            <a href="/#bolao" className="text-amber-300 hover:text-accent transition-colors flex items-center gap-1.5">
              <span>🏆</span> Bolão do Gol
            </a>
            <Link to="/como-funciona" onClick={() => window.scrollTo(0, 0)} className="hover:text-accent transition-colors">Como Funciona</Link>
            <Link to="/faq" onClick={() => window.scrollTo(0, 0)} className="hover:text-accent transition-colors">Dúvidas (FAQ)</Link>
            
            <button
              onClick={() => setIsShareModalOpen(true)}
              className="text-emerald-100/90 hover:text-accent transition-colors flex items-center gap-1.5 cursor-pointer font-semibold text-sm"
              title="Compartilhar aplicativo com amigos"
            >
              <span>📢</span> Compartilhar
            </button>

            <a href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol" target="_blank" rel="noopener noreferrer" className="bg-accent text-text-dark px-4 py-2 rounded-lg hover:brightness-110 transition-all font-bold drop-shadow-none">
              Baixar App
            </a>
          </nav>
          
          {/* Mobile Menu Button */}
          <button 
            className="md:hidden text-white hover:text-accent p-2"
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            aria-label={isMobileMenuOpen ? "Fechar menu de navegação" : "Abrir menu de navegação"}
          >
            <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {isMobileMenuOpen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
        </div>

        {/* Mobile Menu Dropdown */}
        {isMobileMenuOpen && (
          <div className="md:hidden bg-[#052313]/98 backdrop-blur-md border-t border-emerald-800/60 absolute top-full left-0 w-full flex flex-col p-4 shadow-xl text-white">
            <Link to="/" onClick={() => { setIsMobileMenuOpen(false); window.scrollTo(0, 0); }} className="py-3 text-lg font-semibold hover:text-accent border-b border-emerald-800/50">Início</Link>
            <a href="/#jogos-hoje" onClick={() => setIsMobileMenuOpen(false)} className="py-3 text-lg font-semibold hover:text-accent border-b border-emerald-800/50">Jogos de Hoje</a>
            <a href="/#bolao" onClick={() => setIsMobileMenuOpen(false)} className="py-3 text-lg font-semibold text-amber-300 hover:text-accent border-b border-emerald-800/50">🏆 Bolão do Gol (Galera & Bares)</a>
            <Link to="/como-funciona" onClick={() => { setIsMobileMenuOpen(false); window.scrollTo(0, 0); }} className="py-3 text-lg font-semibold hover:text-accent border-b border-emerald-800/50">Como Funciona</Link>
            <Link to="/faq" onClick={() => { setIsMobileMenuOpen(false); window.scrollTo(0, 0); }} className="py-3 text-lg font-semibold hover:text-accent border-b border-emerald-800/50">Dúvidas (FAQ)</Link>
            <Link to="/suporte" onClick={() => { setIsMobileMenuOpen(false); window.scrollTo(0, 0); }} className="py-3 text-lg font-semibold text-amber-300 hover:text-accent border-b border-emerald-800/50 flex items-center gap-2">
              <span>🎧</span> Suporte & Atendimento
            </Link>
            
            {/* Opção de Compartilhar no Menu Mobile */}
            <button
              onClick={() => { setIsMobileMenuOpen(false); setIsShareModalOpen(true); }}
              className="py-3 text-lg font-semibold text-amber-300 hover:text-accent border-b border-emerald-800/50 flex items-center gap-2 cursor-pointer text-left"
            >
              <span>📢</span> Compartilhar com Amigos
            </button>

            <a href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol" target="_blank" rel="noopener noreferrer" className="mt-4 bg-accent text-text-dark text-lg px-4 py-3 rounded-xl font-bold text-center hover:scale-[1.02] transition-transform">Baixar App</a>
          </div>
        )}
      </header>

      <main className={`flex-1 w-full flex flex-col items-center bg-[#041d10] ${isHome ? '' : 'pt-[80px]'}`}>
        <Outlet />
      </main>

      <footer className="w-full bg-[#03170c] text-gray-200 py-16 border-t border-emerald-800/60">
        <div className="container mx-auto px-6 max-w-6xl">
          <div className="grid grid-cols-1 md:grid-cols-5 gap-12 mb-12">
            <div className="col-span-1 md:col-span-2">
              <Link to="/" onClick={() => window.scrollTo(0, 0)} className="flex items-center gap-3 mb-6 hover:opacity-90 transition-opacity">
                <img src="/logo_transparent.png" alt="Raspadinha do Gol" className="w-12 h-12 object-contain filter drop-shadow-md" />
                <h2 className="text-2xl font-bold text-white tracking-tight">Raspadinha do Gol</h2>
              </Link>
              <p className="text-sm text-emerald-100/75 leading-relaxed max-w-sm mb-6">
                A plataforma mais inovadora de quizzes esportivos, raspadinhas ao vivo e Bolão entre amigos e bares. Mostre que você entende de futebol, acumule tokens e resgate prêmios incríveis de forma segura e transparente.
              </p>
              <div className="flex items-center gap-4">
                <div className="flex items-center justify-center w-10 h-10 rounded-full bg-emerald-900/80 text-white font-bold text-xs border border-emerald-700/70">18+</div>
                <div className="flex items-center gap-2 text-sm text-emerald-300 font-semibold bg-emerald-500/15 px-3 py-1.5 rounded-full border border-emerald-400/30">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"></path></svg>
                  Site Seguro & Sem Apostas
                </div>
              </div>
            </div>

            <div>
              <h3 className="text-white font-bold mb-6 uppercase tracking-wider text-sm">Links Úteis</h3>
              <ul className="space-y-4">
                <li><Link to="/suporte" onClick={() => window.scrollTo(0, 0)} className="text-amber-300 hover:text-white transition-colors text-sm font-bold flex items-center gap-1.5"><span>🎧</span> Suporte & Atendimento</Link></li>
                <li><Link to="/sobre-nos" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-accent transition-colors text-sm">Sobre Nós</Link></li>
                <li><a href="/#bolao" className="text-amber-300 hover:text-accent transition-colors text-sm font-semibold">🏆 Bolão do Gol</a></li>
                <li><Link to="/como-funciona" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-accent transition-colors text-sm">Como Funciona</Link></li>
                <li><Link to="/faq" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-accent transition-colors text-sm">Dúvidas Frequentes (FAQ)</Link></li>
                <li><button onClick={() => setIsShareModalOpen(true)} className="text-emerald-100/70 hover:text-white transition-colors text-sm flex items-center gap-1.5 cursor-pointer"><span>📢</span> Compartilhar o Aplicativo</button></li>
                <li><a href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol" target="_blank" rel="noopener noreferrer" className="text-emerald-100/70 hover:text-accent transition-colors text-sm">Baixar o Aplicativo</a></li>
              </ul>
            </div>

            <div>
              <h3 className="text-white font-bold mb-6 uppercase tracking-wider text-sm">Legal</h3>
              <ul className="space-y-4">
                <li><Link to="/regulamento" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-white transition-colors text-sm">Regulamento</Link></li>
                <li><Link to="/termos" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-white transition-colors text-sm">Termos de Uso</Link></li>
                <li><Link to="/privacidade" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-white transition-colors text-sm">Política de Privacidade</Link></li>
                <li><Link to="/jogo-responsavel" onClick={() => window.scrollTo(0, 0)} className="text-emerald-100/70 hover:text-white transition-colors text-sm">Uso Consciente</Link></li>
              </ul>
            </div>

            <div>
              <h3 className="text-white font-bold mb-6 uppercase tracking-wider text-sm">Suporte & Redes</h3>
              <ul className="space-y-4">
                <li>
                  <Link to="/suporte" onClick={() => window.scrollTo(0, 0)} className="text-amber-300 hover:text-white transition-colors text-sm font-bold flex items-center gap-2">
                    <span>🎧</span> Central de Suporte
                  </Link>
                </li>
                <li>
                  <a href="https://www.youtube.com/@guiadoplayeroficial" target="_blank" rel="noopener noreferrer" className="text-emerald-100/70 hover:text-red-400 transition-colors text-sm flex items-center gap-2">
                    <span>▶️</span> YouTube (@guiadoplayeroficial)
                  </a>
                </li>
                <li>
                  <a href="https://www.tiktok.com/@guiadoplayeroficial" target="_blank" rel="noopener noreferrer" className="text-emerald-100/70 hover:text-cyan-400 transition-colors text-sm flex items-center gap-2">
                    <span>🎵</span> TikTok (@guiadoplayeroficial)
                  </a>
                </li>
              </ul>
            </div>
          </div>

          <div className="pt-8 border-t border-emerald-800/50 flex flex-col md:flex-row justify-between items-center gap-4 text-xs text-emerald-200/60 pb-20 md:pb-8">
            <p>LUVTEK - CNPJ: 43.531.480/0001-20</p>
            <p>© {new Date().getFullYear()} Dígito Inovação - Raspadinha do Gol. Todos os direitos reservados.</p>
          </div>
        </div>
      </footer>

      {/* Sticky Bottom Bar (Mobile Only) */}
      <div className="md:hidden fixed bottom-0 left-0 w-full bg-[#052313] border-t border-emerald-700/70 p-4 z-50 flex justify-between items-center shadow-[0_-10px_30px_rgba(0,0,0,0.6)]">
        <div className="flex flex-col">
          <span className="text-white font-black text-sm">RASPADINHA & BOLÃO 🏆</span>
          <span className="text-accent text-xs font-bold">Jogos Ao Vivo Liberados</span>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsShareModalOpen(true)}
            aria-label="Compartilhar aplicativo com amigos"
            className="bg-emerald-900/90 text-amber-300 hover:text-white border border-emerald-500/50 p-2.5 rounded-full flex items-center justify-center cursor-pointer shadow-md"
            title="Compartilhar App"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
            </svg>
          </button>
          <a href="https://play.google.com/store/apps/details?id=br.com.digitoinovacao.raspadinha_do_gol" target="_blank" rel="noopener noreferrer" className="bg-green-500 text-white px-5 py-2.5 rounded-full font-black uppercase text-xs shadow-[0_0_15px_rgba(34,197,94,0.6)] animate-pulse">
            BAIXAR APP
          </a>
        </div>
      </div>

      {/* Modal de Compartilhamento do App */}
      <ShareAppModal isOpen={isShareModalOpen} onClose={() => setIsShareModalOpen(false)} />
    </div>
  );
}
