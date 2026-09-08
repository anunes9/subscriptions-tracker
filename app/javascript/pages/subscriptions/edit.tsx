import { Head, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppLayout from '@/components/app_layout'
import SubscriptionForm, { type SubscriptionFormValues } from '@/components/subscription_form'
import type { Category, Subscription } from '@/types'

type EditSubscriptionPageProps = {
  subscription: Subscription
  categories: Category[]
  errors?: Record<string, string[]>
}

export default function EditSubscription({ subscription, categories, errors }: EditSubscriptionPageProps) {
  const form = useForm<SubscriptionFormValues>({
    name: subscription.name,
    service_directory_entry_id: subscription.service_directory_entry_id ?? '',
    amount: '',
    billing_cycle: subscription.billing_cycle,
    billing_anchor_date: subscription.billing_anchor_date,
    category_id: subscription.category_id,
    amount_type: subscription.amount_type,
    subscription_type: subscription.subscription_type,
    trial_end_date: subscription.trial_end_date ?? '',
    status: subscription.status,
    rating: subscription.rating?.toString() ?? '',
    tag: subscription.tag ?? '',
    notes: subscription.notes ?? '',
  })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((data) => ({ subscription: data }))
    form.patch(`/subscriptions/${subscription.id}`)
  }

  return (
    <AppLayout title={`Edit ${subscription.name}`}>
      <Head title={`Edit ${subscription.name}`} />

      <form onSubmit={submit} className="max-w-lg space-y-6">
        <SubscriptionForm form={form} categories={categories} errors={errors} isEdit />

        <button
          type="submit"
          disabled={form.processing}
          className="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
        >
          Save changes
        </button>
      </form>
    </AppLayout>
  )
}
