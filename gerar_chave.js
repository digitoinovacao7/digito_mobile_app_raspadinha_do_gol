const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log("==================================================");
console.log("🤖 GERADOR DE CHAVE DA BETFAIR (MODO HACKER) 🤖");
console.log("==================================================\n");
console.log("Fique tranquilo, este script roda apenas no seu computador e não salva a sua senha em lugar nenhum.\n");

rl.question('Digite seu Usuário da Betfair: ', (username) => {
  rl.question('Digite sua Senha da Betfair: ', async (password) => {
    
    console.log("\n⏳ Conectando aos servidores da Betfair...");

    try {
        // 1. Fazer Login
        const loginParams = new URLSearchParams();
        loginParams.append("username", username);
        loginParams.append("password", password);

        const loginResponse = await fetch("https://identitysso.betfair.com/api/login", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "X-Application": "betfair-bot-setup",
                "Content-Type": "application/x-www-form-urlencoded",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
            },
            body: loginParams.toString()
        });

        const loginData = await loginResponse.json();

        if (loginData.status !== "SUCCESS") {
            console.error("❌ ERRO NO LOGIN:", loginData.error || loginData.status);
            console.log("Verifique se seu usuário e senha estão corretos e tente novamente.");
            rl.close();
            return;
        }

        const sessionToken = loginData.token;
        console.log("✅ Login realizado com sucesso! Gerando sua App Key...\n");

        // 2. Criar a Chave de Desenvolvedor
        const keyResponse = await fetch("https://api.betfair.com/exchange/account/rest/v1.0/createDeveloperAppKeys/", {
            method: "POST",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json",
                "X-Authentication": sessionToken,
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
            },
            body: JSON.stringify({ appName: "RoboDigitoApp" })
        });

        const keyData = await keyResponse.json();

        if (keyData.error || keyData.faultcode) {
             console.log("Aviso: Você já deve ter chaves criadas.");
             console.log("Tentando recuperar suas chaves existentes...\n");
             
             const getResponse = await fetch("https://api.betfair.com/exchange/account/rest/v1.0/getDeveloperAppKeys/", {
                method: "POST",
                headers: {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "X-Authentication": sessionToken,
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
                },
                body: "{}"
             });
             
             const getData = await getResponse.json();
             if (getData && getData.length > 0) {
                 const myKey = getData[0];
                 const liveKey = myKey.appVersions.find(v => !v.delayData);
                 
                 console.log("==================================================");
                 console.log("🎉 CHAVE (APP KEY) RECUPERADA COM SUCESSO! 🎉");
                 console.log("==================================================");
                 console.log(`\nSua App Key LIVE é: \x1b[32m${liveKey.applicationKey}\x1b[0m\n`);
                 console.log("Copie essa chave (em verde) e cole lá no painel de Admin do aplicativo!");
             } else {
                 console.error("❌ ERRO: Não consegui listar suas chaves.", getData);
             }
        } else {
             const newKey = keyData[0];
             const liveKey = newKey.appVersions.find(v => !v.delayData);

             console.log("==================================================");
             console.log("🎉 CHAVE (APP KEY) CRIADA COM SUCESSO! 🎉");
             console.log("==================================================");
             console.log(`\nSua App Key LIVE é: \x1b[32m${liveKey.applicationKey}\x1b[0m\n`);
             console.log("Copie essa chave (em verde) e cole lá no painel de Admin do aplicativo!");
        }

    } catch (e) {
        console.error("❌ ERRO INESPERADO:", e.message);
    }

    rl.close();
  });
});
