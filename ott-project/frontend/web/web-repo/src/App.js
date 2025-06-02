import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import './App.css'
import Home from './pages/Home.js'
import Login from './pages/Login.js'

function App() {
  return (
    <BrowserRouter>
      <div className="nav" style={{ padding: '1rem', background: '#222', color: 'white' }}>
        <Link to="/home" style={{ marginRight: '1rem', color: 'lightgray' }}>Home</Link>
        <Link to="/login" style={{ color: 'lightgray' }}>Login</Link>
      </div>
      <Routes>
        <Route path="/home" element={<Home />} />
        <Route path="/login" element={<Login />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App