import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <div style={{ padding: '2rem' }}>
      <h1>学習管理アプリ</h1>
      <p>学習の記録を管理するアプリケーションです</p>
      <nav style={{ marginTop: '2rem' }}>
        <ul style={{ listStyle: 'none', padding: 0 }}>
          <li style={{ margin: '1rem 0' }}>
            <Link to="/logs">学習ログ一覧</Link>
          </li>
          <li style={{ margin: '1rem 0' }}>
            <Link to="/stats">統計</Link>
          </li>
        </ul>
      </nav>
    </div>
  )
}
