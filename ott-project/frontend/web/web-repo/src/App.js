import { BrowserRouter, Routes, Route, Link } from 'react-router-dom'
import './App.css'
import Home from './pages/Home.js'
import Auth from './pages/Auth.js'

function App() {
  return (
    <BrowserRouter>
      <div className="nav" style={{ padding: '1rem', background: '#222', color: 'white' }}>
        <Link to="/home" style={{ marginRight: '1rem', color: 'lightgray' }}>Home</Link>
        <Link to="/auth" style={{ color: 'lightgray' }}>Auth</Link>
      </div>
      <Routes>
        <Route path="/home" element={<Home />} />
        <Route path="/auth" element={<Auth />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App