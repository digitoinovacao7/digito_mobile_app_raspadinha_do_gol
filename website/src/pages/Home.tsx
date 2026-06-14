import { Link } from 'react-router-dom';

export function Home() {
  return (
    <>
      {/* Hero Section */}
      <section className="w-full bg-primary text-white py-20 px-4 relative overflow-hidden flex flex-col items-center">
        <div className="absolute inset-0 bg-black/20"></div> {/* Overlay */}
        
        <div className="relative z-10 max-w-4xl mx-auto text-center flex flex-col items-center">
          <img src="/logo.png" alt="Raspadinha do Gol" className="w-48 h-48 mb-8 drop-shadow-2xl animate-bounce" style={{animationDuration: '3s'}} />
          <h2 className="text-4xl md:text-6xl font-extrabold mb-6 leading-tight">
            Sua torcida vale <span className="text-accent drop-shadow-md">PIX na hora!</span>
          </h2>
          <p className="text-lg md:text-2xl mb-10 text-gray-100 max-w-2xl">
            Assista aos jogos ao vivo e ganhe raspadinhas exclusivas a cada gol, no intervalo e no fim da partida. Encontrou 3 bolas de futebol? O PIX cai na sua conta!
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <a href="https://app-raspadinhadogol.web.app" className="bg-accent text-text-dark text-xl px-8 py-4 rounded-xl font-bold hover:scale-105 transition-transform shadow-lg shadow-accent/30 text-center">
              Quero Participar
            </a>
            <Link to="/regulamento" className="bg-white/10 border-2 border-white/50 backdrop-blur-sm text-white text-xl px-8 py-4 rounded-xl font-bold hover:bg-white/20 transition-colors text-center">
              Ver Regulamento
            </Link>
          </div>
        </div>
      </section>

      {/* Features / Como Funciona */}
      <section id="como-funciona" className="py-20 px-4 w-full bg-white">
        <div className="max-w-6xl mx-auto">
          <h3 className="text-3xl md:text-4xl font-bold text-center mb-16 text-primary">Como Funciona?</h3>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-bg-light p-8 rounded-2xl shadow-sm text-center border-t-4 border-primary hover:-translate-y-2 transition-transform">
              <div className="w-16 h-16 bg-primary/10 text-primary rounded-full flex items-center justify-center mx-auto mb-6 text-2xl font-black">1</div>
              <h4 className="text-xl font-bold mb-4">Acompanhe o Jogo</h4>
              <p className="text-gray-600">Fique de olho nas partidas de futebol ao vivo diretamente pelo aplicativo.</p>
            </div>

            <div className="bg-bg-light p-8 rounded-2xl shadow-sm text-center border-t-4 border-accent hover:-translate-y-2 transition-transform">
              <div className="w-16 h-16 bg-accent/20 text-yellow-600 rounded-full flex items-center justify-center mx-auto mb-6 text-2xl font-black">2</div>
              <h4 className="text-xl font-bold mb-4">Gatilho de Liberação</h4>
              <p className="text-gray-600">Saiu Gol? Intervalo? Fim de jogo? A sua primeira raspadinha da partida é 100% grátis.</p>
            </div>

            <div className="bg-bg-light p-8 rounded-2xl shadow-sm text-center border-t-4 border-primary hover:-translate-y-2 transition-transform">
              <div className="w-16 h-16 bg-primary/10 text-primary rounded-full flex items-center justify-center mx-auto mb-6 text-2xl font-black">3</div>
              <h4 className="text-xl font-bold mb-4">Raspe e Ganhe PIX</h4>
              <p className="text-gray-600">Revele 3 bolas de futebol no grid 3x3 e solicite o seu prêmio via PIX instantaneamente.</p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
