import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { PrizesSlider } from '../components/PrizesSlider';

const heroImages = [
  "/hero-football.png?v=2",
  "/stadium_crowd.png",
  "/player_kicking.png"
];

export function Home() {
  const [currentImage, setCurrentImage] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentImage((prev) => (prev + 1) % heroImages.length);
    }, 5000); // Change image every 5 seconds
    return () => clearInterval(timer);
  }, []);

  return (
    <>
      {/* Hero Section */}
      <section className="w-full bg-primary text-white pt-32 pb-20 px-4 relative overflow-hidden flex flex-col items-center justify-center min-h-[80vh]">
        {/* Background Images Slider */}
        {heroImages.map((img, index) => (
          <img 
            key={index}
            src={img} 
            alt={`Hero Background ${index + 1}`} 
            className={`absolute inset-0 w-full h-full object-cover z-0 transition-opacity duration-1000 ${
              index === currentImage ? "opacity-80" : "opacity-0"
            }`} 
          />
        ))}
        <div className="absolute inset-0 bg-black/60 z-0 transition-opacity duration-1000"></div> {/* Overlay darker for better contrast */}
        
        <div className="relative z-10 max-w-4xl mx-auto flex flex-col items-center text-center w-full">
          <div className="mb-8 drop-shadow-2xl">
            <img 
              src="/logo_transparent.png" 
              alt="Raspadinha do Gol" 
              className="w-48 h-48 object-contain" 
            />
          </div>
          <h2 className="text-4xl md:text-6xl font-extrabold mb-6 leading-tight">
            Seu conhecimento de futebol vale <span className="text-accent drop-shadow-md">Prêmios!</span>
          </h2>
          <p className="text-lg md:text-2xl mb-10 text-gray-100 max-w-2xl">
            Acompanhe jogos ao vivo e ganhe raspadinhas gratuitas a cada gol, intervalo ou fim do jogo! Raspe na hora e concorra a camisas oficiais e prêmios incríveis.
          </p>
          <div className="flex flex-col sm:flex-row justify-center gap-4 w-full md:w-auto mt-4">
            <a href="https://app-raspadinhadogol.web.app" className="bg-accent text-text-dark text-xl px-8 py-4 rounded-xl font-black hover:scale-110 transition-all duration-300 shadow-[0_0_25px_rgba(252,211,77,0.8)] text-center animate-pulse border-2 border-accent">
              Jogar Agora Grátis
            </a>
            <Link to="/regulamento" onClick={() => window.scrollTo(0, 0)} className="bg-white/10 border-2 border-white/50 backdrop-blur-sm text-white text-xl px-8 py-4 rounded-xl font-bold hover:bg-white/20 hover:scale-105 transition-all duration-300 text-center">
              Ver Regulamento
            </Link>
          </div>
        </div>

        {/* Efeito de fade para transição suave com a próxima seção */}
        <div className="absolute bottom-0 left-0 w-full h-48 bg-gradient-to-t from-black to-transparent z-10 pointer-events-none"></div>
      </section>

      {/* Espaçamento escuro de respiro */}
      <div className="w-full h-24 bg-black"></div>

      {/* Seção do Slider de Prêmios */}
      <section className="w-full">
        <PrizesSlider />
      </section>

      {/* Benefícios / Por que Escolher */}
      <section className="py-20 px-4 w-full bg-gray-50">
        <div className="max-w-6xl mx-auto text-center">
          <h3 className="text-3xl md:text-4xl font-bold mb-12 text-primary">Por que a Raspadinha do Gol?</h3>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-accent text-primary rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">⚡</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">Raspadinhas Relâmpago</h4>
              <p className="text-gray-600 text-lg">A cada gol, intervalo ou fim de jogo, uma Raspadinha especial aparece na sua tela instantaneamente. Não perca a chance!</p>
            </div>
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">🤖</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">Quiz com Inteligência Artificial</h4>
              <p className="text-gray-600 text-lg">Teste seus conhecimentos! Responda às perguntas geradas por IA sobre os jogos em andamento e ganhe Tokens ao acertar.</p>
            </div>
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-primary text-white rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">🎁</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">Troque por Prêmios</h4>
              <p className="text-gray-600 text-lg">Use seus Tokens para comprar mais Raspadinhas e concorra a camisas oficiais de times, cupons e brindes exclusivos.</p>
            </div>
            <div className="p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
              <div className="w-20 h-20 bg-white text-primary border-4 border-primary rounded-full flex items-center justify-center mx-auto mb-6 text-4xl shadow-lg">🔒</div>
              <h4 className="text-2xl font-bold mb-3 text-primary">100% Seguro</h4>
              <p className="text-gray-600 text-lg">Não somos casa de aposta! Somos um jogo de habilidade seguro, transparente e gratuito para participar.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Features / Como Funciona Banner */}
      <section className="py-16 px-4 w-full bg-primary text-white text-center">
        <div className="max-w-4xl mx-auto">
          <h3 className="text-3xl md:text-4xl font-bold mb-6">Ainda com dúvidas de como jogar?</h3>
          <p className="text-xl mb-8 text-gray-200">Preparamos um guia passo a passo de como ganhar brindes e resgatar prêmios incríveis!</p>
          <Link to="/como-funciona" onClick={() => window.scrollTo(0, 0)} className="inline-block bg-white text-primary text-xl px-8 py-4 rounded-xl font-bold hover:scale-105 transition-transform shadow-lg">
            Ver o Passo a Passo Completo
          </Link>
        </div>
      </section>

      {/* Social Proof / Depoimentos */}
      <section className="py-20 px-4 w-full bg-primary text-white">
        <div className="max-w-6xl mx-auto">
          <h3 className="text-3xl md:text-4xl font-bold text-center mb-16">O que a torcida está dizendo</h3>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white/10 p-8 rounded-2xl backdrop-blur-sm border border-white/20">
              <div className="flex text-accent mb-4">★★★★★</div>
              <p className="text-gray-200 italic mb-6">"Fui assistir ao jogo do Flamengo pelo app, na hora do gol ganhei uma chance na raspadinha. Fui lá e ganhei a camisa oficial! Sensacional!"</p>
              <div className="font-bold text-lg">- Marcos T. <span className="text-sm font-normal text-gray-300 ml-2">Rio de Janeiro</span></div>
            </div>

            <div className="bg-white/10 p-8 rounded-2xl backdrop-blur-sm border border-white/20">
              <div className="flex text-accent mb-4">★★★★★</div>
              <p className="text-gray-200 italic mb-6">"Muito mais divertido do que aposta. A gente vibra com o jogo e ainda tem a surpresa da raspadinha na hora do gol. E as camisas são originais mesmo!"</p>
              <div className="font-bold text-lg">- Juliana S. <span className="text-sm font-normal text-gray-300 ml-2">São Paulo</span></div>
            </div>

            <div className="bg-white/10 p-8 rounded-2xl backdrop-blur-sm border border-white/20">
              <div className="flex text-accent mb-4">★★★★★</div>
              <p className="text-gray-200 italic mb-6">"Duvidei que o prêmio chegava, mas é verdade. Ganhei num domingo à tarde e logo depois a equipe entrou em contato para o envio. Recomendo."</p>
              <div className="font-bold text-lg">- Carlos E. <span className="text-sm font-normal text-gray-300 ml-2">Minas Gerais</span></div>
            </div>
          </div>
        </div>
      </section>
      </>
      );
      }
