import { Link } from 'react-router-dom'

export default function Stats() {
  return (
    <div style={{ padding: '2rem' }}>
      <h1>統計</h1>
      <p>ここに学習時間の統計が表示されます</p>
      <div style={{ marginTop: '2rem' }}>
        <Link to="/">ホームに戻る</Link>
      </div>
    </div>
  )
}
