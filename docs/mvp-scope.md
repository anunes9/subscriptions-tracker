# MVP Scope & Build Order: Subscription Tracker

**Companion to:** subscription-tracker-prd.md, subscription-tracker-data-model.md, subscription-tracker-architecture.md
**Version:** 1.0 — Draft

---

## 1. Scope Confirmation

**Decision: the MVP targets the full v1 scope already defined in the PRD** — including Household Sharing (4.13) and the Freemium/Stripe model (4.9) — nothing gets cut. This document is not a scope-reduction exercise; it's a **build order**: what to build first, what depends on what, and which already-lower-priority items (P1/P2 in the PRD) are safe to slip a little if the team runs into real time pressure, without breaking the core promise of the app.

---

## 2. A Dependency Conflict Worth Resolving Now

The PRD labels these two features independently:
- **Household Sharing (4.13)** — Priority **P0**, in v1 launch scope, **Premium-gated**.
- **Freemium Model (4.9)** — Priority **P1**, with the note *"monetization plumbing can follow core feature build."*

Taken literally, these conflict: if Household Sharing is a P0 launch feature and it's gated behind Premium, then **Stripe billing and `is_premium` gating can't actually be deferred** — they're a hard prerequisite for shipping Household Sharing at all. There's no way to launch a premium-only feature without the premium infrastructure existing first.

**Resolution:** treat the *minimum* monetization plumbing (Stripe Checkout, webhook handling, `User.is_premium` flag) as a **P0 dependency of Household Sharing**, even though the fuller freemium experience (pricing page polish, upgrade prompts throughout the app, free-tier limit enforcement UI) can still trail slightly behind, per the original P1 framing. In short: **the gate must exist before launch; the marketing/UX around the gate can be refined shortly after.**

---

## 3. Build Phases

Ordered by dependency, not by the PRD's section numbers. Each phase assumes the Rails + Inertia + React stack from the architecture doc.

### Phase 0 — Foundation
*Nothing else can be built until this exists.*
- Rails + Inertia + React project scaffold (Vite Ruby, Tailwind)
- Devise auth (email/password + Google OAuth, email verification, password reset) — PRD Section 3
- Passwordless login (magic link with code) — custom controller + `PasswordlessLoginRequest` model, rack-attack rate limiting (PRD 3.0.1)
- Base Postgres schema via ActiveRecord migrations, matching the full data model doc (all entities, even ones not yet used — cheaper to create the tables once than migrate repeatedly)
- Row-Level Security spike — prove out the `SET LOCAL` + policy approach early (flagged as a real risk in the architecture doc); don't wait until Household Sharing to discover this is harder than expected

### Phase 1 — Core Subscription Loop
*The minimum that makes the app useful at all.*
- Onboarding Flow (3.1) — checklist against the known-service directory
- Known-Service Directory (4.4.1) — the finalized bundled icon/color/category list from our naming pass
- Add/Manage Subscription (4.1), including Amount Type (Fixed/Variable) and the universal History Log (4.1.1)
- Categories (4.4) — presets + custom
- Billing Cycle Support (4.5) — Monthly/Yearly
- Currency Support (4.6) — EUR/USD, with the `exchange_rates` snapshot table
- Month View (4.2) and Monthly Cost Summary (4.3)
- Dashboard (4.8) with Basic Analytics (4.11 Basic — category breakdown, monthly vs. yearly split)

**Exit criteria:** a user can sign up, complete onboarding, add subscriptions (manually or via the directory), and see an accurate month view and monthly total. This is the smallest slice that delivers the core promise.

### Phase 2 — Time-Based Intelligence
*Everything that depends on Solid Queue and the passage of time.*
- Solid Queue setup (`config/recurring.yml`)
- `FxRateRefreshJob`, `PeriodRolloverJob` (creates next `HistoryLogEntry` per subscription, carry-forward estimates for Variable)
- Free Trial Tracking (4.1.2) — needs rollover logic to handle trial-end prompts
- Renewal & trial reminders (4.7) — `ReminderDispatchJob`, email via ActionMailer/Resend + in-app notification
- `PriceChangeCheckJob` (feeds Premium insights in Phase 4, but the detection logic itself has no Premium dependency, so it's cheap to build here)
- Worth-It Rating & Tags (4.1.3)
- Calendar Export / ICS (4.12)

**Exit criteria:** subscriptions behave correctly over time without manual intervention — estimates roll forward, reminders fire, trials prompt a decision.

### Phase 3 — Monetization Infrastructure
*The P0 dependency surfaced in Section 2 above.*
- Stripe integration — Checkout, Customer Portal, webhook handler
- `User.is_premium` / `premium_since` wiring
- Free-tier limit enforcement (the ~7 subscription cap)
- Minimum viable pricing/upgrade UI — doesn't need to be polished yet, just functional

**Exit criteria:** the app can distinguish free vs. Premium users and gate features accordingly. This unblocks Phase 4.

### Phase 4 — Household Sharing (Premium)
*Now unblocked by Phase 3.*
- Household / HouseholdMember models, invite flow, roles
- `household_id` + `visibility` fields on Subscription and OneTimeExpense
- RLS policies enforcing Shared/Private visibility (building on the Phase 0 spike)
- Household Dashboard (4.13)

**Exit criteria:** a Premium user can create a household, invite members, and see a correctly-filtered shared dashboard — with private items provably never leaking across members (this needs dedicated test coverage, not just a visual check).

### Phase 5 — Advanced Analytics (Premium)
- Spending trends, forecasts, "biggest movers," duplicate/overlap detection, annualized cost view (4.11 Advanced)
- Surfacing the price-change detection from Phase 2 as a user-facing alert

**Exit criteria:** Premium users get the full insight set from 4.11.

### Post-Launch Fast-Follow (already scoped as P2 in the PRD, not blocking v1 launch)
- **One-Time Expense Tracking (4.10)** — explicitly scoped in the PRD as "not part of initial release"
- **All Spending combined view** — depends on the above

These two were already deferred in the PRD itself; nothing changes here even under the "full v1" decision, since the PRD never placed them in v1 to begin with.

---

## 4. Launch Checklist (all P0 items, condensed)

Use this as the actual "can we ship" gate — every line must be true before launch:

- [ ] Sign up / log in / log out / password reset / email verification / Google OAuth work
- [ ] Passwordless login (magic link + code) works, is rate-limited, and expired/used requests are cleaned up
- [ ] Onboarding checklist works and is skippable
- [ ] A user can add a subscription manually and via the known-service directory
- [ ] Fixed and Variable amount types both work, including carry-forward estimates
- [ ] Free Trial subscriptions prompt a convert/cancel decision at trial end
- [ ] Categories (preset + custom) work and are filterable
- [ ] Monthly and Yearly billing cycles both display correctly
- [ ] EUR/USD both work, with accurate historical conversion via exchange rate snapshots
- [ ] Month View shows correct dot indicators (solid = monthly, ring = yearly)
- [ ] Monthly Cost Summary total is accurate, normalizing yearly subscriptions
- [ ] Reminders fire correctly via email and in-app, at the configured lead time
- [ ] Dashboard shows accurate basic analytics (category breakdown, monthly vs. yearly split)
- [ ] Stripe billing works end-to-end (checkout, webhook, cancellation)
- [ ] Free-tier subscription cap is enforced
- [ ] Household creation, invites, and the Shared/Private visibility toggle all work
- [ ] **Private household items are verified — via automated tests, not just manual QA — to never appear in another member's view under any query path**

---

## 5. Safe-to-Slip List (already P1/P2 in the PRD)

If real timeline pressure hits, these are the items the PRD itself already prioritized lower — slipping them to a v1.1 shipped a few weeks after launch doesn't contradict anything already decided, since "full v1" was a scope decision, not a hard same-day-launch requirement for every P1/P2 item:

1. Worth-It Rating & Tags (4.1.3) — nice decision-support layer, but nothing else depends on it
2. Calendar Export/ICS (4.12) — free, low-cost, but genuinely optional for day one
3. Advanced Analytics polish (4.11) beyond the price-change alert — trends/forecasts/overlap detection can trail Premium launch by a couple weeks without anyone being blocked
4. Pricing page/upgrade-flow polish (as opposed to the underlying Stripe plumbing, which is not on this list — see Section 2)

---

## 6. Tying Back to Success Metrics (PRD Section 8)

The phased build order lines up naturally with what's measurable at each stage:
- **Phase 1** ships → "time to add first subscription" and onboarding completion become measurable
- **Phase 2** ships → "reminder open/click rate" becomes measurable
- **Phase 3** ships → "free-to-premium conversion rate" becomes measurable
- **Phase 4** ships → "household invite acceptance rate" becomes measurable

Worth instrumenting analytics (PostHog, per the architecture doc) starting in Phase 1, even before there's anything Premium to convert to — early usage data on Phase 1/2 will inform whether the Phase 3 pricing/limits are even set correctly.
