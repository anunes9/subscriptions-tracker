# Renewly

Subscription tracker — Rails 7.2 + Inertia.js + React, per `docs/` (architecture,
data model, PRD, scaffolding plan) if present, or the companion planning docs
this repo was scaffolded from.

## Setup

### 1. Postgres role

The app connects as a **non-superuser** Postgres role in every environment
(including development/test), matching production and — critically — so that
[Row-Level Security](#row-level-security) is actually enforced locally.
Postgres superusers always bypass RLS regardless of policy, so connecting as
a superuser (e.g. the default `postgres`/`root` role) would silently make RLS
a no-op.

Create the role once per machine:

```bash
psql -d postgres -c "CREATE ROLE subscriptions_tracker WITH LOGIN CREATEDB PASSWORD 'subscriptions_tracker_dev';"
```

The password can be overridden via `LOCAL_DATABASE_PASSWORD` (see
`config/database.yml`) if you'd rather not use the default.

### 2. Install dependencies

```bash
bundle install
npm install
```

### 3. Create and load the databases

```bash
bin/rails db:create db:schema:load
RAILS_ENV=test bin/rails db:create db:schema:load
```

This creates four databases per environment set (`_development`/`_test` and
their `_queue` counterparts — Solid Queue's tables live in a separate database
role, see `config/database.yml`).

### 4. Run the app

```bash
bin/dev
```

Boots the Rails server, the Vite dev server, and the Solid Queue supervisor
(`bin/jobs`) together. Visit http://localhost:3000.

Sent emails aren't actually delivered in development — they open via
[letter_opener](https://github.com/ryanb/letter_opener) at `/letter_opener`
instead.

## Testing

```bash
bundle exec rspec
bundle exec rubocop
```

## Deploying to Railway

The app ships as the standard Rails-generated `Dockerfile` (multi-stage build;
`bin/rails assets:precompile` also runs the Vite production build — icons,
manifest, service worker included, via the `vite-plugin-pwa` setup) plus two
Railway config-as-code files for the two processes it needs:

- `railway.json` — the **web** service: builds from `Dockerfile`, no
  `startCommand` override (so the image's own `CMD ["./bin/rails", "server"]`
  runs unmodified through `bin/docker-entrypoint`, which runs `db:prepare`
  before boot), healthcheck at `/up`.
- `railway.worker.json` — the **Solid Queue worker**: same image, but
  `startCommand: "bin/jobs"` instead. This must be a *second* Railway service
  (Settings → Config-as-code File Path → `railway.worker.json`) pointed at
  the same repo — Railway doesn't run two processes from one service/one
  config file.

Setup, once both services exist and a Railway Postgres plugin is attached:

1. **Database**: the app connects as the non-superuser `subscriptions_tracker`
   role in every environment (see [Row-Level Security](#row-level-security)),
   which Railway's Postgres plugin doesn't create for you. Using the
   plugin's own admin credentials, run once:
   ```sql
   CREATE ROLE subscriptions_tracker WITH LOGIN CREATEDB PASSWORD '<a real password>';
   CREATE DATABASE subscriptions_tracker_production OWNER subscriptions_tracker;
   CREATE DATABASE subscriptions_tracker_production_queue OWNER subscriptions_tracker;
   ```
   (Same server, two logical databases — see `config/database.yml`.)
2. **Env vars**, set on *both* services:
   - `RAILS_MASTER_KEY` — from `config/master.key` (never commit this file).
   - `SUBSCRIPTIONS_TRACKER_DATABASE_PASSWORD` — the password chosen above.
   - `DATABASE_HOST` / `DATABASE_PORT` — the Postgres plugin's private
     networking host/port (not the `DATABASE_URL` it generates, since that
     points at its own default role/database).
   - Anything else `config/credentials.yml.enc` currently stubs out
     (`stripe`, `resend`, `google`) needs real values in the encrypted
     credentials file itself, rebuilt before deploying — Rails credentials
     aren't read from env vars.

Railway's config-as-code (`railway.json`) is in its sunset window — it still
works for a service already using it, but Railway's newer
[Infrastructure as Code](https://docs.railway.com/infrastructure-as-code)
(`.railway/railway.ts`, CLI-driven) is now the recommended path for *new*
services, with `railway config migrate` to convert later. This repo uses the
older JSON format because its schema is stable and I could verify it; the
IaC TypeScript API was still new enough that I didn't want to guess at its
exact syntax. Worth revisiting before the Dec 2026 cutover.

## Observability

Product analytics via [PostHog](https://posthog.com), initialized in
`app/javascript/entrypoints/inertia.tsx` via
`app/javascript/lib/observability.ts` (autocapture/pageviews). Reads its keys
from Vite env vars (`VITE_POSTHOG_KEY`, `VITE_POSTHOG_HOST`) and no-ops when
unset — copy `.env.example` to `.env` and fill them in to enable locally.

## Row-Level Security

The `subscriptions` table enforces Row-Level Security at the Postgres level
(`db/migrate/*_enable_rls_on_subscriptions.rb`) — a user can only see/write
rows where `user_id` matches the `app.current_user_id` session variable,
which `ApplicationController` sets for every authenticated request. This is
why:

- The schema is dumped as SQL (`db/structure.sql`), not Ruby (`db/schema.rb`)
  — Rails' Ruby schema dumper can't represent RLS policies, so `schema.rb`
  would silently omit them and `db:schema:load` would create the table
  without any protection.
- Any code that writes to `subscriptions` outside of a real HTTP request
  (console, a Rake task, a background job) must explicitly wrap the write in
  `SET LOCAL app.current_user_id = ...` inside a transaction, or it will be
  rejected. See `spec/support/model_helpers.rb`'s `create_subscription` for
  the pattern used in tests.
