import React from 'react';

function App() {
  return (
    <div className="min-h-screen flex flex-col items-center bg-bg-light">
      {/* Header */}
      <header className="w-full bg-primary text-white py-4 shadow-md sticky top-0 z-50">
        <div className="container mx-auto px-4 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <img src="/logo.png" alt="Raspadinha do Gol" className="w-12 h-12 object-contain" />
            <h1 className="text-2xl font-bold tracking-tight">Raspadinha do Gol</h1>
          </div>
          <nav className="hidden md:flex gap-6 font-semibold">
            <a href="#como-funciona" className="hover:text-accent transition-colors">Como Funciona</a>
            <a href="#premios" className="hover:text-accent transition-colors">Prêmios PIX</a>
            <button className="bg-accent text-text-dark px-4 py-2 rounded-lg hover:brightness-110 transition-all font-bold">
              Baixar App
            </button>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1 w-full flex flex-col items-center">
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
              <button className="bg-accent text-text-dark text-xl px-8 py-4 rounded-xl font-bold hover:scale-105 transition-transform shadow-lg shadow-accent/30">
                Quero Participar
              </button>
              <button className="bg-white/10 border-2 border-white/50 backdrop-blur-sm text-white text-xl px-8 py-4 rounded-xl font-bold hover:bg-white/20 transition-colors">
                Ver Regulamento
              </button>
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
      </main>

      {/* Footer */}
      <footer className="w-full bg-text-dark text-gray-400 py-8 text-center">
        <p>© 2026 Dígito Inovação - Raspadinha do Gol. Todos os direitos reservados.</p>
      </footer>
    </div>
  );
}

export default App;
