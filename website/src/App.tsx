import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { Layout } from './components/Layout';
import { Home } from './pages/Home';
import { Regulamento, Privacidade, Termos, JogoResponsavel } from './pages/StaticPages';
import { Admin } from './pages/Admin';
import { FAQ } from './pages/FAQ';
import { ComoFunciona } from './pages/ComoFunciona';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Home />} />
          <Route path="regulamento" element={<Regulamento />} />
          <Route path="privacidade" element={<Privacidade />} />
          <Route path="termos" element={<Termos />} />
          <Route path="jogo-responsavel" element={<JogoResponsavel />} />
          <Route path="como-funciona" element={<ComoFunciona />} />
          <Route path="faq" element={<FAQ />} />
          <Route path="admin" element={<Admin />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
