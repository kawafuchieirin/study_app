import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Home from './app/routes/Home'
import Logs from './app/routes/Logs'
import Stats from './app/routes/Stats'

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/logs" element={<Logs />} />
        <Route path="/stats" element={<Stats />} />
      </Routes>
    </Router>
  )
}

export default App
