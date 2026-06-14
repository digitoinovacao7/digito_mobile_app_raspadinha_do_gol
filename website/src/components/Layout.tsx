import { Link, Outlet } from 'react-router-dom';

export function Layout() {
  return (
    <div className="min-h-screen flex flex-col items-center bg-bg-light">
      <header className="w-full bg-primary text-white py-4 shadow-md sticky top-0 z-50">
        <div className="container mx-auto px-4 flex justify-between items-center">
          <Link to="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <img src="/logo.png" alt="Raspadinha do Gol" className="w-12 h-12 object-contain" />
            <h1 className="text-2xl font-bold tracking-tight">Raspadinha do Gol</h1>
          </Link>
          <nav className="hidden md:flex gap-6 font-semibold items-center">
            <a href="/#como-funciona" className="hover:text-accent transition-colors">Como Funciona</a>
            <a href="https://app-raspadinhadogol.web.app" className="bg-accent text-text-dark px-4 py-2 rounded-lg hover:brightness-110 transition-all font-bold">
              Baixar App
            </a>
          </nav>
        </div>
      </header>

      <main className="flex-1 w-full flex flex-col items-center bg-bg-light">
        <Outlet />
      </main>

      <footer className="w-full bg-text-dark text-gray-400 py-8">
        <div className="container mx-auto px-4 flex flex-col items-center">
          <div className="flex flex-wrap justify-center gap-6 mb-6">
            <Link to="/regulamento" className="hover:text-white transition-colors">Regulamento</Link>
            <Link to="/privacidade" className="hover:text-white transition-colors">Política de Privacidade</Link>
            <Link to="/termos" className="hover:text-white transition-colors">Termos de Uso</Link>
            <Link to="/jogo-responsavel" className="hover:text-white transition-colors">Jogo Responsável</Link>
          </div>
          <p className="mb-2">LUVTEK - CNPJ: 43.531.480/0001-20</p>
          <p>© 2026 Dígito Inovação - Raspadinha do Gol. Todos os direitos reservados.</p>
        </div>
      </footer>
    </div>
  );
}
