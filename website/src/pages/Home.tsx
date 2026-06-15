import { Link } from 'react-router-dom';

export function Home() {
  return (
    <>
      {/* Hero Section */}
      <section className="w-full bg-primary text-white py-20 px-4 relative overflow-hidden flex flex-col md:flex-row items-center justify-center min-h-[80vh]">
        <div className="absolute inset-0 bg-black/40 z-0"></div> {/* Overlay darker for better contrast */}
        
        <div className="relative z-10 max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-12 w-full">
          {/* Left Content */}
          <div className="flex-1 flex flex-col items-center md:items-start text-center md:text-left">
            <div className="mb-8 drop-shadow-2xl">
              <img 
                src="/logo_transparent.png" 
                alt="Raspadinha do Gol" 
                className="w-48 h-48 object-contain" 
              />
            </div>
            <h2 className="text-4xl md:text-6xl font-extrabold mb-6 leading-tight">
              Sua torcida vale <span className="text-accent drop-shadow-md">PIX na hora!</span>
            </h2>
            <p className="text-lg md:text-2xl mb-10 text-gray-100 max-w-xl">
              Assista aos jogos ao vivo e ganhe raspadinhas exclusivas a cada gol, no intervalo e no fim da partida. Encontrou 3 bolas de futebol? O PIX cai na sua conta!
            </p>
            <div className="flex flex-col sm:flex-row gap-4 w-full md:w-auto">
              <a href="https://app-raspadinhadogol.web.app" className="bg-accent text-text-dark text-xl px-8 py-4 rounded-xl font-bold hover:scale-105 transition-transform shadow-lg shadow-accent/30 text-center">
                Quero Participar
              </a>
              <Link to="/regulamento" onClick={() => window.scrollTo(0, 0)} className="bg-white/10 border-2 border-white/50 backdrop-blur-sm text-white text-xl px-8 py-4 rounded-xl font-bold hover:bg-white/20 transition-colors text-center">
                Ver Regulamento
              </Link>
            </div>
          </div>

          {/* Right Content - Hero Image */}
          <div className="flex-1 flex justify-center items-center w-full max-w-md md:max-w-full">
             <img 
               src="/hero-football.png" 
               alt="Bola de Futebol Premium 3D" 
               className="w-full h-auto drop-shadow-[0_20px_50px_rgba(255,215,0,0.4)] animate-bounce"
               style={{ animationDuration: '4s' }}
             />
          </div>
        </div>
      </section>

      {/* Benefícios / Por que Escolher */}
      <section className="py-20 px-4 w-full bg-gray-50">
        <div className="max-w-6xl mx-auto text-center">
          <h3 className="text-3xl md:text-4xl font-bold mb-12 text-primary">Por que a Raspadinha do Gol?</h3>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-accent text-primary rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">⚡</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">Pix na Hora</h4>
              <p className="text-gray-600 text-lg">Ganhou? O dinheiro vai direto para a sua conta bancária em poucos minutos, sem burocracia.</p>
            </div>
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-primary text-white rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">⚽</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">Emoção ao Vivo</h4>
              <p className="text-gray-600 text-lg">Seu time fez gol? Você ganha uma raspadinha grátis. O jogo fica muito mais emocionante!</p>
            </div>
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-white text-primary border-4 border-primary rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">🔒</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">100% Seguro</h4>
              <p className="text-gray-600 text-lg">Plataforma auditada, pagamentos regulamentados pelo Banco Central e proteção total de dados (LGPD).</p>
            </div>
          </div>
        </div>
      </section>

      {/* Features / Como Funciona */}
      <section id="como-funciona" className="py-20 px-4 w-full bg-white">
        <div className="max-w-6xl mx-auto">
          <h3 className="text-3xl md:text-4xl font-bold text-center mb-16 text-primary">Como Funciona?</h3>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-gray-50 p-8 rounded-2xl shadow-sm text-center border-t-4 border-primary hover:-translate-y-2 transition-transform">
              <div className="w-16 h-16 bg-primary/10 text-primary rounded-full flex items-center justify-center mx-auto mb-6 text-2xl font-black">1</div>
              <h4 className="text-xl font-bold mb-4">Acompanhe o Jogo</h4>
              <p className="text-gray-600">Fique de olho nas partidas de futebol ao vivo diretamente pelo aplicativo.</p>
            </div>

            <div className="bg-gray-50 p-8 rounded-2xl shadow-sm text-center border-t-4 border-accent hover:-translate-y-2 transition-transform">
              <div className="w-16 h-16 bg-accent/20 text-yellow-600 rounded-full flex items-center justify-center mx-auto mb-6 text-2xl font-black">2</div>
              <h4 className="text-xl font-bold mb-4">Gatilho de Liberação</h4>
              <p className="text-gray-600">Saiu Gol? Intervalo? Fim de jogo? A sua primeira raspadinha da partida é 100% grátis.</p>
            </div>

            <div className="bg-gray-50 p-8 rounded-2xl shadow-sm text-center border-t-4 border-primary hover:-translate-y-2 transition-transform">
              <div className="w-16 h-16 bg-primary/10 text-primary rounded-full flex items-center justify-center mx-auto mb-6 text-2xl font-black">3</div>
              <h4 className="text-xl font-bold mb-4">Raspe e Ganhe PIX</h4>
              <p className="text-gray-600">Revele 3 bolas de futebol no grid 3x3 e solicite o seu prêmio via PIX instantaneamente.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Social Proof / Depoimentos */}
      <section className="py-20 px-4 w-full bg-primary text-white">
        <div className="max-w-6xl mx-auto">
          <h3 className="text-3xl md:text-4xl font-bold text-center mb-16">O que a torcida está dizendo</h3>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white/10 p-8 rounded-2xl backdrop-blur-sm border border-white/20">
              <div className="flex text-accent mb-4">★★★★★</div>
              <p className="text-gray-200 italic mb-6">"Fui assistir ao jogo do Flamengo e no primeiro gol do Pedro já ganhei uma raspadinha grátis. Raspei e ganhei R$ 50 direto no PIX! Sensacional!"</p>
              <div className="font-bold text-lg">- Marcos T. <span className="text-sm font-normal text-gray-300 ml-2">Rio de Janeiro</span></div>
            </div>

            <div className="bg-white/10 p-8 rounded-2xl backdrop-blur-sm border border-white/20">
              <div className="flex text-accent mb-4">★★★★★</div>
              <p className="text-gray-200 italic mb-6">"Muito mais divertido do que aposta esportiva normal. A gente vibra com o gol duas vezes: pelo time e pela chance de raspar a cartela."</p>
              <div className="font-bold text-lg">- Juliana S. <span className="text-sm font-normal text-gray-300 ml-2">São Paulo</span></div>
            </div>

            <div className="bg-white/10 p-8 rounded-2xl backdrop-blur-sm border border-white/20">
              <div className="flex text-accent mb-4">★★★★★</div>
              <p className="text-gray-200 italic mb-6">"Duvidei que o PIX caía na hora, mas é verdade. Ganhei num domingo à tarde e 2 minutos depois o dinheiro tava na conta. Recomendo."</p>
              <div className="font-bold text-lg">- Carlos E. <span className="text-sm font-normal text-gray-300 ml-2">Minas Gerais</span></div>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20 px-4 w-full bg-gray-50">
        <div className="max-w-4xl mx-auto">
          <h3 className="text-3xl md:text-4xl font-bold text-center mb-12 text-primary">Dúvidas Frequentes (FAQ)</h3>
          
          <div className="space-y-6">
            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <h4 className="text-xl font-bold text-primary mb-2">É realmente grátis no momento do gol?</h4>
              <p className="text-gray-600">Sim! Toda vez que ocorrer um dos gatilhos (Gol, Intervalo ou Fim de Jogo) na partida que você está acompanhando no app, a primeira raspadinha é por nossa conta.</p>
            </div>
            
            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <h4 className="text-xl font-bold text-primary mb-2">Como eu recebo meu prêmio?</h4>
              <p className="text-gray-600">Todos os prêmios são pagos via PIX. Para isso, sua chave PIX deve ser o mesmo CPF cadastrado na sua conta Raspadinha do Gol.</p>
            </div>

            <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <h4 className="text-xl font-bold text-primary mb-2">Menores de 18 anos podem jogar?</h4>
              <p className="text-gray-600">Não. O uso da plataforma é estritamente proibido para menores de idade. Confirmamos a identidade e a idade durante o cadastro.</p>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
