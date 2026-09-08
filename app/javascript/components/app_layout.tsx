import { Link, router } from '@inertiajs/react'
import type { ReactNode } from 'react'

type AppLayoutProps = {
  title: string
  children: ReactNode
}

// Shared shell for authenticated pages. Deliberately minimal — real
// navigation/branding lands with the Dashboard (Phase 1 ticket 1.8), the
// intended landing screen the rest of the nav will be built around.
export default function AppLayout({ title, children }: AppLayoutProps) {
  const signOut = () => router.delete('/users/sign_out')

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-4xl items-center justify-between px-6 py-4">
          <Link href="/" className="text-lg font-bold tracking-tight text-slate-900">
            Renewly
          </Link>
          <nav className="flex items-center gap-4 text-sm font-medium text-slate-600">
            <Link href="/subscriptions" className="hover:text-slate-900">
              Subscriptions
            </Link>
            <Link href="/categories" className="hover:text-slate-900">
              Categories
            </Link>
            <button type="button" onClick={signOut} className="hover:text-slate-900">
              Sign out
            </button>
          </nav>
        </div>
      </header>

      <main className="mx-auto max-w-4xl px-6 py-10">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">{title}</h1>
        <div className="mt-6">{children}</div>
      </main>
    </div>
  )
}
