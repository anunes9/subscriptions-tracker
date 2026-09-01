import type { ReactNode } from 'react'

type AuthLayoutProps = {
  eyebrow: string
  title: string
  children: ReactNode
}

export default function AuthLayout({ eyebrow, title, children }: AuthLayoutProps) {
  return (
    <div className="flex min-h-screen bg-white">
      <div className="flex w-full flex-col justify-center px-6 py-12 sm:px-12 lg:w-1/2 lg:px-20 xl:px-24">
        <div className="mx-auto w-full max-w-sm">
          <a href="/" className="text-xl font-bold tracking-tight text-slate-900">
            Renewly
          </a>

          <h1 className="mt-10 text-3xl font-bold tracking-tight text-slate-900">{title}</h1>
          <p className="mt-2 text-sm font-medium text-slate-500">{eyebrow}</p>

          <div className="mt-8">{children}</div>
        </div>
      </div>

      <div className="relative hidden w-1/2 overflow-hidden bg-gradient-to-b from-indigo-950 via-fuchsia-800 to-orange-300 lg:block">
        <svg
          viewBox="0 0 800 1000"
          preserveAspectRatio="xMidYMax slice"
          className="absolute inset-0 h-full w-full"
          role="img"
          aria-label="Illustration of a sunset over mountains and a lake"
        >
          <title>Illustration of a sunset over mountains and a lake</title>
          <circle cx="400" cy="360" r="130" fill="#FFE9C7" opacity="0.9" />
          <circle cx="400" cy="360" r="130" fill="url(#sun-glow)" />
          <polygon points="0,480 260,300 430,470 620,260 800,470 800,1000 0,1000" fill="#3b2f63" opacity="0.85" />
          <polygon points="0,560 300,410 520,560 800,400 800,1000 0,1000" fill="#241b45" opacity="0.9" />
          <rect x="0" y="640" width="800" height="360" fill="url(#water-fade)" />
          {[110, 230, 350, 470, 590, 710].map((x) => (
            <line key={`tree-${x}`} x1={x} y1="700" x2={x} y2="960" stroke="#0d0a20" strokeWidth="6" />
          ))}
          <defs>
            <radialGradient id="sun-glow" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stopColor="#FFF6E5" stopOpacity="0.9" />
              <stop offset="100%" stopColor="#FFF6E5" stopOpacity="0" />
            </radialGradient>
            <linearGradient id="water-fade" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#3d2a52" />
              <stop offset="15%" stopColor="#1c1436" />
              <stop offset="100%" stopColor="#0c0920" />
            </linearGradient>
          </defs>
        </svg>
      </div>
    </div>
  )
}
