import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import './App.css'
import Home from './pages/Home.jsx'
import Auth from './pages/Auth.jsx'
import Me from './pages/me.jsx'

function App() {
  return (
    <BrowserRouter>
      <div className="App">
          <div className="nav">
              <div className="nav-left">
                <Link to="/home">Moodly</Link>
                <Link to="/chat">Chat</Link>
              </div>

              <div className="nav-right">
                <Link to="/auth">Auth</Link>
                <Link to="/me">Me</Link>
                <input
                  type="text"
                  placeholder="검색..."
                  className="search-input"
                />
            </div>
          </div>

        <Routes>
          <Route path="/home" element={<Home />} />
          <Route path="/auth" element={<Auth />} />
          <Route path="/me" element={<Me />} />
        </Routes>
      </div>
    </BrowserRouter>
  )
}

export default App