# Data Model: Subscription Tracker

**Companion to:** subscription-tracker-prd.md
**Diagram:** subscription-tracker-erd.mermaid
**Version:** 1.0 — Draft

---

## 1. Design Principles

These fall directly out of decisions made in the PRD:

1. **The history log is universal.** Every subscription — Fixed or Variable — writes to `HISTORY_LOG_ENTRY` per billing period. This is what makes Fixed↔Variable switching seamless (PRD 4.1.1) and gives every subscription trend data for free (PRD 4.11).
2. **One-time expenses reuse the same shape as a log entry** (amount, category, date, currency) but live in their own table since they have no recurrence, no subscription parent, and no reminder logic (PRD 4.10).
3. **The service directory is global, not user-owned.** `SERVICE_DIRECTORY_ENTRY` rows are maintained by the team, not created by users — a `Subscription` optionally references one for icon/color/cancellation-link inheritance, but always stores its own `name`/`category_id` so it still works if unlinked (PRD 4.4.1).
4. **Categories are polymorphic between preset and custom.** `CATEGORY.user_id` is null for the ~9 preset categories (global, shared across all users) and set for a user's custom ones. This avoids a separate "preset category" table.
5. **Currency is stored per-row, not inferred.** Every monetary entity (`Subscription`, `HistoryLogEntry`, `OneTimeExpense`) carries its own `currency`, even though v1 only allows EUR/USD — this keeps the schema ready for full multi-currency (Future Consideration) without a migration.
6. **Estimated vs. confirmed is a first-class flag**, not inferred from missing data. `HISTORY_LOG_ENTRY.is_estimated` makes it trivial to render the "~" treatment (PRD 4.1.1) and to know which rows to overwrite once the user confirms an actual.
7. **Household sharing reuses ownership, not a separate copy.** A shared `Subscription` or `OneTimeExpense` is still owned by exactly one `User` — sharing is expressed via `household_id` + `visibility`, not by duplicating the row into a household-owned table. This keeps a single source of truth per item and makes visibility a simple filter, not a sync problem.

---

## 2. Entities

### 2.1 User
Represents an account holder. Holds account-level defaults so most reminder/currency logic doesn't need to be repeated per subscription.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| email | string | unique |
| password_hash | string | nullable if OAuth-only |
| oauth_provider | string | nullable, e.g. "google" |
| home_currency | enum(EUR, USD) | user's default display currency |
| default_reminder_lead_days | int | e.g. 3; applies to all subscriptions unless overridden (Premium) |
| is_premium | boolean | |
| premium_since | datetime | nullable |
| created_at | datetime | |

### 2.2 Category
Both preset and custom categories live here.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK → User) | **null** for the ~9 global preset categories; set for user-created custom ones |
| name | string | |
| icon | string | icon identifier |
| color | string | hex; used as fallback when a subscription has no brand color |
| is_preset | boolean | redundant with user_id being null, but kept for query simplicity |

### 2.3 ServiceDirectoryEntry
Global, team-maintained directory of known services (Netflix, Spotify, Claude, Vodafone, etc.) — powers auto-suggest, icons, brand colors, and cancellation links.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| name | string | matched against user input during add flow |
| default_category_id | uuid (FK → Category) | pre-selected category when matched |
| icon_asset | string | bundled asset reference, not a runtime-fetched URL |
| brand_color | string | hex |
| cancellation_url | string | nullable |
| region | string | "global", "PT", etc. — supports future region expansion |

### 2.4 Subscription
The core entity. Always belongs to a user; optionally linked to a directory entry.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK → User) | |
| service_directory_id | uuid (FK → ServiceDirectoryEntry) | nullable — null for custom/unmatched services |
| category_id | uuid (FK → Category) | |
| name | string | always stored directly, even if matched to directory |
| currency | enum(EUR, USD) | |
| billing_cycle | enum(monthly, yearly) | |
| amount_type | enum(fixed, variable) | see PRD 4.1.1 |
| subscription_type | enum(regular, trial) | see PRD 4.1.2 |
| status | enum(active, paused, cancelled) | |
| billing_anchor_date | date | day-of-month for monthly; full date for yearly |
| trial_end_date | date | nullable; set when subscription_type = trial |
| rating | int (1–5) | nullable, PRD 4.1.3 |
| tag | enum(essential, nice_to_have) | nullable, PRD 4.1.3 |
| icon_override | string | nullable — user-chosen icon overriding directory default |
| color_override | string | nullable |
| notes | text | nullable |
| custom_reminder_lead_days | int | nullable — Premium per-subscription override of the user default |
| household_id | uuid (FK → Household) | nullable — set only if the owning user belongs to a household (Premium, PRD 4.13) |
| visibility | enum(private, shared) | default `shared` once in a household; irrelevant/ignored if `household_id` is null |
| created_at | datetime | |
| updated_at | datetime | |

**Note:** the *current* amount is not stored directly on this row — it's always the latest confirmed (or estimated) entry in `HISTORY_LOG_ENTRY` for the current period. This avoids two sources of truth.

### 2.5 HistoryLogEntry
One row per subscription per billing period. The core mechanism behind Variable amounts, price-change detection, and trend analytics.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| subscription_id | uuid (FK → Subscription) | |
| period | string | e.g. `"2026-08"` for monthly; a full date for yearly cycles |
| amount | decimal | |
| currency | string | usually matches the subscription's currency at that time |
| is_estimated | boolean | true = carried-forward estimate, not yet confirmed by the user |
| confirmed_at | datetime | nullable — set when the user confirms/edits the actual |
| created_at | datetime | |

Unique constraint: `(subscription_id, period)` — one entry per subscription per period.

### 2.6 OneTimeExpense (Premium, v1.x — PRD 4.10)
Same shape as a log entry, but standalone — no subscription parent, no recurrence.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| user_id | uuid (FK → User) | |
| category_id | uuid (FK → Category) | |
| amount | decimal | |
| currency | enum(EUR, USD) | |
| expense_date | date | |
| note | text | nullable |
| household_id | uuid (FK → Household) | nullable — see 4.13 |
| visibility | enum(private, shared) | default `shared` once in a household |
| created_at | datetime | |

### 2.7 Household / HouseholdMember (Premium — PRD 4.13)
Household sharing is in v1 launch scope. A `Subscription` or `OneTimeExpense` isn't duplicated for sharing — it stays owned by one `User`, and becomes visible to the household via `household_id` + `visibility = shared` (see Design Principle 7).

| Field | Type | Notes |
|---|---|---|
| Household.id | uuid (PK) | |
| Household.name | string | |
| Household.owner_user_id | uuid (FK → User) | must hold an active Premium subscription for the household to function |
| Household.created_at | datetime | |
| HouseholdMember.id | uuid (PK) | |
| HouseholdMember.household_id | uuid (FK → Household) | |
| HouseholdMember.user_id | uuid (FK → User) | unique per user for v1 — a user belongs to at most one household |
| HouseholdMember.role | enum(owner, member) | |
| HouseholdMember.joined_at | datetime | |

Constraint: `HouseholdMember.user_id` is unique (one active household membership per user in v1 — see PRD 4.13 out-of-scope note on multiple households).

### 2.8 ReminderLog
Record of reminders actually sent — supports the "reminder open/click rate" success metric (PRD Section 8) and prevents duplicate sends.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| subscription_id | uuid (FK → Subscription) | |
| channel | enum(email, in_app) | |
| trigger_reason | enum(renewal, trial_end) | |
| sent_at | datetime | |

### 2.9 PasswordlessLoginRequest
Supports magic-link-with-code sign-in (PRD 3.0.1). Short-lived, single-use records — not tied to an existing `User` yet at creation time, since passwordless sign-in can also create an account.

| Field | Type | Notes |
|---|---|---|
| id | uuid (PK) | |
| email | string | the address the request was made for |
| token_hash | string | hash of the magic-link token (never store the raw token) |
| code_hash | string | hash of the 6-digit code (never store the raw code) |
| expires_at | datetime | short window, e.g. 10 minutes from creation |
| used_at | datetime | nullable — set once consumed; a used or expired request can't be reused |
| created_at | datetime | |

Not linked via foreign key to `User` — on successful verification, the app looks up or creates a `User` by `email` and starts a session. Old/expired rows can be purged periodically (e.g. a daily cleanup job alongside the other Solid Queue jobs).

---

## 3. Key Relationships

- `User` 1—N `Subscription`, `Category` (custom only), `OneTimeExpense`
- `Category` 1—N `Subscription`, `OneTimeExpense`
- `ServiceDirectoryEntry` 1—N `Subscription` (optional link)
- `Subscription` 1—N `HistoryLogEntry`, `ReminderLog`
- `Household` 1—N `HouseholdMember`, `Subscription` (via nullable `household_id`), `OneTimeExpense` (via nullable `household_id`)
- `User` 1—1 `HouseholdMember` (at most one active membership in v1)

See `subscription-tracker-erd.mermaid` for the full visual diagram.

---

## 4. Derived / Computed Values (not stored)

These are calculated at query time rather than persisted, to avoid sync bugs:

- **Current period amount** — latest `HistoryLogEntry` for a subscription's current period (falls back to carry-forward logic per PRD 4.1.1 if no entry exists yet).
- **Monthly cost summary total** (PRD 4.3) — sum of active subscriptions' current-period amounts, normalizing yearly subscriptions to `amount / 12`, converted to `home_currency` using the daily EUR/USD rate.
- **Annualized cost view** (PRD 4.11) — `monthly_equivalent * 12`.
- **Price-change alert trigger** — compare the newest confirmed `HistoryLogEntry.amount` to the previous period's for the same subscription.
- **Duplicate/overlap detection** — group active subscriptions by `category_id`, flag categories with more than one active entry.
- **Household dashboard total** (PRD 4.13) — sum of current-period amounts for all `Subscription`/`OneTimeExpense` rows where `household_id` matches the household AND `visibility = shared`, across all members, converted to a common display currency. A member's own personal dashboard ignores `visibility` entirely and always shows 100% of their own items.

---

## 5. Open Implementation Questions

- Exchange rate source: store daily EUR/USD snapshots in a small `ExchangeRate` table (date, rate) for historical accuracy in past-month totals, or always use latest rate? (Recommend storing snapshots — keeps "what did I spend in March" accurate even if rates move later.)
- Should `HistoryLogEntry.period` be a string key (`"2026-08"`) or a proper `period_start_date`? String is simpler for monthly-only v1; a date column scales better if quarterly/weekly cycles are added later (Future Consideration).
- Soft-delete vs. hard-delete for cancelled subscriptions — likely soft-delete (status = cancelled) to preserve history log integrity for analytics.
