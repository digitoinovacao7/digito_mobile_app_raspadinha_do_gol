import { useState, useEffect } from 'react';

const slides = [
  {
    id: 1,
    title: "Troque tokens por PIX!",
    description: "Acumulou tokens nos quizzes? Troque por dinheiro na sua conta via PIX rapidamente.",
    icon: "💸",
    image: "/pix_transfer.png"
  },
  {
    id: 2,
    title: "Camisa Oficial do seu Clube",
    description: "Use seus tokens para resgatar a camisa oficial do seu time do coração.",
    icon: "👕",
    image: "/soccer_jersey.png"
  },
  {
    id: 3,
    title: "Outros Brindes Exclusivos",
    description: "Vouchers, ingressos e diversos outros prêmios incríveis te esperam.",
    icon: "🎁",
    image: "/gifts_vouchers.png"
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
    <div className="relative w-full overflow-hidden my-8 h-96 group">
      {slides.map((slide, index) => (
        <div
          key={slide.id}
          className={`absolute top-0 left-0 w-full h-full flex flex-col items-center justify-center p-8 transition-opacity duration-1000 bg-cover bg-center text-white ${
            index === currentSlide ? "opacity-100 z-10" : "opacity-0 z-0"
          }`}
          style={{ backgroundImage: `url(${slide.image})` }}
        >
          <div className="absolute inset-0 bg-black/50 z-0"></div>
          <div className="relative z-10 flex flex-col md:flex-row items-center justify-center max-w-6xl mx-auto w-full">
            <div className="text-7xl mb-4 md:mb-0 md:mr-8 drop-shadow-lg">{slide.icon}</div>
            <div className="text-center md:text-left">
              <h3 className="text-4xl md:text-5xl font-extrabold mb-4 drop-shadow-lg">{slide.title}</h3>
              <p className="text-xl md:text-2xl text-white/90 max-w-2xl leading-relaxed font-medium drop-shadow-md">{slide.description}</p>
            </div>
          </div>
        </div>
      ))}
      <div className="absolute bottom-6 left-0 w-full flex justify-center gap-3 z-20">
        {slides.map((_, index) => (
          <button
            key={index}
            onClick={() => setCurrentSlide(index)}
            className={`w-3 h-3 rounded-full transition-all duration-300 ${
              index === currentSlide ? "bg-white scale-150" : "bg-white/50 hover:bg-white/80"
            }`}
            aria-label={`Ir para o slide ${index + 1}`}
          />
        ))}
      </div>
    </div>
  );
}
