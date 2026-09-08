import { Head, router, useForm } from '@inertiajs/react'
import { type FormEvent, useMemo, useState } from 'react'
import type { ServiceDirectoryEntry } from '@/types'

type OnboardingPageProps = {
  service_directory_entries: ServiceDirectoryEntry[]
}

type Selection = {
  amount: string
  billing_anchor_date: string
  billing_cycle: 'monthly' | 'yearly'
}

const inputClass =
  'w-full rounded-md border border-slate-300 px-2 py-1.5 text-sm text-slate-900 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900'

export default function Onboarding({ service_directory_entries }: OnboardingPageProps) {
  const [selections, setSelections] = useState<Record<string, Selection>>({})
  const form = useForm<{ selections: (Selection & { service_directory_entry_id: string })[] }>({ selections: [] })

  const grouped = useMemo(() => {
    const byCategory = new Map<string, ServiceDirectoryEntry[]>()
    for (const entry of service_directory_entries) {
      const key = entry.default_category_name ?? 'Other'
      byCategory.set(key, [...(byCategory.get(key) ?? []), entry])
    }
    return Array.from(byCategory.entries())
  }, [service_directory_entries])

  const toggle = (entry: ServiceDirectoryEntry) => {
    setSelections((current) => {
      const next = { ...current }
      if (next[entry.id]) {
        delete next[entry.id]
      } else {
        next[entry.id] = { amount: '', billing_anchor_date: '', billing_cycle: 'monthly' }
      }
      return next
    })
  }

  const updateSelection = (id: string, patch: Partial<Selection>) => {
    setSelections((current) => ({ ...current, [id]: { ...current[id], ...patch } }))
  }

  const selectedEntries = service_directory_entries.filter((entry) => selections[entry.id])

  const finish = (e: FormEvent) => {
    e.preventDefault()
    form.transform(() => ({
      selections: Object.entries(selections).map(([service_directory_entry_id, selection]) => ({
        service_directory_entry_id,
        ...selection,
      })),
    }))
    form.post('/onboarding')
  }

  const skip = () => router.post('/onboarding/skip')

  return (
    <div className="min-h-screen bg-slate-50">
      <Head title="Welcome to Renewly" />

      <div className="mx-auto max-w-2xl px-6 py-12">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">Which of these do you use?</h1>
        <p className="mt-2 text-sm text-slate-500">
          Tap the ones you have — we&rsquo;ll pre-fill the name and category, you just add the amount and billing date.
          Skip this if you&rsquo;d rather add subscriptions one at a time.
        </p>

        <form onSubmit={finish} className="mt-8 space-y-8">
          {grouped.map(([categoryName, entries]) => (
            <section key={categoryName}>
              <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">{categoryName}</h2>
              <div className="mt-3 flex flex-wrap gap-2">
                {entries.map((entry) => (
                  <button
                    key={entry.id}
                    type="button"
                    onClick={() => toggle(entry)}
                    className={`flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm ${
                      selections[entry.id]
                        ? 'border-slate-900 bg-slate-900 text-white'
                        : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    <span
                      className="h-2 w-2 rounded-full"
                      style={{ backgroundColor: entry.brand_color ?? '#94a3b8' }}
                    />
                    {entry.name}
                  </button>
                ))}
              </div>
            </section>
          ))}

          {selectedEntries.length > 0 && (
            <section className="rounded-md border border-slate-200 bg-white p-4">
              <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Add the amount and billing date
              </h2>
              <ul className="mt-3 space-y-3">
                {selectedEntries.map((entry) => (
                  <li key={entry.id} className="flex items-center gap-3">
                    <span className="w-32 shrink-0 truncate text-sm font-medium text-slate-900">{entry.name}</span>
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      placeholder="Amount"
                      value={selections[entry.id].amount}
                      onChange={(e) => updateSelection(entry.id, { amount: e.target.value })}
                      className={`${inputClass} w-24`}
                    />
                    <select
                      value={selections[entry.id].billing_cycle}
                      onChange={(e) =>
                        updateSelection(entry.id, { billing_cycle: e.target.value as Selection['billing_cycle'] })
                      }
                      className={`${inputClass} w-28`}
                    >
                      <option value="monthly">Monthly</option>
                      <option value="yearly">Yearly</option>
                    </select>
                    <input
                      type="date"
                      value={selections[entry.id].billing_anchor_date}
                      onChange={(e) => updateSelection(entry.id, { billing_anchor_date: e.target.value })}
                      className={inputClass}
                    />
                  </li>
                ))}
              </ul>
            </section>
          )}

          <div className="flex items-center gap-4">
            <button
              type="submit"
              disabled={form.processing || selectedEntries.length === 0}
              className="rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
            >
              Finish setup
            </button>
            <button type="button" onClick={skip} className="text-sm font-medium text-slate-500 hover:text-slate-700">
              Skip for now
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
