import type { InertiaFormProps } from '@inertiajs/react'
import { useEffect, useState } from 'react'
import type { Category, ServiceDirectoryEntry } from '@/types'

export type SubscriptionFormValues = {
  name: string
  service_directory_entry_id: string
  amount: string
  billing_cycle: string
  billing_anchor_date: string
  category_id: string
  amount_type: string
  subscription_type: string
  trial_end_date: string
  status: string
  rating: string
  tag: string
  notes: string
}

type SubscriptionFormProps = {
  form: InertiaFormProps<SubscriptionFormValues>
  categories: Category[]
  errors?: Record<string, string[]>
  isEdit?: boolean
}

const inputClass =
  'w-full rounded-md border border-slate-300 px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900'
const labelClass = 'block text-sm font-medium text-slate-700'

function FieldError({ messages }: { messages?: string[] }) {
  if (!messages?.length) return null
  return <p className="mt-1 text-sm text-red-600">{messages[0]}</p>
}

// Name-based autocomplete against the known-service directory (PRD 4.4.1):
// picking a match prefills the category and links the subscription to it,
// without overriding any icon/color the user hasn't asked to customize.
function useDirectorySearch(query: string) {
  const [results, setResults] = useState<ServiceDirectoryEntry[]>([])

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([])
      return
    }

    const timeout = setTimeout(() => {
      fetch(`/service_directory_entries?q=${encodeURIComponent(query)}`, {
        headers: { Accept: 'application/json' },
      })
        .then((res) => res.json())
        .then(setResults)
        .catch(() => setResults([]))
    }, 250)

    return () => clearTimeout(timeout)
  }, [query])

  return results
}

export default function SubscriptionForm({ form, categories, errors, isEdit = false }: SubscriptionFormProps) {
  const { data, setData } = form
  const [nameFocused, setNameFocused] = useState(false)
  const matches = useDirectorySearch(data.service_directory_entry_id ? '' : data.name)

  const selectMatch = (entry: ServiceDirectoryEntry) => {
    setData((current) => ({
      ...current,
      name: entry.name,
      service_directory_entry_id: entry.id,
      category_id: entry.default_category_id,
    }))
    setNameFocused(false)
  }

  return (
    <div className="space-y-5">
      <div className="relative">
        <label className={labelClass} htmlFor="name">
          Name
        </label>
        <input
          id="name"
          type="text"
          value={data.name}
          onChange={(e) => setData({ ...data, name: e.target.value, service_directory_entry_id: '' })}
          onFocus={() => setNameFocused(true)}
          onBlur={() => setTimeout(() => setNameFocused(false), 150)}
          placeholder="e.g. Netflix"
          autoComplete="off"
          className={`mt-1 ${inputClass}`}
        />
        <FieldError messages={errors?.name} />

        {nameFocused && matches.length > 0 && (
          <ul className="absolute z-10 mt-1 w-full rounded-md border border-slate-200 bg-white shadow-lg">
            {matches.map((entry) => (
              <li key={entry.id}>
                <button
                  type="button"
                  onMouseDown={() => selectMatch(entry)}
                  className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-slate-50"
                >
                  <span className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.brand_color ?? '#94a3b8' }} />
                  {entry.name}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div>
        <label className={labelClass} htmlFor="amount">
          Amount (EUR)
        </label>
        <input
          id="amount"
          type="number"
          step="0.01"
          min="0"
          value={data.amount}
          onChange={(e) => setData('amount', e.target.value)}
          placeholder={isEdit ? 'Leave blank to keep the current amount' : '9.99'}
          className={`mt-1 ${inputClass}`}
        />
        <FieldError messages={errors?.amount} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className={labelClass} htmlFor="billing_cycle">
            Billing cycle
          </label>
          <select
            id="billing_cycle"
            value={data.billing_cycle}
            onChange={(e) => setData('billing_cycle', e.target.value)}
            className={`mt-1 ${inputClass}`}
          >
            <option value="monthly">Monthly</option>
            <option value="yearly">Yearly</option>
          </select>
        </div>

        <div>
          <label className={labelClass} htmlFor="billing_anchor_date">
            {data.billing_cycle === 'yearly' ? 'Renewal date' : 'Billing day'}
          </label>
          <input
            id="billing_anchor_date"
            type="date"
            value={data.billing_anchor_date}
            onChange={(e) => setData('billing_anchor_date', e.target.value)}
            className={`mt-1 ${inputClass}`}
          />
          <FieldError messages={errors?.billing_anchor_date} />
        </div>
      </div>

      <div>
        <label className={labelClass} htmlFor="category_id">
          Category
        </label>
        <select
          id="category_id"
          value={data.category_id}
          onChange={(e) => setData('category_id', e.target.value)}
          className={`mt-1 ${inputClass}`}
        >
          <option value="" disabled>
            Choose a category
          </option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </select>
        <FieldError messages={errors?.category} />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <span className={labelClass}>Amount type</span>
          <div className="mt-1 flex gap-2">
            {(
              [
                ['fixed', 'Fixed'],
                ['variable', 'Variable'],
              ] as const
            ).map(([value, label]) => (
              <button
                key={value}
                type="button"
                onClick={() => setData('amount_type', value)}
                className={`rounded-md border px-3 py-2 text-sm font-medium ${
                  data.amount_type === value
                    ? 'border-slate-900 bg-slate-900 text-white'
                    : 'border-slate-300 text-slate-600 hover:bg-slate-50'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <span className={labelClass}>Type</span>
          <div className="mt-1 flex gap-2">
            {(
              [
                ['regular', 'Regular'],
                ['trial', 'Free trial'],
              ] as const
            ).map(([value, label]) => (
              <button
                key={value}
                type="button"
                onClick={() => setData('subscription_type', value)}
                className={`rounded-md border px-3 py-2 text-sm font-medium ${
                  data.subscription_type === value
                    ? 'border-slate-900 bg-slate-900 text-white'
                    : 'border-slate-300 text-slate-600 hover:bg-slate-50'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {data.subscription_type === 'trial' && (
        <div>
          <label className={labelClass} htmlFor="trial_end_date">
            Trial ends
          </label>
          <input
            id="trial_end_date"
            type="date"
            value={data.trial_end_date}
            onChange={(e) => setData('trial_end_date', e.target.value)}
            className={`mt-1 ${inputClass}`}
          />
        </div>
      )}

      {isEdit && (
        <div>
          <label className={labelClass} htmlFor="status">
            Status
          </label>
          <select
            id="status"
            value={data.status}
            onChange={(e) => setData('status', e.target.value)}
            className={`mt-1 ${inputClass}`}
          >
            <option value="active">Active</option>
            <option value="paused">Paused</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
      )}

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className={labelClass} htmlFor="rating">
            Worth-it rating
          </label>
          <select
            id="rating"
            value={data.rating}
            onChange={(e) => setData('rating', e.target.value)}
            className={`mt-1 ${inputClass}`}
          >
            <option value="">Not rated</option>
            {[1, 2, 3, 4, 5].map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className={labelClass} htmlFor="tag">
            Tag
          </label>
          <select
            id="tag"
            value={data.tag}
            onChange={(e) => setData('tag', e.target.value)}
            className={`mt-1 ${inputClass}`}
          >
            <option value="">None</option>
            <option value="essential">Essential</option>
            <option value="nice_to_have">Nice-to-have</option>
          </select>
        </div>
      </div>

      <div>
        <label className={labelClass} htmlFor="notes">
          Notes
        </label>
        <textarea
          id="notes"
          value={data.notes}
          onChange={(e) => setData('notes', e.target.value)}
          rows={3}
          className={`mt-1 ${inputClass}`}
        />
      </div>
    </div>
  )
}
