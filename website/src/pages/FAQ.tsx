export function FAQ() {
  const faqs = [
    {
      q: "Como eu participo do Quiz?",
      a: "Fique de olho no app durante as partidas ao vivo. Sempre que rolar um gol, o intervalo ou o fim do jogo, o quiz aparece na sua tela e você ganha raspadinhas e Tokens do Gol se acertar.",
      badge: "🎮 Quizzes & Jogos",
    },
    {
      q: "Como funciona o Bolão do Gol entre Amigos e Bares?",
      a: "Você pode criar um Bolão da Galera (grátis ou com cota) para qualquer partida e compartilhar o link no WhatsApp. Quem cravar o placar exato leva o pote acumulado! No modoAmigos, o criador recebe 5% de comissão e 85% vai para os vencedores. No modo Bares & Restaurantes, o estabelecimento recebe 10% de comissão para movimentar a casa!",
      badge: "🏆 Bolão do Gol",
    },
    {
      q: "Como eu recebo meu prêmio?",
      a: "Para resgatar os prêmios físicos oficiais (camisas de time, bolas, vestuário ou vouchers parceiros), sua conta deve estar devidamente cadastrada com um CPF, endereço válido e telefone de contato na Raspadinha do Gol. O envio é feito diretamente para o seu endereço com código de rastreamento.",
      badge: "🎁 Prêmios & Resgate",
    },
    {
      q: "Menores de 18 anos podem jogar?",
      a: "Não. O uso da plataforma é estritamente proibido para menores de idade. Confirmamos a identidade e a idade durante o cadastro para garantir a segurança de todos.",
      badge: "🛡️ Regras & Segurança",
    },
    {
      q: "A Raspadinha do Gol é uma casa de apostas?",
      a: "Não! Nós NÃO somos uma casa de apostas e não trabalhamos com odds de apostas. Somos uma plataforma brasileira de entretenimento esportivo, quizzes de futebol, raspadinhas patrocinadas e bolões recreativos onde seu conhecimento vale prêmios reais.",
      badge: "⚽ Sem Apostas",
    },
    {
      q: "É realmente de graça?",
      a: "Sim! A participação nos quizzes, raspadinhas ao vivo e bolões gratuitos é totalmente livre de custos. Você não precisa fazer nenhum depósito para jogar e concorrer a camisas e brindes.",
      badge: "💰 100% Grátis",
    },
    {
      q: "Como funcionam as raspadinhas instantâneas?",
      a: "Sempre que ocorre um evento na partida (gol, intervalo ou apito final), o botão de raspadinha é liberado. Ao raspar a cartela e achar 3 símbolos iguais, você fatura a premiação anunciada!",
      badge: "🎟️ Raspadinhas",
    },
  ];

  return (
    <div className="w-full bg-[#041d10] text-white font-sans min-h-screen pt-24 pb-20 overflow-hidden">
      {/* Header */}
      <section className="relative py-16 px-4 text-center border-b border-emerald-800/60 bg-gradient-to-b from-[#062414] to-[#041d10]">
        <div className="max-w-4xl mx-auto relative z-10">
          <span className="bg-amber-400/10 text-amber-400 border border-amber-400/30 text-xs font-bold px-4 py-1.5 rounded-full uppercase tracking-wider inline-block mb-4">
            Central de Ajuda
          </span>
          <h1 className="text-4xl md:text-5xl font-black mb-4 text-white tracking-tight">
            Dúvidas <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-300 via-amber-400 to-amber-500">Frequentes (FAQ)</span>
          </h1>
          <p className="text-emerald-100/80 text-base md:text-lg max-w-xl mx-auto">
            Tire suas dúvidas sobre o funcionamento dos quizzes, raspadinhas, Bolão do Gol e resgate de prêmios.
          </p>
        </div>
      </section>

      {/* FAQ Grid */}
      <section className="py-16 px-4 max-w-5xl mx-auto">
        <div className="grid gap-6">
          {faqs.map((item, idx) => (
            <div
              key={idx}
              className="bg-[#072917]/75 border border-emerald-800/60 hover:border-amber-400/50 p-6 md:p-8 rounded-3xl transition-all hover:shadow-[0_0_20px_rgba(251,191,36,0.12)] group"
            >
              <div className="flex items-center justify-between gap-4 mb-3">
                <span className="text-xs font-bold text-amber-400 bg-amber-400/10 border border-amber-400/20 px-3 py-1 rounded-full uppercase tracking-wider">
                  {item.badge}
                </span>
              </div>
              <h3 className="text-xl font-bold text-white mb-3 group-hover:text-amber-300 transition-colors">
                {item.q}
              </h3>
              <p className="text-emerald-100/80 text-sm md:text-base leading-relaxed">
                {item.a}
              </p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
