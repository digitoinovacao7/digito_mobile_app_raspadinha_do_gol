#!/bin/bash

# Interrompe o script se ocorrer algum erro
set -e

echo "======================================"
echo "🚀 INICIANDO BUILD E DEPLOY GERAL"
echo "======================================"

echo ""
echo "📦 1. Buildando a Landing Page (React/Vite)..."
cd website
npm install
npm run build
cd ..

echo ""
echo "⚙️  2. Buildando as Funções (Firebase)..."
cd functions
npm install
npm run build
cd ..

echo ""
echo "📱 3. Buildando o App Flutter (Web)..."
# O app precisa sempre buscar o bundle atual; um service worker antigo mantém
# versões do cloud_functions_web em cache e pode reintroduzir o erro de Int64.
flutter build web --pwa-strategy=none
cp web/flutter_service_worker_cleanup.js build/web/flutter_service_worker.js

echo ""
echo "☁️ 4. Enviando tudo para o Firebase Hosting..."
# Como o firebase.json na raiz tem dois sites configurados,
# esse comando envia o website para um link e o app para o outro automaticamente.
firebase deploy

echo ""
echo "✅ Deploy concluído com sucesso!"
echo "➡️  Landing Page: https://raspadinhadogol.web.app"
echo "➡️  App Flutter:  https://app-raspadinhadogol.web.app"
