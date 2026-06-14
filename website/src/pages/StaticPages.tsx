export function Regulamento() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Regulamento</h1>
      <div className="prose prose-lg max-w-none">
        <p>Bem-vindo ao Regulamento Oficial da Raspadinha do Gol.</p>
        <h2 className="text-2xl font-bold mt-6 mb-2">1. Elegibilidade</h2>
        <p>Para participar, o usuário deve ter mais de 18 anos e possuir uma conta ativa no aplicativo.</p>
        <h2 className="text-2xl font-bold mt-6 mb-2">2. Mecânica do Sorteio</h2>
        <p>O sorteio ocorre através de um sistema de lotes gerado em tempo real, condicionado a eventos de partidas de futebol.</p>
        <h2 className="text-2xl font-bold mt-6 mb-2">3. Premiações</h2>
        <p>Os prêmios são distribuídos instantaneamente via PIX para o CPF do titular cadastrado na plataforma.</p>
      </div>
    </div>
  );
}

export function Privacidade() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Política de Privacidade</h1>
      <div className="prose prose-lg max-w-none">
        <p>A proteção dos seus dados é nossa prioridade.</p>
        <h2 className="text-2xl font-bold mt-6 mb-2">Coleta de Dados</h2>
        <p>Coletamos apenas os dados necessários para o processamento de pagamentos e prevenção a fraudes (ex: E-mail, CPF).</p>
        <h2 className="text-2xl font-bold mt-6 mb-2">Compartilhamento</h2>
        <p>Não compartilhamos seus dados com terceiros, exceto provedores de pagamento homologados pelo Banco Central.</p>
      </div>
    </div>
  );
}

export function Termos() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Termos de Uso</h1>
      <div className="prose prose-lg max-w-none">
        <p>Ao utilizar o aplicativo Raspadinha do Gol, você concorda com nossos termos.</p>
        <p className="mt-4">A Raspadinha do Gol é um jogo de diversão com micropagamentos. A garantia de prêmio depende exclusivamente do sistema de lotes estabelecido pela plataforma, não havendo garantia de retorno financeiro.</p>
      </div>
    </div>
  );
}

export function JogoResponsavel() {
  return (
    <div className="w-full max-w-4xl mx-auto px-4 py-12 text-gray-800">
      <h1 className="text-4xl font-bold text-primary mb-8">Jogo Responsável</h1>
      <div className="prose prose-lg max-w-none">
        <p>A Raspadinha do Gol promove o entretenimento consciente.</p>
        <p className="mt-4">Se você sentir que está perdendo o controle, oferecemos ferramentas de autoexclusão e limites diários de depósito.</p>
        <p className="mt-4 font-bold text-red-600">Apenas para maiores de 18 anos.</p>
      </div>
    </div>
  );
}
