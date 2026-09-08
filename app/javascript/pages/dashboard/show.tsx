import { Head, Link } from '@inertiajs/react'
import { useState } from 'react'
import AppLayout from '@/components/app_layout'

type CategoryBreakdownEntry = {
  category: { id: string; name: string; color: string | null }
  monthly_total: string
}

type UpcomingRenewal = {
  id: string
  name: string
  renewal_date: string
  amount: string | null
}

type CycleSplit = {
  monthly_count: number
  yearly_count: number
  monthly_cost: string
  yearly_cost: string
}

type DashboardPageProps = {
  monthly_total: string
  actual_this_month_total: string
  upcoming_renewals: UpcomingRenewal[]
  category_breakdown: CategoryBreakdownEntry[]
  cycle_split: CycleSplit
}

export default function Dashboard({
  monthly_total,
  actual_this_month_total,
  upcoming_renewals,
  category_breakdown,
  cycle_split,
}: DashboardPageProps) {
  const [view, setView] = useState<'normalized' | 'actual'>('normalized')
  const total = view === 'normalized' ? monthly_total : actual_this_month_total
  const maxCategoryTotal = Math.max(1, ...category_breakdown.map((entry) => Number(entry.monthly_total)))

  return (
    <AppLayout title="Dashboard">
      <Head title="Dashboard" />

      <div className="mb-8 flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setView('normalized')}
              className={`text-xs font-semibold uppercase tracking-wide ${view === 'normalized' ? 'text-slate-900' : 'text-slate-400'}`}
            >
              Monthly (normalized)
            </button>
            <span className="text-slate-300">·</span>
            <button
              type="button"
              onClick={() => setView('actual')}
              className={`text-xs font-semibold uppercase tracking-wide ${view === 'actual' ? 'text-slate-900' : 'text-slate-400'}`}
            >
              This month&rsquo;s actual
            </button>
          </div>
          <p className="mt-1 text-4xl font-bold tracking-tight text-slate-900">€{total}</p>
        </div>
        <Link
          href="/subscriptions/new"
          className="rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-slate-800"
        >
          + Add subscription
        </Link>
      </div>

      <div className="mb-8 grid grid-cols-2 gap-4">
        <div className="rounded-md border border-slate-200 bg-white p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Monthly</p>
          <p className="mt-1 text-lg font-bold text-slate-900">
            {cycle_split.monthly_count} · €{cycle_split.monthly_cost}
          </p>
        </div>
        <div className="rounded-md border border-slate-200 bg-white p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Yearly</p>
          <p className="mt-1 text-lg font-bold text-slate-900">
            {cycle_split.yearly_count} · €{cycle_split.yearly_cost}
          </p>
        </div>
      </div>

      <section className="mb-8">
        <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">
          Upcoming renewals (next 14 days)
        </h2>
        {upcoming_renewals.length === 0 ? (
          <p className="mt-3 text-sm text-slate-500">Nothing renewing soon.</p>
        ) : (
          <ul className="mt-3 divide-y divide-slate-200 rounded-md border border-slate-200 bg-white">
            {upcoming_renewals.map((entry) => (
              <li key={entry.id}>
                <Link href={`/subscriptions/${entry.id}`} className="flex items-center justify-between px-4 py-3">
                  <span className="text-sm font-medium text-slate-900">{entry.name}</span>
                  <span className="text-sm text-slate-500">{entry.renewal_date}</span>
                  <span className="text-sm font-semibold text-slate-900">
                    {entry.amount ? `€${entry.amount}` : '—'}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section>
        <h2 className="text-xs font-semibold uppercase tracking-wide text-slate-500">By category</h2>
        {category_breakdown.length === 0 ? (
          <p className="mt-3 text-sm text-slate-500">Add a subscription to see your breakdown.</p>
        ) : (
          <ul className="mt-3 space-y-2">
            {category_breakdown.map((entry) => (
              <li key={entry.category.id} className="flex items-center gap-3">
                <span className="w-32 shrink-0 truncate text-sm text-slate-700">{entry.category.name}</span>
                <div className="h-2 flex-1 rounded-full bg-slate-100">
                  <div
                    className="h-2 rounded-full"
                    style={{
                      width: `${(Number(entry.monthly_total) / maxCategoryTotal) * 100}%`,
                      backgroundColor: entry.category.color ?? '#94a3b8',
                    }}
                  />
                </div>
                <span className="w-16 shrink-0 text-right text-sm font-semibold text-slate-900">
                  €{entry.monthly_total}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </AppLayout>
  )
}
