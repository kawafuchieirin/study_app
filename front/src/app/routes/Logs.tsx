import { Link } from 'react-router-dom'

export default function Logs() {
  return (
    <div style={{ padding: '2rem' }}>
      <h1>学習ログ一覧</h1>
      <p>ここに学習ログの一覧が表示されます</p>
      <div style={{ marginTop: '2rem' }}>
        <Link to="/">ホームに戻る</Link>
      </div>
    </div>
  )
}
