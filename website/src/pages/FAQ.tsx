export function FAQ() {
  return (
    <div className="py-20 px-4 w-full bg-gray-50 flex-1">
      <div className="max-w-4xl mx-auto">
        <h3 className="text-3xl md:text-4xl font-bold text-center mb-12 text-primary">Dúvidas Frequentes (FAQ)</h3>

        <div className="space-y-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">Como eu participo do Quiz?</h4>
            <p className="text-gray-600">Fique de olho no app durante as partidas ao vivo. Assim que um evento principal acontecer (como Gol ou Cartão), o quiz aparece e você ganha Tokens se acertar.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">Como eu recebo meu prêmio?</h4>
            <p className="text-gray-600">Todos os prêmios são pagos via PIX. Para isso, sua chave PIX deve ser o mesmo CPF cadastrado na sua conta Raspadinha do Gol.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">Menores de 18 anos podem jogar?</h4>
            <p className="text-gray-600">Não. O uso da plataforma é estritamente proibido para menores de idade. Confirmamos a identidade e a idade durante o cadastro.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">A Raspadinha do Gol é uma casa de apostas?</h4>
            <p className="text-gray-600">Não! Nós não somos uma casa de apostas. Somos uma plataforma gratuita de quizzes de futebol e jogos de habilidade onde você ganha tokens pelo seu conhecimento.</p>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <h4 className="text-xl font-bold text-primary mb-2">É de graça?</h4>
            <p className="text-gray-600">Sim! A participação nos quizzes é totalmente gratuita. Você ganha tokens pelo seu conhecimento do jogo e usa esses tokens na raspadinha para concorrer aos prêmios reais.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
