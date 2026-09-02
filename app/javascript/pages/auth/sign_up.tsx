import { Head, useForm } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthLayout from '@/components/auth_layout'
import GoogleSignInButton from '@/components/google_sign_in_button'

type SignUpPageProps = {
  errors?: Record<string, string[]>
}

export default function SignUp({ errors }: SignUpPageProps) {
  const form = useForm({ email: '', password: '' })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((data) => ({ user: data }))
    form.post('/users')
  }

  return (
    <AuthLayout eyebrow="Let's get started with your subscriptions" title="Create your account">
      <Head title="Sign up" />

      <form onSubmit={submit} className="space-y-4">
        <div>
          <label htmlFor="email" className="sr-only">
            Email
          </label>
          <input
            id="email"
            type="email"
            autoComplete="email"
            placeholder="Email"
            value={form.data.email}
            onChange={(e) => form.setData('email', e.target.value)}
            className="w-full rounded-md border border-slate-300 px-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900"
          />
          {errors?.email && <p className="mt-1 text-sm text-red-600">Email {errors.email[0]}</p>}
        </div>

        <div>
          <label htmlFor="password" className="sr-only">
            Password
          </label>
          <input
            id="password"
            type="password"
            autoComplete="new-password"
            placeholder="Password"
            value={form.data.password}
            onChange={(e) => form.setData('password', e.target.value)}
            className="w-full rounded-md border border-slate-300 px-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900"
          />
          {errors?.password && <p className="mt-1 text-sm text-red-600">Password {errors.password[0]}</p>}
        </div>

        <button
          type="submit"
          disabled={form.processing}
          className="w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
        >
          Create account
        </button>
      </form>

      <p className="mt-4 text-sm text-slate-500">
        Already have an account?{' '}
        <a href="/users/sign_in" className="font-semibold text-slate-900 hover:underline">
          Log in
        </a>
      </p>

      <div className="relative mt-8">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-slate-200" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-white px-2 text-slate-400">Or continue with</span>
        </div>
      </div>

      <div className="mt-6 space-y-3">
        <GoogleSignInButton />

        <a
          href="/login/passwordless"
          className="flex w-full items-center justify-center rounded-md border border-slate-300 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
        >
          Email me a magic link
        </a>
      </div>
    </AuthLayout>
  )
}
