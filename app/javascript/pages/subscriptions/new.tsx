import { Head, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AppLayout from '@/components/app_layout'
import SubscriptionForm, { type SubscriptionFormValues } from '@/components/subscription_form'
import type { Category } from '@/types'

type NewSubscriptionPageProps = {
  categories: Category[]
  errors?: Record<string, string[]>
}

export default function NewSubscription({ categories, errors }: NewSubscriptionPageProps) {
  const form = useForm<SubscriptionFormValues>({
    name: '',
    service_directory_entry_id: '',
    amount: '',
    billing_cycle: 'monthly',
    billing_anchor_date: '',
    category_id: '',
    amount_type: 'fixed',
    subscription_type: 'regular',
    trial_end_date: '',
    status: 'active',
    rating: '',
    tag: '',
    notes: '',
  })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((data) => ({ subscription: data }))
    form.post('/subscriptions')
  }

  return (
    <AppLayout title="Add a subscription">
      <Head title="Add a subscription" />

      <form onSubmit={submit} className="max-w-lg space-y-6">
        <SubscriptionForm form={form} categories={categories} errors={errors} />

        <button
          type="submit"
          disabled={form.processing}
          className="rounded-md bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
        >
          Add subscription
        </button>
      </form>
    </AppLayout>
  )
}
