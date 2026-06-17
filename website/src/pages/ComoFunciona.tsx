export function ComoFunciona() {
  return (
    <div className="w-full bg-bg-light min-h-screen pt-12 pb-24">
      {/* Header */}
      <section className="bg-primary text-white py-16 px-4 text-center">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-4xl md:text-6xl font-extrabold mb-6">Como Funciona?</h1>
          <p className="text-xl text-gray-200">
            Aprenda como transformar seu conhecimento de futebol em Pix, Camisas e Cupons. É rápido, divertido e 100% seguro!
          </p>
        </div>
      </section>

      {/* Steps */}
      <section className="py-16 px-4 max-w-6xl mx-auto">
        <div className="grid md:grid-cols-3 gap-12 mt-8">
          
          <div className="bg-white p-10 rounded-3xl shadow-lg border-t-8 border-primary hover:-translate-y-2 transition-transform">
            <div className="w-20 h-20 bg-primary/10 text-primary rounded-full flex items-center justify-center mb-8 text-4xl font-black">1</div>
            <h4 className="text-2xl font-bold mb-4">Acompanhe e Responda</h4>
            <p className="text-gray-600 text-lg leading-relaxed">
              No aplicativo, navegue até a aba "Jogos ao Vivo" e escolha a partida do seu time. Fique de olho: sempre que rolar o intervalo ou o fim do jogo, um <b>Quiz Relâmpago</b> especial vai aparecer na sua tela. Você precisa ser rápido e mostrar que entende de futebol!
            </p>
          </div>

          <div className="bg-white p-10 rounded-3xl shadow-lg border-t-8 border-accent hover:-translate-y-2 transition-transform">
            <div className="w-20 h-20 bg-accent/20 text-yellow-600 rounded-full flex items-center justify-center mb-8 text-4xl font-black">2</div>
            <h4 className="text-2xl font-bold mb-4">Acumule Tokens</h4>
            <p className="text-gray-600 text-lg leading-relaxed">
              Ao responder corretamente as perguntas geradas pela nossa Inteligência Artificial antes do tempo esgotar, sua conta é imediatamente abastecida com <b>Tokens Virtuais</b>. Quanto mais você acertar, mais rica a sua carteira fica!
            </p>
          </div>

          <div className="bg-white p-10 rounded-3xl shadow-lg border-t-8 border-primary hover:-translate-y-2 transition-transform">
            <div className="w-20 h-20 bg-primary/10 text-primary rounded-full flex items-center justify-center mb-8 text-4xl font-black">3</div>
            <h4 className="text-2xl font-bold mb-4">Raspe e Ganhe</h4>
            <p className="text-gray-600 text-lg leading-relaxed">
              Com os tokens em mãos, vá para a <b>Raspadinha do Gol</b>. Ao raspar a cartela e achar 3 símbolos iguais, você multiplica seus tokens ou tira a sorte grande levando Pix na hora, camisas oficiais de time ou super cupons de desconto!
            </p>
          </div>
          
        </div>
        
        {/* Call to Action */}
        <div className="mt-20 bg-gradient-to-r from-primary to-slate-800 rounded-3xl p-12 text-center shadow-xl text-white">
          <h2 className="text-3xl font-bold mb-6">Pronto para entrar em campo?</h2>
          <p className="text-lg mb-8 max-w-2xl mx-auto text-gray-200">
            Não perca tempo, os jogos já estão rolando e as raspadinhas estão esperando por você. Baixe o app agora mesmo e comece a pontuar.
          </p>
          <a href="https://app-raspadinhadogol.web.app" className="inline-block bg-accent text-text-dark text-xl px-10 py-4 rounded-xl font-bold hover:scale-105 transition-transform shadow-lg shadow-accent/30">
            Baixar Aplicativo
          </a>
        </div>
      </section>
    </div>
  );
}
