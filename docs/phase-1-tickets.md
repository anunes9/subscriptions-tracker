# Phase 1 Tickets: Core Subscription Loop

**Companion to:** `architecture.md`, `data-model.md`, `mvp-scope.md`, `prd.md`
**Scope:** **Phase 1 (Core Subscription Loop)** from the MVP scope doc — no pre-written scaffolding plan existed for this phase (unlike Phase 0's `phase-0-tickets.md`), so this doc was drafted from the MVP scope doc + PRD during implementation and is a **record of what was built**, not a forward-looking plan. Each ticket below was implemented, tested, and committed separately.

**Exit criteria (met):** a user can sign up, complete onboarding, add subscriptions (manually or via the directory), and see an accurate month view and monthly total.

**Standing decision carried over from Phase 0:** the app is EUR-only for now (no multi-currency, no `exchange_rates` table/FX job). PRD 4.6 (Currency Support, EUR/USD) and the multi-currency conversion parts of PRD 4.3 are out of scope until that decision is revisited.

---

## Ticket 1.1 — Category management

**PRD:** 4.4 (Categories)

CRUD for custom categories, scoped to the current user alongside the global presets. Deleting a custom category reassigns its subscriptions and one-time expenses to the "Other" preset rather than leaving them dangling. Introduced `AuthenticatedController` as the base class for authenticated app pages and a minimal shared `AppLayout` shell.

**Key files:** `app/controllers/categories_controller.rb`, `app/models/category.rb`, `app/javascript/pages/settings/categories.tsx`

---

## Ticket 1.2 — Known-Service Directory rebuild

**PRD:** 4.4.1 (Known-Service Directory)

The preset categories and directory entries seeded in Phase 0 (ticket 0.12) were invented before the PRD text was available in that session and didn't match it. This ticket replaced the 9 ad-hoc categories with the 10 in PRD 4.4, and expanded the directory from 24 generic entries to the 53 in 4.4.1's finalized list (global brands + Portugal-specific providers/gyms/insurers), each carrying a region. Cancellation URLs are left blank except where already verified, rather than guessed.

Seeding also retires categories/entries from the old list, reassigning any dependents to Other first — including a Row-Level-Security-aware per-subscription reassignment, since seeding runs outside a request and a stale preset can span many users' subscriptions.

Added `ServiceDirectoryEntry.search` (name autocomplete, `ILIKE`-based) and a `GET /service_directory_entries` JSON endpoint for the add-subscription flow (ticket 1.3) to consume.

**Key files:** `db/seeds.rb`, `app/controllers/service_directory_entries_controller.rb`, `app/models/service_directory_entry.rb`

---

## Ticket 1.3 — Add/Edit/Delete/Duplicate Subscription

**PRD:** 4.1 (Add/Manage a Subscription), 4.1.3 (Worth-It Rating & Tags)

Full add/edit/delete/duplicate flow for subscriptions: quick-add form with known-service-directory name autocomplete (prefills category and links the directory entry), status management (active/paused/cancelled), the optional worth-it rating/tag fields, and a detail view surfacing the directory's "how to cancel" link.

Amount isn't a `Subscription` column (data model 2.4/2.5 — it's always the latest `HistoryLogEntry`), so add/edit write the current period's log entry directly. `Subscription#current_period` is the minimal period-key logic this needed; the full Fixed/Variable carry-forward/estimate engine is ticket 1.4.

**Key files:** `app/controllers/subscriptions_controller.rb`, `app/javascript/components/subscription_form.tsx`, `app/javascript/pages/subscriptions/*`

---

## Ticket 1.4 — Amount History Log engine

**PRD:** 4.1.1 (Amount History Log)

`Subscription#ensure_current_period_logged!` is the Fixed/Variable core: if the current period isn't logged yet, carry the last known amount forward — a confirmed actual for Fixed (the fixed price *is* this period's charge, no confirmation step), an unconfirmed estimate for Variable. A recurring job will eventually call this proactively as each period rolls over (Phase 2's `PeriodRolloverJob`); for now `SubscriptionsController` calls it reactively whenever a subscription is read, which is enough to produce correct estimates today.

Switching `amount_type` locks in the current period under the old type's confirmation semantics first, so history is never lost or silently reinterpreted ("past periods already in the log stay as-is"). The index/show pages surface unconfirmed estimates with a "~" prefix and a label.

**Key files:** `app/models/subscription.rb` (`ensure_current_period_logged!`, `latest_history_entry`, `confirm_amount!`)

---

## Ticket 1.5 — Monthly-equivalent normalization

**PRD:** 4.3 (Monthly Cost Summary)

`Subscription#monthly_equivalent` (amount/12 for yearly, as-is for monthly) — the last piece of billing-cycle correctness the cost summary needs; the period-key logic itself was already built in tickets 1.3/1.4. Surfaced in the subscriptions list as a "≈€X/mo" hint on yearly entries, ahead of the Dashboard/Monthly Cost Summary ticket that relies on it for the combined total.

**Key files:** `app/models/subscription.rb` (`monthly_equivalent`)

---

## Ticket 1.6 — Onboarding flow

**PRD:** 3.1 (Onboarding Flow)

Added `users.onboarded_at` and an `AuthenticatedController`-wide guard that sends any not-yet-onboarded user to a service checklist before anything else — covers every sign-up path (password, Google OAuth, passwordless) the same way since it's centralized rather than duplicated per controller.

The checklist groups the service directory by category; tapping an entry reveals an inline amount/billing-date/cycle form, and "Finish setup" creates one subscription (+ confirmed first-period log entry) per completed entry, silently skipping incomplete ones. "Skip for now" goes straight to the quick-add flow, per the PRD.

**Key files:** `app/controllers/authenticated_controller.rb`, `app/controllers/onboarding_controller.rb`, `app/javascript/pages/onboarding/show.tsx`, `db/migrate/20260908100000_add_onboarded_at_to_users.rb`

---

## Ticket 1.7 — Month View

**PRD:** 4.2 (Month View)

List-style, mobile-first month view: all active subscriptions renewing in the selected month, grouped by day, with prev/next navigation. Monthly subscriptions renew every month on the anchor date's day-of-month, clamped to the last day of shorter months (a subscription anchored on the 31st still shows in February); yearly subscriptions only appear in the one month they actually renew, marked with a YEARLY badge.

Deliberately read-only — browsing past/future months shows the latest logged amount but never writes new history log rows, unlike the subscriptions pages which do that deliberately for the periods a user is actually managing.

**Key files:** `app/controllers/month_view_controller.rb`, `app/javascript/pages/month_view/show.tsx`

---

## Ticket 1.8 — Dashboard + Monthly Cost Summary

**PRD:** 4.3 (Monthly Cost Summary), 4.8 (Dashboard/Home), 4.11 Basic (Analytics & Insights)

The landing screen and cost summary, now the app's root route: headline monthly total toggling between "normalized" (every active subscription's monthly-equivalent, yearly/12 included) and "this month's actual" (only what really renews this month, at its real amount); upcoming renewals in the next 14 days (`Subscription#next_renewal_date` — finds the next occurrence from a given date, monthly or yearly, clamped to shorter months); category breakdown and monthly-vs-yearly split by count and cost (the same two views 4.3/4.8 already call for).

Also retired the Rails/Vite/Inertia demo scaffold (`InertiaExample` controller/page/assets) that used to own the root route — dead once a real page existed there.

**Key files:** `app/controllers/dashboard_controller.rb`, `app/javascript/pages/dashboard/show.tsx`, `app/models/subscription.rb` (`next_renewal_date`)

---

## Not yet built (deferred to later phases per the MVP scope doc)

- Solid Queue recurring jobs (`PeriodRolloverJob`, `FxRateRefreshJob` — n/a while EUR-only), renewal/trial reminders, free trial tracking, price-change detection, calendar export → **Phase 2**
- Real Stripe Checkout/webhook logic, `is_premium` gating, freemium limits → **Phase 3**
- Household sharing → **Phase 4**
- Advanced analytics (Premium) → **Phase 5**
