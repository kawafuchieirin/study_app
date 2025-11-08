// 理解度の型定義
export type Understanding = 'understood' | 'partial' | 'not_understood'

// 学習ログの型定義
export interface LearningLog {
  log_id: string
  user_id: string
  start_time: string
  end_time: string
  duration_min: number
  what: string
  understanding: Understanding
  did_well?: string
  didnt_get?: string
  tags: string[]
}

// ユーザーの型定義
export interface User {
  user_id: string
  display_name: string
  created_at: string
}

// 統計サマリーの型定義
export interface StatsSummary {
  total_duration_min: number
  understood_count: number
  partial_count: number
  not_understood_count: number
}
