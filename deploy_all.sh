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
echo "📱 2. Buildando o App Flutter (Web)..."
flutter build web

echo ""
echo "☁️ 3. Enviando tudo para o Firebase Hosting..."
# Como o firebase.json na raiz tem dois sites configurados,
# esse comando envia o website para um link e o app para o outro automaticamente.
firebase deploy --only hosting

echo ""
echo "✅ Deploy concluído com sucesso!"
echo "➡️  Landing Page: https://raspadinhadogol.web.app"
echo "➡️  App Flutter:  https://app-raspadinhadogol.web.app"
