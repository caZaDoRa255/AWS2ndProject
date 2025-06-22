import { Routes, Route, Link, useNavigate } from 'react-router-dom'
import { useState } from 'react'
import './App.css'
import Home from './pages/Home.jsx'
import Auth from './pages/Auth.jsx'
import Me from './pages/me.jsx'
import Sub from './pages/Sub.jsx'
import Upload from './pages/upload.jsx'
import Stream from './pages/stream.jsx'
import Search from './pages/search.jsx'; // search.jsx import 추가
import ContentDetail from './pages/contentDetail.jsx'

function App() {
  const navigate = useNavigate();
  const [keyword, setKeyword] = useState("");

  const handleSearch = (e) => {
    if (e.key === 'Enter' && keyword.trim()) {
      // 🔽 search.jsx로 이동하며 keyword를 쿼리 파라미터로 전달
      navigate(`/search?keyword=${encodeURIComponent(keyword)}`);
      setKeyword(""); // (선택사항) 검색 후 입력창 초기화
    }
  };

  return (
    <div className="App">
      <div className="nav">
        <div className="nav-left">
          <Link to="/home">Moodly</Link>
          <Link to="/chat">Cozyly</Link>
        </div>

        <div className="nav-right">
          <Link to="/auth">Auth</Link>
          <Link to="/me">Me</Link>
          <Link to="/Sub">Subscription</Link>
          <input
            type="text"
            placeholder="검색..."
            className="search-input"
            value={keyword}
            onChange={(e) => setKeyword(e.target.value)}
            onKeyDown={handleSearch}
          />
        </div>
      </div>

      <Routes>
        <Route path="/home" element={<Home />} />
        <Route path="/auth" element={<Auth />} />
        <Route path="/me" element={<Me />} />
        <Route path="/Sub" element={<Sub />} />
        <Route path="/upload" element={<Upload />} />
        <Route path="/stream" element={<Stream />} />
        <Route path="/search" element={<Search />} />
        <Route path="/contentDetail" element={<ContentDetail />} />
      </Routes>
    </div>
  );
}

export default App;