import { useState, useEffect } from "react";

const slides = [
  {
    id: 1,
    title: "Camisa Oficial do seu Clube",
    description:
      "Acompanhe seu time e concorra a camisas oficiais entregues na sua casa.",
    icon: "👕",
    image: "/soccer_jersey.png",
  },
  {
    id: 2,
    title: "Bolas Oficiais",
    description:
      "Jogue como os craques com bolas oficiais das grandes ligas e campeonatos.",
    icon: "⚽",
    image: "/stadium_crowd.png",
  },
  {
    id: 3,
    title: "Outros Brindes Exclusivos",
    description:
      "Vouchers, ingressos e diversos outros prêmios incríveis te esperam a cada jogo.",
    icon: "🎁",
    image: "/gifts_vouchers.png",
  },
];

export function PrizesSlider() {
  const [currentSlide, setCurrentSlide] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % slides.length);
    }, 4000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="relative w-full overflow-hidden h-[600px] bg-black group">
      {/* Título fixo sobreposto ao banner */}
      <div className="absolute top-16 left-0 w-full z-20 text-center pointer-events-none">
        <h3 className="text-3xl md:text-5xl font-black text-white drop-shadow-2xl tracking-wide">
          Prêmios incríveis te esperam
        </h3>
      </div>

      {/* Fade no topo para misturar com o espaçamento preto acima */}
      <div className="absolute top-0 left-0 w-full h-40 bg-gradient-to-b from-black to-transparent z-10 pointer-events-none"></div>

      {slides.map((slide, index) => (
        <div
          key={slide.id}
          className={`absolute top-0 left-0 w-full h-full flex flex-col items-center justify-center p-8 transition-opacity duration-1000 bg-cover bg-center text-white ${
            index === currentSlide
              ? "opacity-100 z-10"
              : "opacity-0 z-0 pointer-events-none"
          }`}
          style={{ backgroundImage: `url(${slide.image})` }}
        >
          <div className="absolute inset-0 bg-black/60 z-0"></div>
          <div className="relative z-10 flex flex-col md:flex-row items-center justify-center max-w-6xl mx-auto w-full mt-16">
            <div className="text-7xl mb-4 md:mb-0 md:mr-8 drop-shadow-lg">
              {slide.icon}
            </div>
            <div className="text-center md:text-left">
              <h3 className="text-4xl md:text-5xl font-extrabold mb-4 drop-shadow-lg text-accent">
                {slide.title}
              </h3>
              <p className="text-xl md:text-2xl text-white max-w-2xl leading-relaxed font-medium drop-shadow-md">
                {slide.description}
              </p>
            </div>
          </div>
        </div>
      ))}
      <div className="absolute bottom-8 left-0 w-full flex justify-center gap-4 z-20">
        {slides.map((_, index) => (
          <button
            key={index}
            onClick={() => setCurrentSlide(index)}
            className={`w-3 h-3 rounded-full transition-all duration-300 shadow-md ${
              index === currentSlide
                ? "bg-accent scale-150"
                : "bg-white/50 hover:bg-white"
            }`}
            aria-label={`Ir para o slide ${index + 1}`}
          />
        ))}
      </div>
    </div>
  );
}
