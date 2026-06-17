import React, { useState, useEffect } from 'react';
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc, setDoc } from 'firebase/firestore';

// Como este é um app genérico, a config do Firebase normalmente viria de variáveis de ambiente.
// Aqui colocamos um placeholder genérico que pode ser atualizado com as chaves reais.
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSy_MOCK_KEY_FOR_DEV",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "mock-app.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "mock-app",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "mock-app.firebasestorage.app",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "1234567890",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:1234567890:web:abcdef123456"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export function Admin() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  // API Keys State
  const [apiFootball, setApiFootball] = useState('');
  const [mercadoPago, setMercadoPago] = useState('');
  const [zApi, setZApi] = useState('');

  // Prize Rules State
  const [globalWinChance, setGlobalWinChance] = useState(10);

  useEffect(() => {
    async function loadData() {
      try {
        const configDoc = await getDoc(doc(db, "system_config", "general"));
        if (configDoc.exists()) {
          const data = configDoc.data();
          
          if (data.api_keys) {
            setApiFootball(data.api_keys.api_football || '');
            setMercadoPago(data.api_keys.mercado_pago || '');
            setZApi(data.api_keys.z_api || '');
          }

          if (data.prize_rules) {
            setGlobalWinChance(data.prize_rules.global_win_chance || 10);
          }
        }
      } catch (e) {
        console.error("Erro ao carregar os dados:", e);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      await setDoc(doc(db, "system_config", "general"), {
        api_keys: {
          api_football: apiFootball,
          mercado_pago: mercadoPago,
          z_api: zApi
        },
        prize_rules: {
          global_win_chance: globalWinChance
        }
      }, { merge: true });
      setMessage('Configurações salvas com sucesso!');
    } catch (e) {
      console.error("Erro ao salvar os dados:", e);
      setMessage('Erro ao salvar as configurações.');
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return <div className="p-8 text-center">Carregando painel admin...</div>;
  }

  return (
    <div className="max-w-4xl mx-auto p-6 bg-white shadow-md rounded-lg mt-8">
      <h1 className="text-3xl font-bold mb-6 text-gray-800">Painel Administrativo</h1>
      
      {message && (
        <div className={`p-4 mb-6 rounded ${message.includes('Erro') ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
          {message}
        </div>
      )}

      <form onSubmit={handleSave}>
        <div className="mb-8">
          <h2 className="text-xl font-semibold mb-4 text-gray-700 border-b pb-2">Chaves de API</h2>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">API Football</label>
              <input type="text" className="w-full p-2 border rounded focus:ring-2 focus:ring-green-500" value={apiFootball} onChange={e => setApiFootball(e.target.value)} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Mercado Pago</label>
              <input type="text" className="w-full p-2 border rounded focus:ring-2 focus:ring-green-500" value={mercadoPago} onChange={e => setMercadoPago(e.target.value)} />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Z-API (WhatsApp)</label>
              <input type="text" className="w-full p-2 border rounded focus:ring-2 focus:ring-green-500" value={zApi} onChange={e => setZApi(e.target.value)} />
            </div>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-xl font-semibold mb-4 text-gray-700 border-b pb-2">Regras de Premiação</h2>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Chance Global de Vitória (%)</label>
              <input type="number" step="1" min="1" max="100" className="w-full p-2 border rounded focus:ring-2 focus:ring-green-500" value={globalWinChance} onChange={e => setGlobalWinChance(parseInt(e.target.value, 10))} />
              <p className="text-sm text-gray-500 mt-1">Ex: 10 significa que 10% das raspadinhas jogadas serão premiadas (Sorteio Aleatório - RNG).</p>
            </div>
          </div>
        </div>

        <button 
          type="submit" 
          disabled={saving}
          className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-4 rounded transition-colors disabled:bg-gray-400"
        >
          {saving ? 'Salvando...' : 'Salvar Configurações'}
        </button>
      </form>
    </div>
  );
}
