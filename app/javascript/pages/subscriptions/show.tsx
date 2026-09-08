import { Head, Link } from '@inertiajs/react'
import AppLayout from '@/components/app_layout'
import type { Subscription } from '@/types'

type ShowSubscriptionPageProps = {
  subscription: Subscription
}

const STATUS_LABEL: Record<Subscription['status'], string> = {
  active: 'Active',
  paused: 'Paused',
  cancelled: 'Cancelled',
}

export default function ShowSubscription({ subscription }: ShowSubscriptionPageProps) {
  return (
    <AppLayout title={subscription.name}>
      <Head title={subscription.name} />

      <div className="max-w-lg space-y-6">
        <div className="rounded-md border border-slate-200 bg-white p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-500">{subscription.category.name}</p>
              <p className="mt-1 text-2xl font-bold text-slate-900">
                {subscription.current_amount ? `€${subscription.current_amount}` : 'No amount recorded yet'}
                <span className="ml-1 text-sm font-normal text-slate-500">
                  / {subscription.billing_cycle === 'monthly' ? 'month' : 'year'}
                </span>
              </p>
            </div>
            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700">
              {STATUS_LABEL[subscription.status]}
            </span>
          </div>

          {subscription.subscription_type === 'trial' && subscription.trial_end_date && (
            <p className="mt-3 rounded-md bg-amber-50 px-3 py-2 text-sm font-medium text-amber-800">
              Free trial ends {subscription.trial_end_date}
            </p>
          )}

          <dl className="mt-6 space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-slate-500">
                {subscription.billing_cycle === 'monthly' ? 'Billing day' : 'Renewal date'}
              </dt>
              <dd className="text-slate-900">{subscription.billing_anchor_date}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-slate-500">Amount type</dt>
              <dd className="text-slate-900">{subscription.amount_type === 'fixed' ? 'Fixed' : 'Variable'}</dd>
            </div>
            {subscription.tag && (
              <div className="flex justify-between">
                <dt className="text-slate-500">Tag</dt>
                <dd className="text-slate-900">{subscription.tag === 'essential' ? 'Essential' : 'Nice-to-have'}</dd>
              </div>
            )}
            {subscription.rating && (
              <div className="flex justify-between">
                <dt className="text-slate-500">Worth-it rating</dt>
                <dd className="text-slate-900">{subscription.rating} / 5</dd>
              </div>
            )}
          </dl>

          {subscription.notes && <p className="mt-4 text-sm text-slate-600">{subscription.notes}</p>}
        </div>

        {subscription.cancellation_url && (
          <a
            href={subscription.cancellation_url}
            target="_blank"
            rel="noreferrer"
            className="block w-full rounded-md border border-slate-300 px-4 py-2.5 text-center text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            How to cancel
          </a>
        )}

        <Link
          href={`/subscriptions/${subscription.id}/edit`}
          className="block w-full rounded-md bg-slate-900 px-4 py-2.5 text-center text-sm font-semibold text-white hover:bg-slate-800"
        >
          Edit subscription
        </Link>
      </div>
    </AppLayout>
  )
}
