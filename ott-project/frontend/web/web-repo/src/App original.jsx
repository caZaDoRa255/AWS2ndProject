import {Routes, Route, Link, useNavigate } from 'react-router-dom'

import { useState, useEffect } from 'react'
import './App.css'
import Home from './pages/Home.jsx'
import Auth from './pages/Auth.jsx'
import Me from './pages/me.jsx'
import Sub from './pages/Sub.jsx'
import Upload from './pages/upload.jsx'
import Stream from './pages/stream.jsx'
import Search from './pages/search.jsx'; // search.jsx import 추가
import ContentDetail from './pages/contentDetail.jsx'
import AdminLogin from './pages/admin/adminLogin.jsx'
import AdminDashboard from './pages/admin/adminDashboard.jsx'
import Chat from './pages/Chat.jsx'
import StickerGame from './pages/StickerGame.jsx'

function App() {
  // const callGCPFunction = async () => {
  // try {
  //   const res = await fetch("https://REGION-PROJECT_ID.cloudfunctions.net/YOUR_FUNCTION_NAME", {
  //     method: "GET", // 또는 POST 등
  //     headers: {
  //       "Content-Type": "application/json",
  //       // 필요시 Authorization 헤더도 추가
  //     }
  //   });

  //   if (!res.ok) throw new Error("GCP 호출 실패");

  //   const result = await res.json();
  //   alert("함수 호출 성공: " + JSON.stringify(result));
  // } catch (err) {
  //   console.error(err);
  //   alert("GCP 호출 실패: " + err.message);
  // }
  // }; // 이건 나중에 지운다.

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
          {/* <button onClick={callGCPFunction} className="gcp-button">⚙️ GCP 호출</button>  */}
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
        <Route path="/chat" element={<Chat />} />
        <Route path="/Sub" element={<Sub />} />
        <Route path="/upload" element={<Upload />} />
        <Route path="/stream" element={<Stream />} />
        <Route path="/search" element={<Search />} />
        
        <Route path="/content/:id" element={<ContentDetail />} />
        <Route path="/admin" element={<AdminLogin />} />
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/sticker-game" element={<StickerGame />} />
      </Routes>
    </div>
  );
}

export default App;