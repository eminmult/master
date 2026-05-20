export type UserRole = 'client' | 'master' | 'admin'

export interface User {
  id: number
  first_name: string
  last_name: string | null
  full_name?: string
  email: string | null
  phone: string
  role: UserRole
  avatar_url: string | null
  rating_avg?: string | number
  rating_count?: number
  is_active?: boolean
  master_profile?: MasterProfile | null
  addresses?: Address[]
}

export interface MasterProfile {
  id?: number
  categories?: Category[]
  portfolio?: PortfolioItem[]
  skills?: Record<string, any>
  completed_orders?: number
  is_accepting_orders?: boolean
  bio?: string | null
  experience_years?: number | null
}

export interface PortfolioItem {
  id: number
  image_url?: string
  thumb_url?: string
  medium_url?: string
  large_url?: string
  caption?: string | null
}

export interface Address {
  id: number
  label?: string | null
  full_address: string
  lat?: number | null
  lng?: number | null
  is_default?: boolean
}

export interface Category {
  id: number
  name: string
  description?: string | null
  icon_url?: string | null
  masters_count?: number
  base_price?: number | null
  subcategories?: Subcategory[]
}

export interface Subcategory {
  id: number
  name: string
  category_id: number
}

export type OrderStatus =
  | 'pending_master'
  | 'pending_client'
  | 'discussion'
  | 'confirmed'
  | 'accepted'
  | 'on_the_way'
  | 'arrived'
  | 'in_progress'
  | 'awaiting_completion'
  | 'awaiting_review'
  | 'completed'
  | 'closed'
  | 'canceled_by_client'
  | 'canceled_by_master'
  | 'canceled_by_system'

export interface Order {
  id: number
  client_id: number
  master_id: number | null
  category_id: number
  status: OrderStatus
  description: string | null
  full_address: string
  lat?: number | null
  lng?: number | null
  district?: string | null
  urgency?: 'normal' | 'urgent' | null
  estimated_budget?: number | null
  agreed_price?: number | null
  contact_phone?: string
  created_at: string
  updated_at?: string
  category?: Category
  client?: User
  master?: User
  photos?: any[]
  status_history?: any[]
  client_reviewed?: boolean
  master_reviewed?: boolean
}

export interface NotificationItem {
  id: number
  user_id: number
  type: string
  title: string
  body: string
  data?: Record<string, any>
  is_read: boolean
  created_at: string
}
