export function FAQ() {
  return (
    <div className="py-20 px-4 w-full bg-gray-50 flex-1">
      <div className="max-w-4xl mx-auto">
        <h3 className="text-3xl md:text-4xl font-bold text-center mb-12 text-primary">Dúvidas Frequentes (FAQ)</h3>

        <div className="space-y-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">Como eu participo do Quiz?</h4>
            <p className="text-gray-600">Fique de olho no app durante as partidas ao vivo. Sempre que rolar um gol, o intervalo ou o fim do jogo, o quiz aparece e você ganha prêmios se acertar.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">Como eu recebo meu prêmio?</h4>
            <p className="text-gray-600">Para resgatar os prêmios físicos, sua conta deve estar devidamente cadastrada com um endereço válido e telefone de contato na Raspadinha do Gol.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">Menores de 18 anos podem jogar?</h4>
            <p className="text-gray-600">Não. O uso da plataforma é estritamente proibido para menores de idade. Confirmamos a identidade e a idade durante o cadastro.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">A Raspadinha do Gol é uma casa de apostas?</h4>
            <p className="text-gray-600">Não! Nós não somos uma casa de apostas. Somos uma plataforma gratuita de quizzes de futebol e jogos de habilidade onde você ganha brindes pelo seu conhecimento.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">É de graça?</h4>
            <p className="text-gray-600">Sim! A participação nos quizzes é totalmente gratuita. Você usa o seu conhecimento na raspadinha para concorrer a prêmios reais.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
