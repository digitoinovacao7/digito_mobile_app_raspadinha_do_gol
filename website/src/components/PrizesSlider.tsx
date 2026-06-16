import { useState, useEffect } from 'react';

const slides = [
  {
    id: 1,
    title: "Troque tokens por PIX!",
    description: "Acumulou tokens nos quizzes? Troque por dinheiro na sua conta via PIX rapidamente.",
    icon: "💸",
    bgColor: "bg-green-600"
  },
  {
    id: 2,
    title: "Camisa Oficial do seu Clube",
    description: "Use seus tokens para resgatar a camisa oficial do seu time do coração.",
    icon: "👕",
    bgColor: "bg-blue-600"
  },
  {
    id: 3,
    title: "Outros Brindes Exclusivos",
    description: "Vouchers, ingressos e diversos outros prêmios incríveis te esperam.",
    icon: "🎁",
    bgColor: "bg-purple-600"
  }
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
    <div className="relative w-full max-w-4xl mx-auto overflow-hidden rounded-2xl shadow-2xl my-8 h-72 md:h-56 group">
      {slides.map((slide, index) => (
        <div
          key={slide.id}
          className={`absolute top-0 left-0 w-full h-full flex flex-col md:flex-row items-center justify-center p-8 transition-opacity duration-1000 ${slide.bgColor} text-white ${
            index === currentSlide ? "opacity-100 z-10" : "opacity-0 z-0"
          }`}
        >
          <div className="text-7xl mb-4 md:mb-0 md:mr-8 drop-shadow-lg">{slide.icon}</div>
          <div className="text-center md:text-left">
            <h3 className="text-3xl font-extrabold mb-3 drop-shadow-sm">{slide.title}</h3>
            <p className="text-lg md:text-xl text-white/90 max-w-lg leading-relaxed">{slide.description}</p>
          </div>
        </div>
      ))}
      <div className="absolute bottom-4 left-0 w-full flex justify-center gap-3 z-20">
        {slides.map((_, index) => (
          <button
            key={index}
            onClick={() => setCurrentSlide(index)}
            className={`w-3 h-3 rounded-full transition-all duration-300 ${
              index === currentSlide ? "bg-white scale-125" : "bg-white/40 hover:bg-white/70"
            }`}
            aria-label={`Ir para o slide ${index + 1}`}
          />
        ))}
      </div>
    </div>
  );
}
