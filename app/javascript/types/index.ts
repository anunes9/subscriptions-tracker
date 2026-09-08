export type FlashData = {
  notice?: string
  alert?: string
}

export type SharedProps = {
  flash: FlashData
}

export type Category = {
  id: string
  name: string
  icon: string | null
  color: string | null
  is_preset: boolean
}

export type BillingCycle = 'monthly' | 'yearly'
export type AmountType = 'fixed' | 'variable'
export type SubscriptionType = 'regular' | 'trial'
export type SubscriptionStatus = 'active' | 'paused' | 'cancelled'
export type SubscriptionTag = 'essential' | 'nice_to_have' | null

export type Subscription = {
  id: string
  name: string
  currency: string
  billing_cycle: BillingCycle
  amount_type: AmountType
  subscription_type: SubscriptionType
  status: SubscriptionStatus
  billing_anchor_date: string
  trial_end_date: string | null
  rating: number | null
  tag: SubscriptionTag
  icon_override: string | null
  color_override: string | null
  notes: string | null
  category_id: string
  service_directory_entry_id: string | null
  current_amount: string | null
  current_amount_estimated: boolean
  category: { id: string; name: string; color: string | null; icon: string | null }
  cancellation_url?: string | null
}

export type ServiceDirectoryEntry = {
  id: string
  name: string
  icon_asset: string
  brand_color: string | null
  cancellation_url: string | null
  region: string
  default_category_id: string
}
