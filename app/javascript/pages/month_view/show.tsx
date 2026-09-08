import { Head, Link } from '@inertiajs/react'
import AppLayout from '@/components/app_layout'

type MonthViewEntry = {
  id: string
  name: string
  billing_cycle: 'monthly' | 'yearly'
  renewal_date: string
  amount: string | null
  is_estimated: boolean
  category: { id: string; name: string; color: string | null }
}

type MonthViewPageProps = {
  year: number
  month: number
  entries: MonthViewEntry[]
  prev_month: { year: number; month: number }
  next_month: { year: number; month: number }
}

const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
]

function groupByDate(entries: MonthViewEntry[]) {
  const byDate = new Map<string, MonthViewEntry[]>()
  for (const entry of entries) {
    byDate.set(entry.renewal_date, [...(byDate.get(entry.renewal_date) ?? []), entry])
  }
  return Array.from(byDate.entries())
}

function formatDay(dateString: string) {
  const day = Number(dateString.split('-')[2])
  return `${day}${['th', 'st', 'nd', 'rd'][day % 10 > 3 || [11, 12, 13].includes(day % 100) ? 0 : day % 10]}`
}

export default function MonthView({ year, month, entries, prev_month, next_month }: MonthViewPageProps) {
  const grouped = groupByDate(entries)

  return (
    <AppLayout title="Month View">
      <Head title="Month View" />

      <div className="mb-6 flex items-center justify-between">
        <Link
          href={`/month_view?year=${prev_month.year}&month=${prev_month.month}`}
          className="rounded-md border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-50"
        >
          ← Prev
        </Link>
        <h2 className="text-lg font-semibold text-slate-900">
          {MONTH_NAMES[month - 1]} {year}
        </h2>
        <Link
          href={`/month_view?year=${next_month.year}&month=${next_month.month}`}
          className="rounded-md border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-50"
        >
          Next →
        </Link>
      </div>

      {entries.length === 0 ? (
        <p className="text-sm text-slate-500">Nothing renews this month.</p>
      ) : (
        <div className="space-y-6">
          {grouped.map(([date, dateEntries]) => (
            <section key={date}>
              <h3 className="text-xs font-semibold uppercase tracking-wide text-slate-500">{formatDay(date)}</h3>
              <ul className="mt-2 divide-y divide-slate-200 rounded-md border border-slate-200 bg-white">
                {dateEntries.map((entry) => (
                  <li key={entry.id}>
                    <Link href={`/subscriptions/${entry.id}`} className="flex items-center justify-between px-4 py-3">
                      <span className="flex min-w-0 items-center gap-3">
                        <span
                          className="h-2.5 w-2.5 shrink-0 rounded-full"
                          style={{ backgroundColor: entry.category.color ?? '#94a3b8' }}
                        />
                        <span className="min-w-0">
                          <span className="flex items-center gap-2">
                            <span className="truncate text-sm font-medium text-slate-900">{entry.name}</span>
                            {entry.billing_cycle === 'yearly' && (
                              <span className="rounded-full bg-indigo-100 px-2 py-0.5 text-[10px] font-semibold text-indigo-700">
                                YEARLY
                              </span>
                            )}
                          </span>
                          <span className="block text-xs text-slate-500">{entry.category.name}</span>
                        </span>
                      </span>
                      <span className="shrink-0 text-sm font-semibold text-slate-900">
                        {entry.amount ? `${entry.is_estimated ? '~' : ''}€${entry.amount}` : '—'}
                      </span>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      )}
    </AppLayout>
  )
}
