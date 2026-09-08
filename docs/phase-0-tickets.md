# Scaffolding Plan: Subscription Tracker (Rails + Inertia + React)

**Companion to:** subscription-tracker-architecture.md, subscription-tracker-data-model.md, subscription-tracker-mvp-scope.md
**Version:** 1.0 — Draft
**Scope:** This covers **Phase 0 (Foundation)** from the MVP Scope doc — getting an empty-but-real project skeleton in place. It stops before any actual subscription/category/household feature logic (that's Phase 1+).

**A note on exactness:** Rails generator syntax and gem-specific installer commands (especially for `inertia_rails` and `solid_queue`, both actively evolving gems) can shift between versions. Commands below reflect the current standard usage as of this writing — treat them as a strong starting point, and check `bundle info <gem>` / the gem's README against whatever version actually resolves in `Gemfile.lock` before running blind.

---

## Ticket 0.1 — Initialize the Rails app

**Depends on:** nothing
**Goal:** an empty Rails app, API-friendliness aside (we want full Rails since Inertia needs view rendering, sessions, etc.)

```bash
rails new subscription_tracker \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --skip-jbuilder \
  --skip-test
cd subscription_tracker
bundle add rspec-rails --group "development,test"
bin/rails generate rspec:install
```

**Acceptance criteria:**
- [ ] `bin/rails server` boots and serves the default Rails page
- [ ] Postgres is the configured adapter in `config/database.yml`
- [ ] RSpec runs (`bundle exec rspec`) with zero examples, zero failures

---

## Ticket 0.2 — Add Inertia.js + React + TypeScript + Vite Ruby

**Depends on:** 0.1
**Goal:** Rails serving React pages through Inertia, per the architecture doc's core decision.

```bash
bundle add vite_rails inertia_rails
bin/rails vite:install
bin/rails generate inertia:install
# When prompted: choose React, choose TypeScript, allow it to install
# @inertiajs/react, vite-plugin-ruby, and a starter HomeController + Home page
```

Manually verify/adjust after the generator runs:
- `app/frontend/entrypoints/inertia.ts` — the Inertia client entrypoint
- `app/views/layouts/application.html.erb` — should include `vite_client_tag` / `vite_javascript_tag` and the Inertia root `<div id="app">`
- `app/controllers/application_controller.rb` — should include `include InertiaRails::Controller`

**Acceptance criteria:**
- [ ] Visiting `/` renders a React component (not raw ERB) via Inertia
- [ ] Editing the React page and reloading reflects changes (Vite dev server HMR working)
- [ ] `bin/dev` (or equivalent Procfile.dev) boots both Rails and Vite together

---

## Ticket 0.3 — Add Tailwind CSS

**Depends on:** 0.2

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

- Configure `tailwind.config.js` `content` paths to include `app/frontend/**/*.{ts,tsx}`
- Import Tailwind's base/components/utilities into the main CSS entrypoint Vite is already serving

**Acceptance criteria:**
- [ ] A Tailwind utility class (e.g. `bg-blue-500`) visibly applies on the Inertia home page

---

## Ticket 0.4 — Auth: Devise + Google OAuth

**Depends on:** 0.1
**Goal:** email/password + Google OAuth sign-in, per PRD Section 3.

```bash
bundle add devise omniauth-google-oauth2 omniauth-rails_csrf_protection
bin/rails generate devise:install
bin/rails generate devise User
```

After the generator, extend the migration it creates for `users` with the app-specific fields from the data model doc (2.1):

```ruby
# add to the generated devise migration, or a follow-up migration
add_column :users, :home_currency, :string, null: false, default: "EUR"
add_column :users, :default_reminder_lead_days, :integer, null: false, default: 3
add_column :users, :is_premium, :boolean, null: false, default: false
add_column :users, :premium_since, :datetime
add_column :users, :provider, :string   # for omniauth
add_column :users, :uid, :string        # for omniauth
```

Add Google OAuth to the Devise model:

```ruby
# app/models/user.rb
devise :database_authenticatable, :registerable, :recoverable,
       :rememberable, :validatable, :confirmable,
       :omniauthable, omniauth_providers: [:google_oauth2]
```

Add the callback route/controller (`Users::OmniauthCallbacksController`) per standard Devise+OmniAuth setup, and configure the Google OAuth strategy in `config/initializers/devise.rb` using credentials (`Rails.application.credentials.dig(:google, :client_id)`, etc. — set via `bin/rails credentials:edit`).

**Acceptance criteria:**
- [ ] Sign up / log in / log out / password reset / email confirmation all work via Devise's default views (to be replaced with Inertia/React views in a later ticket)
- [ ] "Sign in with Google" completes an OAuth round-trip and creates/logs in a `User`
- [ ] Google credentials are read from Rails encrypted credentials, not hardcoded

---

## Ticket 0.5 — Passwordless login (magic link with code)

**Depends on:** 0.4
**Goal:** the custom flow from PRD 3.0.1 / architecture doc 3.5 — not a Devise module, built alongside it.

```bash
bin/rails generate model PasswordlessLoginRequest \
  email:string \
  token_hash:string \
  code_hash:string \
  expires_at:datetime \
  used_at:datetime
bin/rails generate controller PasswordlessLoginRequests create show
```

Implementation notes for this ticket (not generator output — actual logic to write):
- Generate a random token (e.g. `SecureRandom.urlsafe_base64(32)`) and a random 6-digit code (`SecureRandom.random_number(10**6).to_s.rjust(6, '0')`); store only `Digest::SHA256.hexdigest(...)` of each, per the architecture doc's security note.
- `PasswordlessLoginRequestsController#create` — takes an email, creates the request row, enqueues an email (Ticket 0.7) with both the link and the code.
- A verification action — takes either the raw token (via link) or the raw code (via form submission), hashes it, looks up a matching unexpired/unused row, marks `used_at`, then finds-or-creates a `User` by email and calls `sign_in(user)`.
- Add `rack-attack` (`bundle add rack-attack`) and throttle `PasswordlessLoginRequestsController#create` by email/IP.

**Acceptance criteria:**
- [ ] Requesting a login email creates exactly one unused, unexpired `PasswordlessLoginRequest`
- [ ] Both the link and the code independently sign a user in
- [ ] A second use of the same link/code fails
- [ ] Requests older than the expiry window fail verification
- [ ] Repeated rapid requests for the same email are rate-limited (429, not silently processed)

---

## Ticket 0.6 — Core domain models & migrations

**Depends on:** 0.4
**Goal:** the rest of the schema from the data model doc, so every later feature ticket has tables to work against. No business logic yet — just structure.

```bash
bin/rails generate model Category \
  name:string icon:string color:string \
  user:references{optional} is_preset:boolean

bin/rails generate model ServiceDirectoryEntry \
  name:string icon_asset:string brand_color:string \
  cancellation_url:string region:string \
  default_category:references{to_table=categories}

bin/rails generate model Subscription \
  user:references \
  service_directory_entry:references{optional} \
  category:references \
  name:string currency:string billing_cycle:string \
  amount_type:string subscription_type:string status:string \
  billing_anchor_date:date trial_end_date:date \
  rating:integer tag:string \
  icon_override:string color_override:string notes:text \
  custom_reminder_lead_days:integer \
  household:references{optional} visibility:string

bin/rails generate model HistoryLogEntry \
  subscription:references \
  period:string amount:decimal currency:string \
  is_estimated:boolean confirmed_at:datetime

bin/rails generate model OneTimeExpense \
  user:references category:references \
  amount:decimal currency:string expense_date:date note:text \
  household:references{optional} visibility:string

bin/rails generate model Household \
  name:string owner:references{to_table=users}

bin/rails generate model HouseholdMember \
  household:references user:references role:string joined_at:datetime

bin/rails generate model ReminderLog \
  subscription:references channel:string trigger_reason:string sent_at:datetime

bin/rails generate model ExchangeRate \
  rate_date:date from_currency:string to_currency:string rate:decimal
```

After generating, add the constraints called out in the data model doc that generators won't add automatically:
```ruby
# migration follow-up
add_index :history_log_entries, [:subscription_id, :period], unique: true
add_index :household_members, :user_id, unique: true
add_index :passwordless_login_requests, :email
```

Set up the `enum`-style fields (`billing_cycle`, `amount_type`, `subscription_type`, `status`, `visibility`, `role`, `channel`, `trigger_reason`, `tag`) as Rails enums on each model rather than free-text strings, matching the data model doc's `enum(...)` columns.

**Acceptance criteria:**
- [ ] `bin/rails db:migrate` runs clean on a fresh database
- [ ] Every model file has the corresponding `enum` declarations matching the data model doc
- [ ] `bin/rails db:schema:dump` output matches the entities/fields in subscription-tracker-data-model.md (use this as a manual cross-check, not just "it migrated")

---

## Ticket 0.7 — Email (ActionMailer + Resend)

**Depends on:** 0.1

```bash
bundle add resend
```

- Configure `config/environments/production.rb` (and a real SMTP/API setup for `development`/`staging`) to deliver via Resend's SMTP or API
- Generate a base mailer: `bin/rails generate mailer PasswordlessLogin magic_link`
- Generate the reminder mailer stub (used later in Phase 2): `bin/rails generate mailer Reminder renewal_due trial_ending`

**Acceptance criteria:**
- [ ] A test email sends successfully in development (e.g. via `letter_opener` or Resend's sandbox mode)
- [ ] Mailer views exist as placeholders, ready for real content in later tickets

---

## Ticket 0.8 — Solid Queue setup

**Depends on:** 0.6
**Goal:** background job infrastructure in place, per the architecture doc's decision to avoid Redis.

```bash
bundle add solid_queue
bin/rails generate solid_queue:install
bin/rails db:migrate
```

Create empty job stubs (logic comes in Phase 2, per the MVP scope doc):
```bash
bin/rails generate job FxRateRefresh
bin/rails generate job PeriodRollover
bin/rails generate job ReminderDispatch
bin/rails generate job PriceChangeCheck
bin/rails generate job PasswordlessCleanup
```

Add a skeleton `config/recurring.yml` wiring each job to a schedule (daily, per the architecture doc's job table) — even with empty job bodies, this proves the scheduling mechanism works end-to-end.

**Acceptance criteria:**
- [ ] Solid Queue's own tables migrate cleanly
- [ ] `bin/jobs` (or the Solid Queue supervisor process) starts without error
- [ ] A manually-enqueued test job executes and logs output
- [ ] `config/recurring.yml` lists all five jobs with schedules, even though bodies are empty

---

## Ticket 0.9 — Row-Level Security spike

**Depends on:** 0.6
**Goal:** de-risk the hardest architectural unknown *early*, per the architecture doc's explicit warning not to leave this until Household Sharing (Phase 4).

```bash
bin/rails generate migration EnableRlsOnSubscriptions
```

```ruby
# in the migration, using raw SQL since ActiveRecord has no RLS DSL
class EnableRlsOnSubscriptions < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;"
    execute <<~SQL
      CREATE POLICY subscriptions_owner_access ON subscriptions
      USING (user_id = current_setting('app.current_user_id')::uuid);
    SQL
  end

  def down
    execute "DROP POLICY IF EXISTS subscriptions_owner_access ON subscriptions;"
    execute "ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;"
  end
end
```

Add an `around_action` in `ApplicationController` that sets `app.current_user_id` via `SET LOCAL` at the start of each authenticated request, scoped to the current transaction/connection.

**Acceptance criteria:**
- [ ] With RLS enabled, a raw SQL query for another user's subscription (without the session variable set) returns zero rows
- [ ] The same query with the session variable set to the correct user returns the expected rows
- [ ] A request spec proves this — not just a manual `rails console` check — since this is the pattern Household Sharing will depend on later

---

## Ticket 0.10 — Stripe skeleton

**Depends on:** 0.6
**Goal:** just the plumbing shape — actual billing logic is Phase 3 per the MVP scope doc, but the routes/webhook endpoint should exist now so later work has a home.

```bash
bundle add stripe
bin/rails generate controller Billing checkout webhook
```

- Add `config/initializers/stripe.rb` reading the API key from credentials
- Add a webhook route with signature verification stubbed in (`Stripe::Webhook.construct_event`), even if the handler body just logs the event type for now

**Acceptance criteria:**
- [ ] `POST /billing/webhook` with a validly-signed test event from the Stripe CLI returns 200
- [ ] An invalidly-signed request is rejected (400), proving signature verification is actually wired up, not just present

---

## Ticket 0.11 — CI pipeline

**Depends on:** 0.1

- `.github/workflows/ci.yml` running on every PR:
  - `bundle exec rspec`
  - `bundle exec rubocop`
  - `bin/rails db:migrate:status` check (catches missing/out-of-order migrations)
  - `npm run typecheck` (or `tsc --noEmit`) for the frontend
- `bundle add rubocop rubocop-rails --group development,test` and generate a baseline `.rubocop.yml`

**Acceptance criteria:**
- [ ] Opening a PR triggers the workflow
- [ ] A deliberately broken test/lint rule fails the check
- [ ] A clean PR passes

---

## Ticket 0.12 — Seed data: preset categories + starter service directory

**Depends on:** 0.6
**Goal:** the app is unusable without this — categories and known services are referenced everywhere in the UI.

- `db/seeds.rb` populates:
  - The ~9 preset `Category` rows from PRD 4.4 (`user_id: nil`, `is_preset: true`)
  - The finalized `ServiceDirectoryEntry` list from the naming pass (Netflix, Spotify, Vodafone, Holmes Place, Fidelidade, Glovo, etc. — the full list from PRD 4.4.1), each linked to its `default_category`

**Acceptance criteria:**
- [ ] `bin/rails db:seed` populates categories and the service directory idempotently (safe to re-run without duplicating rows — use `find_or_create_by`)
- [ ] Every category from PRD 4.4 exists; every service from the finalized 4.4.1 list exists with the correct category link

---

## Ticket 0.13 — PWA setup

**Depends on:** 0.3

```bash
npm install -D vite-plugin-pwa
```

- Configure `vite-plugin-pwa` in `vite.config.ts` per the architecture doc's caching-strategy note (static assets cache-first, Inertia data requests network-first)
- Add `public/manifest.json` (app name, theme color, icons) and link it from the Inertia root layout
- Add placeholder app icons (real icon design is a separate design task, not this ticket)

**Acceptance criteria:**
- [ ] Lighthouse's PWA audit passes the installability checks
- [ ] The app can be "Added to Home Screen" on a mobile browser
- [ ] Reloading while offline still renders the app shell (even if data doesn't load)

---

## Ticket 0.14 — Observability

**Depends on:** 0.1

```bash
bundle add sentry-ruby sentry-rails
npm install @sentry/react
```

- Configure Sentry DSN via credentials, initialize in both Rails (`config/initializers/sentry.rb`) and the React entrypoint
- Add PostHog (or chosen analytics tool) client-side snippet, gated behind an environment variable so local dev doesn't pollute production analytics

**Acceptance criteria:**
- [ ] A deliberately raised exception in a test route appears in Sentry
- [ ] A basic pageview event appears in the analytics tool

---

## Ticket 0.15 — Railway deployment config

**Depends on:** all of the above
**Goal:** the app actually deploys, end to end, even with no real features yet.

- `railway.json` or Railway's dashboard-configured build/start commands
- Release-phase command: `bin/rails db:prepare` (migrates + seeds safely)
- Environment variables configured in Railway: `DATABASE_URL` (auto-provided by the Postgres addon), `RAILS_MASTER_KEY`, Stripe keys, Resend key, Google OAuth credentials, Sentry DSN

**Acceptance criteria:**
- [ ] Pushing to `main` triggers a Railway deploy
- [ ] The deployed app is reachable over HTTPS and shows the Inertia home page
- [ ] Signing up via passwordless login works against the deployed environment, end to end (proves email delivery, DB, and session handling all work together in production, not just locally)

---

## Suggested Execution Order

Tickets 0.1 → 0.2 → 0.3 can only go in that order (each depends on the last). From there, 0.4 unblocks 0.5, 0.6, and 0.10; 0.6 unblocks 0.8, 0.9, and 0.12. Tickets 0.7, 0.11, 0.13, and 0.14 are largely independent and can be picked up in parallel or interleaved wherever convenient. Ticket 0.15 should be last, once there's something real to deploy.
