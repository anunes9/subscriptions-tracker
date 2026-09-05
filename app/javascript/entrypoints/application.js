import { registerSW } from 'virtual:pwa-register'

// Registered on every page (this entrypoint is loaded from the shared
// layout), so the app shell is installable/offline-capable regardless of
// whether the page renders through Inertia.
//
// Production only: in development the service worker's scope would be
// stuck under /vite-dev/ (Vite Ruby's dev build output dir, see
// config/vite.json), and registering it there just adds a confusing caching
// layer on top of local development without ever covering the whole app.
//
// Note: Vite Ruby always runs the `build` command (never a `vite dev`
// server) to produce assets for every Rails environment, so `import.meta.
// env.PROD`/`DEV` — which reflect the *command*, not the mode — are always
// `true`/`false` here regardless of RAILS_ENV. `MODE` tracks the Rails
// environment correctly (vite_ruby passes it via `--mode`), so check that
// instead.
if (import.meta.env.MODE === 'production') {
  registerSW({ immediate: true })
}
