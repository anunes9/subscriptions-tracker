import { Head, useForm, usePage } from '@inertiajs/react'
import type { FormEvent } from 'react'
import AuthLayout from '@/components/auth_layout'
import GoogleSignInButton from '@/components/google_sign_in_button'
import type { SharedProps } from '@/types'

export default function SignIn() {
  const { flash } = usePage<SharedProps>().props
  const form = useForm({ email: '', password: '' })

  const submit = (e: FormEvent) => {
    e.preventDefault()
    form.transform((data) => ({ user: data }))
    form.post('/users/sign_in')
  }

  return (
    <AuthLayout eyebrow="Welcome back, glad to see you" title="Log in to your account">
      <Head title="Log in" />

      {flash.alert && <p className="mb-4 rounded-md bg-red-50 px-4 py-2.5 text-sm text-red-700">{flash.alert}</p>}
      {flash.notice && (
        <p className="mb-4 rounded-md bg-emerald-50 px-4 py-2.5 text-sm text-emerald-700">{flash.notice}</p>
      )}

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
        </div>

        <div>
          <label htmlFor="password" className="sr-only">
            Password
          </label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            placeholder="Password"
            value={form.data.password}
            onChange={(e) => form.setData('password', e.target.value)}
            className="w-full rounded-md border border-slate-300 px-4 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-900"
          />
        </div>

        <div className="text-right">
          <a
            href="/users/password/new"
            className="text-sm font-medium text-slate-500 hover:text-slate-900 hover:underline"
          >
            Forgot password?
          </a>
        </div>

        <button
          type="submit"
          disabled={form.processing}
          className="w-full rounded-md bg-slate-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:opacity-60"
        >
          Log in
        </button>
      </form>

      <p className="mt-4 text-sm text-slate-500">
        Don&apos;t have an account?{' '}
        <a href="/users/sign_up" className="font-semibold text-slate-900 hover:underline">
          Sign up
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
