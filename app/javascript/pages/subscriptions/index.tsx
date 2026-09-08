import { Head, Link, router } from '@inertiajs/react'
import AppLayout from '@/components/app_layout'
import type { Subscription } from '@/types'

type IndexSubscriptionsPageProps = {
  subscriptions: Subscription[]
}

export default function SubscriptionsIndex({ subscriptions }: IndexSubscriptionsPageProps) {
  const deleteSubscription = (subscription: Subscription) => {
    if (window.confirm(`Delete "${subscription.name}"?`)) {
      router.delete(`/subscriptions/${subscription.id}`)
    }
  }

  const duplicateSubscription = (subscription: Subscription) => {
    router.post(`/subscriptions/${subscription.id}/duplicate`)
  }

  return (
    <AppLayout title="Subscriptions">
      <Head title="Subscriptions" />

      <div className="mb-6 flex justify-end">
        <Link
          href="/subscriptions/new"
          className="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800"
        >
          Add subscription
        </Link>
      </div>

      {subscriptions.length === 0 ? (
        <p className="text-sm text-slate-500">No subscriptions yet — add your first one above.</p>
      ) : (
        <ul className="divide-y divide-slate-200 rounded-md border border-slate-200 bg-white">
          {subscriptions.map((subscription) => (
            <li key={subscription.id} className="flex items-center justify-between px-4 py-3">
              <Link href={`/subscriptions/${subscription.id}`} className="flex min-w-0 flex-1 items-center gap-3">
                <span
                  className="h-2.5 w-2.5 shrink-0 rounded-full"
                  style={{ backgroundColor: subscription.category.color ?? '#94a3b8' }}
                />
                <span className="min-w-0">
                  <span className="block truncate text-sm font-medium text-slate-900">{subscription.name}</span>
                  <span className="block text-xs text-slate-500">
                    {subscription.category.name} · {subscription.billing_cycle === 'monthly' ? 'Monthly' : 'Yearly'}
                    {subscription.status !== 'active' && ` · ${subscription.status}`}
                  </span>
                </span>
              </Link>

              <div className="ml-4 flex shrink-0 items-center gap-4 text-sm">
                <span className="font-semibold text-slate-900">
                  {subscription.current_amount ? `€${subscription.current_amount}` : '—'}
                </span>
                <button
                  type="button"
                  onClick={() => duplicateSubscription(subscription)}
                  className="font-medium text-slate-600 hover:text-slate-900"
                >
                  Duplicate
                </button>
                <button
                  type="button"
                  onClick={() => deleteSubscription(subscription)}
                  className="font-medium text-red-600 hover:text-red-700"
                >
                  Delete
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </AppLayout>
  )
}
