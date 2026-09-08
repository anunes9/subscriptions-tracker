# Architecture & Technology: Subscription Tracker

**Companion to:** subscription-tracker-prd.md, subscription-tracker-data-model.md
**Diagram:** subscription-tracker-architecture.mermaid
**Version:** 2.0 — Draft (Rails + Inertia.js monolith)

---

## 1. Recommended Stack

Confirmed direction: **Ruby on Rails serving a React frontend via Inertia.js**, as a single monolith. This is the lowest-ops path available given the stack preferences discussed — one language for backend logic, one deploy target, no separate API contract to maintain for your own frontend.

| Layer | Choice | Why |
|---|---|---|
| Backend framework | **Ruby on Rails** | Mature, batteries-included — ActiveRecord, ActionMailer, migrations, Devise all fit this app well |
| Frontend rendering | **Inertia.js + React + TypeScript** | Rails controllers return React page components with props directly — no separate JSON API needed for the app's own frontend, but you still write UI in React/TSX |
| Styling | **Tailwind CSS** | Works the same regardless of backend; fast to build with |
| Auth | **Devise** (+ `omniauth-google-oauth2` for Google sign-in) | Handles email/password, email verification, password reset, OAuth — covers PRD Section 3 |
| Database | **Postgres**, hosted as a Railway-managed addon | Relational, matches the data model doc directly; supports Row-Level Security for household visibility |
| ORM | **ActiveRecord** | Rails' native ORM; migrations map directly to the entities in subscription-tracker-data-model.md |
| Background jobs | **Solid Queue** (Rails 7.1+) | DB-backed job queue — no Redis to provision/operate, which matters for low-ops. Handles both one-off jobs and recurring/scheduled jobs (`config/recurring.yml`) |
| Email | **ActionMailer**, optionally via **Resend** as the SMTP/API provider | Transactional email for renewal/trial reminders |
| Payments | **Stripe** (via the `stripe` Ruby gem) | Same role as before — Premium billing, webhooks update `is_premium` |
| Hosting | **Railway** — single service for the Rails app + Postgres addon | One platform, one deploy, no cross-origin/CORS concerns since frontend and backend are the same app |
| Icon/logo assets | Bundled via the Rails asset pipeline (**Vite Ruby**), not fetched at runtime | Same requirement as before — instant recognition, no loading delay; Vite Ruby is also what enables the PWA tooling (`vite-plugin-pwa`) — see 3.7 |

### 1.1 What you gain vs. the Next.js/Supabase/Vercel path
- **One deploy, one host.** No coordinating a frontend deploy (Vercel) with a separate backend deploy (Railway/Supabase) — a single `git push` ships both.
- **No CORS or cross-service auth token handling** — Inertia requests are same-origin, session-based auth via Devise works out of the box.
- **No Redis to operate** — Solid Queue stores jobs in Postgres, so the whole app's persistence is one database.
- **Rails' maturity** — Devise, ActionMailer, ActiveRecord migrations, and the Rails ecosystem are all well-trodden for exactly this kind of CRUD-heavy, account-based app.

### 1.2 What you give up
- **End-to-end TypeScript type safety** between backend and frontend (what tRPC would have given you) — Inertia passes props from Ruby to React, but there's no automatic type generation. Mitigation: define a shared TypeScript types file for page props and keep it manually in sync, or adopt a gem like `inertia_rails-contrib` typegen tooling if it fits your workflow.
- **Next.js-specific features** (edge functions, built-in ISR) — not particularly relevant for this app's needs, so low cost.
- **A formal JSON API** — if you later want a native mobile app or third-party integrations (PRD Future Considerations), you'd add API-only controllers alongside the Inertia ones at that point; not needed for v1.

---

## 2. High-Level Architecture

See `subscription-tracker-architecture.mermaid` for the full diagram. Summary of the flow:

1. **Client** — React page components rendered through Inertia.js. The browser gets a full page render on first load, then subsequent navigation is handled client-side via Inertia's XHR-based routing — similar UX to an SPA, without hand-building an API layer.
2. **Rails app** — controllers handle requests, run business logic (subscription CRUD, history log writes, household visibility checks, freemium limit enforcement), and return `inertia: 'PageName', props: {...}` responses instead of JSON API responses or server-rendered ERB views.
3. **Database** — Postgres on Railway, with **Row-Level Security policies** enforcing that a user can only read/write their own rows, and household members can read each other's rows only where `household_id` matches and `visibility = 'shared'` — same defense-in-depth principle as before, just implemented via raw SQL migrations in Rails rather than Supabase's built-in RLS tooling (see Section 4).
4. **Solid Queue** handles everything that needs to happen without a user request, using `config/recurring.yml` for the scheduled ones:
   - Daily FX rate refresh (EUR↔USD snapshot, stored in an `exchange_rates` table)
   - Billing-period rollover — for each active subscription whose period has turned over, create the next `HistoryLogEntry` (carry-forward estimate for Variable, auto-copy for Fixed — PRD 4.1.1)
   - Renewal & trial-end reminder dispatch (email via ActionMailer/Resend + in-app notification row) — PRD 4.7, 4.1.2
   - Price-change detection — compare newest vs. previous confirmed `HistoryLogEntry.amount`, write an alert if changed (Premium, PRD 4.9)
5. **External services** — Stripe handles Premium billing (webhooks flow into a Rails controller to update `User.is_premium`), ActionMailer/Resend sends transactional email, the exchange rate API is called once daily by the Solid Queue job.

---

## 3. Component Responsibilities

### 3.1 Frontend (React via Inertia)
- Page components organized to mirror the app's screens: onboarding checklist, quick-add flow, month view, dashboard, household view, analytics.
- Receives data as **props from the Rails controller**, not via a separate data-fetching layer — a controller action like `SubscriptionsController#index` renders `inertia: 'Subscriptions/Index', props: { subscriptions: ... }`.
- Client-side interactivity (forms, toggles, charts) is plain React; form submissions go through Inertia's `useForm` helper, which posts back to a Rails controller action.
- PWA manifest + service worker for installability; calendar ICS export (PRD 4.12) is a Rails controller action returning a `.ics` file/feed, not a frontend concern.

### 3.2 Rails Controllers (replacing the tRPC routers from the prior draft)
Organized by domain, mirroring the data model entities — same responsibilities as previously planned, just as Rails controllers instead of tRPC routers:
- `SubscriptionsController` — CRUD, status changes, visibility toggle
- `HistoryLogEntriesController` — confirm/edit a period's actual amount
- `CategoriesController` — CRUD for custom categories
- `OneTimeExpensesController` — CRUD (Premium-gated)
- `HouseholdsController` / `HouseholdMembersController` — create/invite/leave, visibility-filtered household dashboard queries
- `AnalyticsController` — trend/insight queries (PRD 4.11), Basic vs. Advanced gated by `current_user.premium?`
- `BillingController` — Stripe checkout session creation, webhook handler

### 3.3 Database (Postgres on Railway)
- Schema mirrors `subscription-tracker-data-model.md` directly via ActiveRecord migrations.
- **Row-Level Security** is still the key decision for household privacy — implemented via raw SQL in a Rails migration (`execute "CREATE POLICY ..."`), since ActiveRecord doesn't have native RLS support. The Rails connection needs to `SET LOCAL app.current_user_id` (or similar) at the start of each request (e.g. via a `around_action` in `ApplicationController`) so Postgres policies can reference it — this is a bit more manual than Supabase's built-in auth-integrated RLS, worth budgeting real implementation time for.
- `exchange_rates` table (date, from_currency, to_currency, rate) stores daily snapshots, same reasoning as before — keeps historical totals accurate.

### 3.4 Background Jobs (Solid Queue)
Defined as Rails jobs (`ApplicationJob` subclasses), with recurring ones scheduled in `config/recurring.yml`:

| Job | Schedule | Responsibility |
|---|---|---|
| `FxRateRefreshJob` | Daily | Fetch EUR↔USD rate, insert into `exchange_rates` |
| `PeriodRolloverJob` | Daily | For subscriptions whose billing period has turned over, create the next `HistoryLogEntry` |
| `ReminderDispatchJob` | Daily (or more frequent near renewal windows) | Find upcoming renewals/trial-ends within the lead-time window, send email + write in-app notification, log to `reminder_logs` |
| `PriceChangeCheckJob` | Daily, after rollover | Compare consecutive `HistoryLogEntry` amounts, flag changes for Premium users |

### 3.5 Auth (Devise)
- Handles the full account lifecycle from PRD Section 3: sign up, log in, log out, password reset, email verification, Google OAuth via `omniauth-google-oauth2`.
- Session-based auth (Rails default) works natively with Inertia — no token management needed since frontend and backend are same-origin.
- **Passwordless (magic link with code) — custom, not native to Devise.** Devise doesn't ship this pattern out of the box, so it's implemented as a small standalone flow alongside Devise rather than forcing it through a Devise module:
  - A `PasswordlessLoginRequestsController` creates a `PasswordlessLoginRequest` row (token hash + 6-digit code hash + expiry), emails both via ActionMailer, and on verification (link click or code entry) finds-or-creates the `User` by email and starts a Warden/Devise session directly (`sign_in(user)`), so the rest of the app doesn't need to know or care which method the user signed in with.
  - Store only hashes of the token/code (e.g. `Digest::SHA256`), never the raw values, so a database read alone can't be used to sign in as someone else.
  - Rate-limit requests per email (e.g. via `rack-attack`) to prevent abuse.
  - A daily cleanup job (alongside the other Solid Queue jobs) purges expired/used `PasswordlessLoginRequest` rows.

### 3.6 Payments (Stripe)
- Stripe Checkout for upgrading to Premium; Stripe Customer Portal for self-service plan management/cancellation.
- Webhook endpoint (a standard Rails controller action) updates `User.is_premium` and `premium_since` on subscription lifecycle events — use the `stripe-ruby` gem's webhook signature verification to ensure authenticity.

### 3.7 PWA Implementation

PWA support is a client-side concern (manifest + service worker + HTTPS) and is fully independent of the Rails/Inertia backend choice — it doesn't block or complicate the monolith approach.

| Requirement | Implementation |
|---|---|
| `manifest.json` | Static file (app name, icons, theme color, `display: standalone`), served via the Vite Ruby asset pipeline, linked with a `<link rel="manifest">` tag in the Inertia root layout (`app/views/layouts/application.html.erb`) |
| Service worker | Generated via **`vite-plugin-pwa`** (Workbox-based) — natural fit since Vite Ruby is already the recommended asset pipeline for React/TS, so PWA tooling comes largely for free |
| App icons | Bundled the same way as the service logos (PRD 4.4.1) — add the app's own icon set (multiple sizes + `apple-touch-icon`) alongside |
| HTTPS | Provided by default on any Railway-deployed domain — no extra setup |

**Caching strategy nuance:** Inertia does client-side page transitions via XHR/fetch rather than full page reloads, so the service worker needs different caching rules per request type:
- **Static assets** (JS bundle, CSS, icons, manifest) → cache-first, since they only change on deploy.
- **Inertia data requests** (page props — the actual subscription/dashboard data) → network-first or network-only, so users never see a stale monthly total served from cache. Configure this explicitly via `vite-plugin-pwa`'s custom route matchers rather than relying on default caching behavior.

**iOS caveat (platform limitation, not Rails-specific):** Safari supports "Add to Home Screen" and offline caching reasonably well, but web push notifications on iOS only work once the PWA has actually been added to the home screen. Worth keeping in mind if reminders (PRD 4.7) ever move from email/in-app toward push notifications (noted as a Future Consideration in the PRD).

---

## 4. Key Architectural Decisions (resolving prior open questions)

- **Exchange rate storage:** confirmed — store daily snapshots in an `exchange_rates` table rather than always using the latest rate, so past-month totals remain historically accurate. (Unchanged from the prior draft.)
- **Household visibility enforcement:** two layers — Rails controller/query scoping (primary UX path, e.g. `Subscription.where(household_id: household.id, visibility: :shared)`) *and* Postgres RLS policies (safety net, defense in depth) — same principle as before, but RLS setup requires more manual wiring in Rails than it would have in Supabase (see 3.3).
- **Icon/logo delivery:** bundled as static assets via the Rails asset pipeline (Vite Ruby recommended over Sprockets for React/TS support) at build time, not fetched from a runtime CDN.
- **Type safety across the Rails/React boundary:** since Inertia doesn't generate types automatically, maintain a shared `types/inertia-props.ts` file with interfaces matching each controller's `props:` payload. Not as airtight as tRPC, but disciplined naming/co-location keeps drift manageable for a small team.

---

## 5. Environments & Deployment

- **Environments:** local dev → Railway PR/preview environments (if using Railway's environment-per-branch feature) → Production.
- **CI/CD:** GitHub Actions runs RSpec tests, Rubocop linting, and `rails db:migrate:status` checks on every PR; merging to `main` triggers a Railway deploy.
- **Secrets:** Stripe keys, Resend/SMTP credentials, exchange rate API key, `RAILS_MASTER_KEY` — stored as Railway environment variables / Rails encrypted credentials, never committed.
- **Database migrations:** standard Rails migrations, run automatically as part of the Railway deploy (release phase command: `rails db:migrate`).

---

## 6. Observability

- **Error tracking:** Sentry for Rails (via `sentry-ruby` + `sentry-rails`), which also captures frontend React errors if paired with `sentry-javascript`.
- **Analytics:** PostHog (self-hostable or cloud) for product usage metrics — supports the Success Metrics in the PRD (Section 8): time-to-first-subscription, onboarding completion, reminder click-through, free-to-premium conversion.
- **Job monitoring:** Solid Queue ships with a web dashboard (`mission_control-jobs` gem) for inspecting job runs/failures — worth mounting in the Rails app for visibility into the recurring jobs, especially `ReminderDispatchJob` and `PeriodRolloverJob`, which are the two most likely to cause silent user-facing problems if they fail.

---

## 7. Open Questions / Risks

- **RLS implementation effort in Rails:** budget real time for this — it's the one piece that would have been closer to "free" on Supabase and now needs to be hand-built (policies + `SET LOCAL` session context per request). Worth a spike/prototype early rather than assuming it late.
- **Solid Queue at scale:** it's DB-backed, which is simpler ops but can add load to the primary Postgres instance as job volume grows — fine at this app's expected scale, but worth knowing Sidekiq+Redis is the standard escape hatch if Solid Queue ever becomes a bottleneck.
- **Inertia + TypeScript prop drift:** without generated types, prop shape mismatches between a controller and its page component are a runtime, not compile-time, error. Consider a lightweight prop-shape test (e.g. an RSpec request spec asserting the props payload matches expected keys) for the most critical pages.
- **Stripe webhook reliability:** ensure idempotent webhook handling (Stripe can retry/redeliver events) so `is_premium` state doesn't get corrupted by out-of-order delivery — unchanged concern from the prior draft.
