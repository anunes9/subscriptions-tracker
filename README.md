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
