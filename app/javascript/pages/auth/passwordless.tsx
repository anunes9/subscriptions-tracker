import { Head, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthLayout from '@/components/auth_layout'

type PasswordlessPageProps = {
  sent_to?: string
  errors?: Record<string, string[]>
}

export default function Passwordless({ sent_to, errors }: PasswordlessPageProps) {
  const emailForm = useForm({ email: '' })
  const codeForm = useForm({ code: '' })

  const requestLink = (e: FormEvent) => {
    e.preventDefault()
    emailForm.post('/login/passwordless')
  }

  const verifyCode = (e: FormEvent) => {
    e.preventDefault()
    codeForm.transform((data) => ({ ...data, email: sent_to }))
    codeForm.post('/login/passwordless/verify')
  }

  if (sent_to) {
    return (
      <AuthLayout eyebrow={`We sent a link and a code to ${sent_to}`} title="Check your email">
        <Head title="Check your email" />

        <p className="mb-6 text-sm text-slate-500">
          Click the link in the email, or enter the 6-digit code below. It expires in 10 minutes.
        </p>

        <form onSubmit={verifyCode} className="space-y-4">
          <div>
            <label htmlFor="code" className="sr-only">
              6-digit code
            </label>
            <input
              id="code"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              placeholder="123456"
              maxLength={6}
              value={codeForm.data.code}
              onChange={(e) => codeForm.setData('code', e.target.value)}
              className="w-full rounded-md border border-slate-300 px-4 py-2.5 text-center text-lg tracking-[0.5em] text-slate-900 placeholder:tracking-normal placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900"
            />
            {errors?.code && <p className="mt-1 text-sm text-red-600">Code {errors.code[0]}</p>}
          </div>

          <button
            type="submit"
            disabled={codeForm.processing}
            className="w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
          >
            Verify code
          </button>
        </form>

        <p className="mt-4 text-sm text-slate-500">
          <a href="/login/passwordless" className="font-semibold text-slate-900 hover:underline">
            Use a different email
          </a>
        </p>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout eyebrow="No password needed" title="Sign in with a magic link">
      <Head title="Sign in with a magic link" />

      <form onSubmit={requestLink} className="space-y-4">
        <div>
          <label htmlFor="email" className="sr-only">
            Email
          </label>
          <input
            id="email"
            type="email"
            autoComplete="email"
            placeholder="Email"
            value={emailForm.data.email}
            onChange={(e) => emailForm.setData('email', e.target.value)}
            className="w-full rounded-md border border-slate-300 px-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900"
          />
        </div>

        <button
          type="submit"
          disabled={emailForm.processing}
          className="w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
        >
          Send magic link
        </button>
      </form>

      <p className="mt-4 text-sm text-slate-500">
        <a href="/users/sign_in" className="font-semibold text-slate-900 hover:underline">
          Back to log in
        </a>
      </p>
    </AuthLayout>
  )
}
