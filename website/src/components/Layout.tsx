import { Link, Outlet, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';

export function Layout() {
  const [isScrolled, setIsScrolled] = useState(false);
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
    isHome && !isScrolled ? 'bg-transparent' : 'bg-primary shadow-md'
  }`;

  return (
    <div className="min-h-screen flex flex-col items-center bg-bg-light">
      <header className={headerClass}>
        <div className="container mx-auto px-4 flex justify-between items-center">
          <Link to="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <img src="/logo_transparent.png" alt="Raspadinha do Gol" className="w-12 h-12 object-contain" />
            <h1 className="text-2xl font-bold tracking-tight drop-shadow-md">Raspadinha do Gol</h1>
          </Link>
          <nav className="hidden md:flex gap-6 font-semibold items-center drop-shadow-md">
            <a href="/#como-funciona" className="hover:text-accent transition-colors">Como Funciona</a>
            <a href="https://app-raspadinhadogol.web.app" className="bg-accent text-text-dark px-4 py-2 rounded-lg hover:brightness-110 transition-all font-bold drop-shadow-none">
              Baixar App
            </a>
          </nav>
        </div>
      </header>

      <main className={`flex-1 w-full flex flex-col items-center bg-bg-light ${isHome ? '' : 'pt-[80px]'}`}>
        <Outlet />
      </main>

      <footer className="w-full bg-slate-900 text-gray-300 py-16 border-t border-slate-800">
        <div className="container mx-auto px-6 max-w-6xl">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
            <div className="col-span-1 md:col-span-2">
              <Link to="/" onClick={() => window.scrollTo(0, 0)} className="flex items-center gap-3 mb-6 hover:opacity-90 transition-opacity">
                <img src="/logo_transparent.png" alt="Raspadinha do Gol" className="w-12 h-12 object-contain filter drop-shadow-md" />
                <h2 className="text-2xl font-bold text-white tracking-tight">Raspadinha do Gol</h2>
              </Link>
              <p className="text-sm text-gray-400 leading-relaxed max-w-sm mb-6">
                A plataforma mais inovadora de quizzes esportivos. Mostre que você entende de futebol, acumule tokens e resgate prêmios incríveis de forma segura e transparente.
              </p>
              <div className="flex items-center gap-4">
                <div className="flex items-center justify-center w-10 h-10 rounded-full bg-slate-800 text-white font-bold text-xs border border-slate-700">18+</div>
                <div className="flex items-center gap-2 text-sm text-emerald-400 font-semibold bg-emerald-400/10 px-3 py-1.5 rounded-full border border-emerald-400/20">
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"></path></svg>
                  Site Seguro
                </div>
              </div>
            </div>

            <div>
              <h3 className="text-white font-bold mb-6 uppercase tracking-wider text-sm">Links Úteis</h3>
              <ul className="space-y-4">
                <li><Link to="/#como-funciona" className="text-gray-400 hover:text-accent transition-colors text-sm">Como Funciona</Link></li>
                <li><Link to="/faq" onClick={() => window.scrollTo(0, 0)} className="text-gray-400 hover:text-accent transition-colors text-sm">Dúvidas Frequentes (FAQ)</Link></li>
                <li><a href="https://app-raspadinhadogol.web.app" className="text-gray-400 hover:text-accent transition-colors text-sm">Baixar o Aplicativo</a></li>
              </ul>
            </div>

            <div>
              <h3 className="text-white font-bold mb-6 uppercase tracking-wider text-sm">Legal</h3>
              <ul className="space-y-4">
                <li><Link to="/regulamento" onClick={() => window.scrollTo(0, 0)} className="text-gray-400 hover:text-white transition-colors text-sm">Regulamento</Link></li>
                <li><Link to="/termos" onClick={() => window.scrollTo(0, 0)} className="text-gray-400 hover:text-white transition-colors text-sm">Termos de Uso</Link></li>
                <li><Link to="/privacidade" onClick={() => window.scrollTo(0, 0)} className="text-gray-400 hover:text-white transition-colors text-sm">Política de Privacidade</Link></li>
                <li><Link to="/jogo-responsavel" onClick={() => window.scrollTo(0, 0)} className="text-gray-400 hover:text-white transition-colors text-sm">Jogo Responsável</Link></li>
              </ul>
            </div>
          </div>

          <div className="pt-8 border-t border-slate-800 flex flex-col md:flex-row justify-between items-center gap-4 text-xs text-gray-500">
            <p>LUVTEK - CNPJ: 43.531.480/0001-20</p>
            <p>© {new Date().getFullYear()} Dígito Inovação - Raspadinha do Gol. Todos os direitos reservados.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
