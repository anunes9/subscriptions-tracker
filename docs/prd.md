# Product Requirements Document: Subscription Tracker

**Version:** 1.0
**Date:** August 26, 2026
**Status:** Draft

---

## 1. Overview

### 1.1 Problem Statement
People subscribe to a growing number of recurring services (streaming, software, memberships) across multiple billing cycles and currencies. It's easy to lose track of what's active, when it renews, and how much it all costs — leading to surprise charges and wasted money on forgotten subscriptions.

### 1.2 Product Summary
A mobile-first web app that lets users quickly add and manage subscriptions, see them organized in a monthly calendar view, track total monthly spend, categorize them, and get reminded before renewals. Supports monthly and yearly billing cycles, multiple currencies, and cloud sync via user accounts.

### 1.3 Goals
- Make adding a subscription take under 30 seconds.
- Give users a clear, at-a-glance picture of monthly spend across all subscriptions.
- Reduce surprise renewals through timely reminders.
- Support a freemium model that can convert to paid.

### 1.4 Non-Goals (v1)
- Automatic bank/email scanning to detect subscriptions.
- Budget caps or spending-limit alerts.
- Native iOS/Android apps (mobile-first responsive web only).
- Bill splitting with a running balance/settle-up ledger (household sharing is in v1 scope as a Premium feature — see 4.9/4.13 — but tracking who owes whom is out of scope).

---

## 2. Target Platform

- **Platform:** Mobile-first responsive web app (works on desktop, optimized for mobile viewport first).
- **Framework/stack:** To be determined by engineering; should support responsive breakpoints, PWA-friendly patterns (installable, offline-tolerant reads) as a stretch goal.

---

## 3. User Accounts

- Users must create an account to use the app. Supported sign-in methods:
  - **Email/password**
  - **Google OAuth**
  - **Passwordless — magic link with code** (see 3.0.1)
  - All three are offered side by side at sign-in; a user isn't forced into one.
- Data syncs to the cloud, accessible across devices.
- Standard flows required: sign up, log in, log out, password reset (for password-based accounts), email verification.
- Account deletion must also delete all associated subscription data (GDPR-style compliance).

### 3.0.1 Passwordless Login (Magic Link with Code)
**Priority:** P0

Reduces sign-in friction, especially on mobile where typing a password is annoying and switching to an email app can interrupt the flow.

- User enters their email address and requests a sign-in link.
- The app emails a message containing **both**: a clickable magic link, and a **6-digit numeric code** they can type directly back into the app instead of leaving it — useful when opening the email app would break the flow (e.g. the email opens in a different browser/device than where the code was requested, or on mobile where switching apps is disruptive).
- Either the link or the code signs the user in; both are single-use and expire after a short window (e.g. 10 minutes).
- If the email doesn't match an existing account, completing the flow **creates** one — passwordless sign-in doubles as sign-up, same as the other methods.
- Rate-limited per email address to prevent abuse (e.g. no more than a few requests per 10 minutes).
- Does not replace password/Google sign-in — a user who originally signed up with a password can still use it; passwordless is simply an additional, faster path.

### 3.1 Onboarding Flow
**Priority:** P0

After account creation, a guided setup speeds up initial adoption by leveraging the known-service directory (4.4.1) instead of requiring one-by-one manual entry:

- Present a checklist of common services grouped by category (e.g. "Which of these do you use?" — Netflix, Spotify, Disney+, gym, etc.), pre-populated with logos from the directory.
- User taps to select the ones they have; each selected service creates a draft subscription pre-filled with name, icon, category, and brand color — user then just fills in amount and billing date to confirm.
- Skippable at any point — leads into the standard quick-add flow (4.1) for anything not in the checklist, or if the user prefers manual entry throughout.
- Goal: get a user from signup to their first few subscriptions logged in well under a minute, supporting the "time to add first subscription" success metric (Section 8).

---

## 4. Core Features

### 4.1 Add / Manage a Subscription
**Priority:** P0

Fields when adding a subscription:
| Field | Required | Notes |
|---|---|---|
| Name | Yes | Free text, e.g. "Netflix" |
| Amount | Yes | Numeric |
| Currency | Yes | Defaults to user's preferred currency, editable per subscription |
| Billing cycle | Yes | Monthly or Yearly (toggle) |
| Renewal/billing date | Yes | Date picker; for monthly, day-of-month; for yearly, full date |
| Category | Yes | Preset dropdown + "add custom category" option |
| Icon/logo | No | Auto-suggested from name if possible (e.g. via known-service icon list), fallback to generic icon or emoji picker |
| Notes | No | Free text |
| Active/Paused/Cancelled status | Yes | Defaults to Active |
| Amount type | Yes | Fixed or Variable (toggle) — see 4.1.1 |
| Subscription type | Yes | Regular or Free Trial (toggle) — see 4.1.2 |
| Worth-it rating | No | Optional 1–5 rating — see 4.1.3 |
| Tag | No | Essential / Nice-to-have — see 4.1.3 |
| Visibility | Yes (if in a household) | Private or Shared — see 4.13. Defaults to Shared for household members. Not shown/relevant for users not in a household. |

Actions:
- Add subscription (quick-add flow, minimal required fields to reduce friction)
- Edit subscription
- Delete subscription
- Mark as paused or cancelled (retains history without counting toward active totals)
- Duplicate subscription (for quickly adding similar entries)

#### 4.1.1 Amount History Log (core data concept)
**Priority:** P0

Every subscription — regardless of Amount Type — maintains a **history log**: one entry per billing period recording the amount that applied during that period (period → amount). This is a core part of the subscription data model, not a feature exclusive to Variable subscriptions.

- **Fixed subscriptions:** each new period automatically logs the same amount. This is invisible to the user in normal use, but means the log always reflects what was actually charged in any given past period, even if the fixed amount is later changed (e.g. a plan price increase) — historical totals stay accurate rather than being overwritten.
- **Variable subscriptions:** the log is what the user actively confirms/edits each period, and is what powers estimates (see below).
- **Amount Type (Fixed/Variable) can be changed at any time** without any migration or data loss, because both types read/write the same log:
  - Switching **Fixed → Variable**: past periods already in the log stay as-is (backfilled automatically from the fixed amount that applied each period). The next period follows the Variable flow described below.
  - Switching **Variable → Fixed**: the log stays intact as a historical record; future periods simply log the new fixed amount each cycle.

**Variable-period behavior**, using the shared log:
- When a subscription's billing date passes (or a few days before), if it's Variable, the app prompts the user to confirm/enter that period's actual amount via a quick one-tap/inline update — no need to re-add the subscription.
- Until updated, the current period's amount is **estimated using the most recent logged amount** (carry-forward from the last known period, whether that period was itself Fixed or Variable).
- Estimated amounts are visually distinguished from confirmed actuals in the month view and dashboard (e.g. a "~" prefix or "estimated" label).
- The monthly cost summary total uses the actual logged amount once entered, or the estimate otherwise.

**Additional benefits of the universal log:**
- Powers a simple trend view per subscription (e.g. "Electricity: last 6 months," or "Netflix: price changes over time") for both Fixed and Variable subscriptions — ties into the spending-trends item under Future Considerations, though this basic history is in scope for v1 since the log is required regardless.
- Enables accurate historical totals: "what did I spend in March" reflects what was actually true in March, not today's current amount.
- Storage cost is one row per subscription per period — trivial at expected scale, even over many years.

#### 4.1.2 Free Trial Tracking
**Priority:** P0

Free trials are a distinct source of surprise charges — the moment of risk is trial-to-paid conversion, not a normal renewal. Handled as a **Subscription Type** setting:

- **Regular:** standard behavior as described above.
- **Free Trial:** the subscription has a trial end date instead of (or in addition to) a normal renewal date. Once added, the app treats the trial end date with elevated urgency:
  - A more prominent, earlier-and-closer reminder cadence than normal renewals (e.g. reminders at both ~3 days and ~1 day before conversion, vs. a single default reminder for regular subscriptions).
  - Visually distinguished in month view and dashboard (e.g. a "Trial" badge, different accent treatment) so it stands out from committed recurring costs.
  - At the trial end date, the app prompts the user to confirm: convert to Regular (enter the post-trial amount and billing cycle) or mark as Cancelled. If the user takes no action, the subscription is flagged as needing attention rather than silently converting.
- Trials still use the shared history log (4.1.1) once converted to Regular, so no data is lost in the transition.

#### 4.1.3 Worth-It Rating & Tags
**Priority:** P1

Lightweight decision-support fields to help users decide what to keep or cut, independent of category:

- **Worth-it rating:** optional 1–5 rating per subscription, prompted periodically (e.g. gently surfaced every few months, never forced) or editable anytime from the subscription detail view. Purely a personal signal — not shared, not benchmarked against other users.
- **Tag — Essential / Nice-to-have:** a simple two-state tag letting users mark which subscriptions are non-negotiable vs. discretionary. Filterable in the subscription list, and usable as an additional lens in the Analytics & Insights section (4.11) — e.g. "$X/month is Nice-to-have spend."
- Both fields are optional and free (not gated to Premium), since they're low-cost to build and directly feed the more elaborate Premium insights (overlap detection, "what to cut" prompts) without requiring new data collection later.

### 4.2 Month View
**Priority:** P0

- Calendar-style or list-style view (mobile-first: list grouped by date is likely more usable than a dense calendar grid — flag for design exploration) showing all subscriptions renewing within the selected month.
- Each entry shows: name/icon, amount (in its currency + converted amount if multi-currency), renewal date, category tag.
- Navigation: swipe or arrows to move between months (prev/next).
- Yearly subscriptions appear only in the month they renew, but should be visually distinguished (e.g. a "yearly" badge) from monthly ones.
- Tapping an entry opens/edits that subscription.

### 4.3 Monthly Cost Summary
**Priority:** P0

- Prominent total showing combined monthly cost of all **active** subscriptions.
- Yearly subscriptions are normalized to a monthly-equivalent cost (amount ÷ 12) when included in the total, with an option to toggle between "monthly view" (normalized) and "this month's actual charges" (only what renews in the selected month).
- Multi-currency totals: convert all subscriptions to a single user-selected "home currency" for the total, using current exchange rates. Show a note/timestamp on rate freshness.
- Secondary breakdown: total by category (e.g. pie or bar chart) and monthly vs. yearly split.

### 4.4 Categories
**Priority:** P0

Preset categories, informed by the most common recurring expense types:

| Category | Example services |
|---|---|
| Streaming & Entertainment | Netflix, Amazon Prime Video, HBO Max, Disney+, YouTube Premium |
| Music & Audio | Spotify, Apple Music, YouTube Music, Audible |
| Health & Fitness | Gym memberships, fitness apps |
| Home & Utilities | Internet/TV provider, water, electricity, gas |
| Transportation & Vehicle | Car insurance, maintenance, fuel, ride-hailing |
| Food & Delivery | Food/grocery delivery apps |
| Education | Tuition, online courses |
| Family & Childcare | Baby care, childcare services |
| Software & Cloud | SaaS tools, cloud storage |
| Other | Custom / uncategorized (default fallback) |

- Users can create custom categories (name + optional color/icon).
- Users can edit/delete custom categories (deleting reassigns affected subscriptions to "Other" or prompts reassignment).
- Filter subscription list/month view by category.

#### 4.4.1 Known-Service Directory (icons & auto-categorization)

To speed up the add flow, the app maintains a curated directory of known services, each mapped to a logo/icon and a default category. When a user types a subscription name (e.g. "Netflix"), the app auto-suggests the matching service, pre-fills its icon, and pre-selects its category — user can still override both.

- **Bundled icon set for v1:** the app ships with recognizable, ready-to-use logo icons (not fetched at runtime) for the most common services, so recognition is instant with no loading delay. Finalized initial set:
  - **Streaming & Entertainment:** Netflix, Amazon Prime Video, HBO Max, Disney+, YouTube Premium, Hulu, Peacock, Apple TV, Paramount+, SkyShowtime, Crunchyroll, DAZN, SportTV (PT), Lionsgate+
  - **Music & Audio:** Spotify, Apple Music, YouTube Music, Amazon Music, Deezer, Tidal, Audible
  - **Software & Cloud:** Claude, ChatGPT, iCloud+, Google One, Gemini, Dropbox, Railway, Vercel, Cursor
  - **Home & Utilities:** Vodafone (PT), MEO (PT), NOS (PT), EDP (PT), Galp (PT), plus generic "Electricity" and "Gas" fallback entries for providers outside the curated list
  - **Health & Fitness (Portugal gym chains):** Holmes Place, Fitness Hut, Virgin Active, Solinca, Fitness UP, Vivagym, TTF
  - **Transportation & Vehicle:** Uber, Uber One, plus major Portuguese car insurers — Fidelidade, Generali Tranquilidade, Ageas, Allianz, Zurich
  - **Food & Delivery:** Glovo, Uber Eats
  - Plus other clearly recognizable, high-usage brands as identified during design for remaining categories (Education, Family & Childcare) — final list to be confirmed with design.
- **Brand colors:** wherever a known service's icon, badge, or accent color is shown (e.g. in list rows, month view entries, category charts), use that service's actual brand color rather than a generic app color — this reinforces instant recognition (e.g. Netflix red, Spotify green, Claude's brand color). Generic/custom subscriptions without a known brand fall back to the category's default color or a user-selected color.
- **Cancellation help:** where available, each directory entry stores a direct link (or brief instructions) for how to cancel that service, surfaced on the subscription's detail view (e.g. a "How to cancel" button). Saves users from having to search for this themselves at the moment they've decided to cut a subscription. Links maintained by the team alongside the rest of the directory; entries without a known cancellation path simply omit the button.
- **v1 regional scope: Global major brands + Portugal-specific providers**, since local providers (e.g. utility/internet companies) are a common recurring expense not covered by global brand lists.
- Any subscription not found in the directory falls back to manual category selection and a generic category icon or emoji picker (per 4.1).
- Directory is maintained/extensible by the team over time; not user-editable beyond adding their own custom subscriptions.
- Architecture should allow adding more regions/providers, services, and icons later without a data model change (service directory entries tagged by region, each with icon asset + brand color reference).
- **Licensing note:** bundling third-party logos/brand colors means design/legal should confirm usage is limited to factual identification of the service (nominative use) rather than implying endorsement or partnership — standard practice for this kind of app, but worth a quick check before launch.

### 4.5 Billing Cycle Support
**Priority:** P0

- Monthly and Yearly are the two supported cycles for v1.
- Each subscription stores its own cycle independently.
- (Future consideration, not v1: weekly, quarterly, custom intervals — noted in Future Considerations.)

### 4.6 Currency Support
**Priority:** P0

- **v1 scope: EUR and USD only.** User sets a "home/default currency" in settings, choosing either EUR or USD.
- Each subscription can be entered in either EUR or USD, independent of the home currency (e.g. home currency USD, but a subscription billed in EUR).
- A single, simple exchange rate (EUR↔USD) is fetched from a third-party API and refreshed daily to power converted totals when a subscription's currency differs from the home currency.
- All amounts displayed with proper currency symbols/formatting ($ / €).
- Architecture should be built to allow adding more currencies later without a data model change (e.g. currency stored per-subscription as a code, not assumed) — full multi-currency (beyond EUR/USD) is deferred to a future release.

### 4.7 Renewal Reminders
**Priority:** P0

- Reminders sent via **email and in-app notification**.
- Default reminder timing: configurable per user (e.g. default 3 days before renewal), with a global setting and possible per-subscription override.
- In-app: a notification/bell icon with upcoming renewals; a dashboard "upcoming this week" widget.
- Email: transactional email sent at the configured lead time before each renewal.
- Users can opt out of reminders globally or per subscription.

### 4.8 Dashboard / Home
**Priority:** P0

- Landing screen after login showing:
  - Total monthly cost (normalized)
  - Upcoming renewals (next 7–14 days)
  - Quick-add button (prominent, thumb-reachable on mobile)
  - Category breakdown snapshot

### 4.9 Freemium Model
**Priority:** P1 (define limits, but monetization plumbing can follow core feature build)

**Free tier** (should be genuinely usable, not crippled — goal is real adoption and habit formation):
- Up to ~7 active subscriptions
- Preset categories only
- Global default reminder timing (single setting, applies to all subscriptions)
- Month view, monthly cost summary, category breakdown (basic)
- Fixed and Variable amount support, history log (core functionality, not gated)

**Premium tier:**

| Feature | Why it drives payment |
|---|---|
| Unlimited subscriptions | Direct usage ceiling — most users cross the free cap once they actually audit their spending |
| Custom categories & icons | Personalization for power users |
| Household/family sharing (see 4.13) | Split bills (e.g. shared Netflix, internet), shared visibility across household members; invite flow doubles as organic growth loop |
| Advanced analytics & insights (see 4.11) | Turns the app from "tracker" into "insight tool" |
| Data export (CSV/PDF) | Useful for personal budgeting or expense/tax purposes |
| Full multi-currency (beyond EUR/USD) | Travelers/expats — smaller but high-willingness-to-pay segment |
| Per-subscription custom reminder timing | Finer control vs. the free tier's single global default |
| Price-change alerts (flags when a subscription's logged amount changes period-to-period, using the history log) | Tangible "the app saved me money" moment; low build cost since it reuses the history log already required for core functionality |
| One-time expense tracking (v1.x — see 4.10) | Expands the app from subscriptions-only into a lightweight general expense tracker, increasing daily/weekly usage frequency rather than just monthly check-ins |
| Priority support / early access to new features | Standard retention lever |

Requires: pricing page, upgrade flow, payment integration (e.g. Stripe), subscription management for the app's own premium plan (meta, but standard SaaS pattern).

### 4.10 One-Time Expense Tracking (Premium, v1.x)
**Priority:** P2 — post-launch premium expansion, not part of initial release

Extends the app beyond recurring subscriptions to capture one-off purchases (e.g. a dinner, a clothing purchase, a one-time shopping trip), turning it into a lighter general expense tracker while keeping subscriptions as the primary focus.

- **Data model reuse:** a one-time expense uses the same underlying shape as a history log entry (amount, date, category, currency) but with no recurrence and no renewal/reminder logic — architecturally cheap to add given the log structure already exists for subscriptions.
- **Entry:** quick-add flow similar to subscriptions (amount, category, date, optional note), but no billing cycle or renewal date fields.
- **Categories:** reuses the same preset + custom category system as subscriptions (4.4), so spending is grouped consistently regardless of type.
- **Reporting — kept separate by default:** the core dashboard and monthly cost summary (4.3) continue to reflect **subscriptions only**, preserving the app's core value of tracking predictable, committed monthly cost.
- **Combined view (optional):** a secondary "All Spending" view/tab combines subscriptions + one-time expenses into a single total and category breakdown, for users who want the fuller picture. Toggle between "Subscriptions" and "All Spending" rather than merging by default.
- **Household visibility:** one-time expenses carry the same Shared/Private visibility setting as subscriptions when the user belongs to a household (see 4.13) — e.g. a dinner expense can be marked Private even if the user's household sharing default is Shared.
- Out of scope for this feature (may be reconsidered later): receipt scanning/photo capture, bank integration, splitting a single expense across multiple categories.

### 4.11 Analytics & Insights
**Priority:** Basic = P0 (part of core v1), Advanced = P1 (Premium)

Leverages the history log (4.1.1) and category system (4.4) already core to the data model. Split into a **Basic** set available free, and an **Advanced** set gated to Premium (referenced from 4.9).

#### Basic (Free)
- Category breakdown chart (pie/bar) — current snapshot, already covered in 4.3/4.8.
- Monthly vs. yearly subscription split (cost and count).

#### Advanced (Premium)
**Spending trends**
- Monthly total over time (line chart, last 6/12 months) — subscriptions only, or combined with one-time expenses if that feature is enabled (4.10).
- Category breakdown over time (e.g. how spend in a category has grown/shrunk over months).
- Fixed vs. Variable spend split trend — how much of total spend is predictable vs. fluctuating.

**Cost changes & anomalies**
- Price-change history per subscription — visualized as a "price over time" line per service (pairs with the price-change alerts in 4.9).
- "Biggest movers" this month — which subscriptions/categories increased or decreased the most.
- Stale-subscription nudge — soft prompt for subscriptions the user hasn't opened/reviewed in the app for a while (review reminder, not a claim about actual usage of the underlying service).

**Composition & benchmarking**
- Category breakdown as % of total spend (e.g. "32% of your subscriptions go to Streaming & Entertainment").
- Annualized cost view — reframes any subscription's monthly cost as its yearly equivalent (e.g. "$480/year"), to make small recurring amounts feel more tangible.

**Forward-looking**
- Renewal forecast — projected spend for next 30/60/90 days based on known upcoming renewals.
- "If nothing changes" annualized projection based on current active subscriptions.

**Actionable / money-saving prompts**
- "Renewing soon — worth reviewing?" prompts for upcoming renewals, framed as a decision point rather than just a notification.
- Duplicate/overlap detection — flags likely-overlapping services within the same category (e.g. multiple streaming subscriptions), surfaced as a gentle "you're spending $X across N similar services" insight.

### 4.12 Calendar Export (ICS)
**Priority:** P2

Lets users see renewals in the calendar app they already use daily, rather than only inside this app.

- Generates a subscribable ICS feed (or one-time export file) containing all upcoming renewal dates, including Free Trial end dates (4.1.2), as calendar events.
- Feed stays live/updated if subscribed (vs. a static one-time export) so new or changed subscriptions automatically reflect in the user's calendar.
- Works with Google Calendar, Apple Calendar, Outlook — any client that supports subscribing to an ICS URL.
- Free feature (low build cost, drives habitual awareness which supports retention) — not gated to Premium.

### 4.13 Household Sharing (Premium)
**Priority:** P0 — in v1 launch scope (moved forward from earlier v1.x plan)

Lets a Premium user share a combined subscription dashboard with family/household members, while keeping individual items private by default control.

**Household setup**
- Any Premium user can create a Household and becomes its **owner**.
- Owner invites other users by email; invited users must have (or create) their own account — a household member is always a full account holder, not a guest.
- Roles: **Owner** (can rename/delete the household, remove members, and — per the open question below — decide default visibility policy) and **Member** (can view shared items, manage their own subscriptions/expenses, and leave the household).
- A user can belong to only one household at a time for v1 (simplifies visibility logic; multiple households is a possible future extension).
- Only the household **owner** needs an active Premium subscription for the household to function; members join and use shared features under the owner's plan (standard "family plan" pattern) — final billing mechanics TBD with business.

**Visibility model**
- Every subscription (4.1) and one-time expense (4.10) has a **Visibility** setting: **Shared** or **Private**.
- Only relevant once a user is part of a household — for users not in a household, this field is inert/hidden.
- **Default: Shared.** Once a user joins a household, their subscriptions default to visible to the household (opt-out model, per product decision) — this maximizes the "aha" moment of seeing the combined picture immediately, rather than requiring users to manually opt in item by item.
- Users can flip any individual subscription or one-time expense to **Private** at any time, hiding it from other household members entirely (not shown in the household dashboard, category breakdowns, or totals) while it remains fully visible in the owner's own personal view.
- Changing visibility is always self-service and immediate — no approval needed from other members.

**Household Dashboard**
- A dedicated view (separate from each member's personal dashboard) showing the combined total, category breakdown, and upcoming renewals across all members' **Shared** items only.
- Each shared item is attributed to the household member who owns it, so it's clear who's paying for what.
- Personal dashboards are unaffected — a user's own view always shows 100% of their own subscriptions and expenses (Shared and Private alike); only the household view is filtered to Shared-only, and only for items belonging to *other* members (a user's own items always appear in their personal view regardless of visibility).

**Out of scope for v1**
- Settle-up/IOU tracking (who owes whom for a split bill) — this feature shows shared visibility, not a ledger (per Non-Goals, 1.4).
- Per-member spending limits or approval workflows.
- More than one household per user.

---

## 5. Non-Functional Requirements

- **Mobile-first design:** all layouts designed for small viewports first, then scaled up; touch-friendly targets, minimal required taps to add a subscription.
- **Performance:** month view and dashboard should load quickly even with 100+ subscriptions.
- **Security:** passwords hashed, standard auth security practices, HTTPS everywhere.
- **Data privacy:** currency amounts and subscription data are personal financial data — handle with care; no third-party sharing without consent.
- **Accessibility:** sufficient color contrast, screen-reader-friendly forms, scalable text.

---

## 6. Open Questions

- Exact free-tier subscription limit and premium price point.
- Should month view default to calendar grid or list layout on mobile? (Recommend usability testing.)
- Which exchange-rate provider to use for EUR↔USD conversion.
- Should paused/cancelled subscriptions be excluded from monthly totals by default, or shown greyed out?
- Icon/logo sourcing for popular services — manual curated list vs. third-party logo API.
- Household billing mechanics: does the owner's single Premium subscription cover all members, or does each member need their own? (Standard "family plan" pattern assumed, TBD with business.)
- Should the household owner be able to override a member's item to Private (privacy concern) — or is visibility always solely the item-owner's choice? (Current assumption: always the item owner's choice, owner has no override.)
- Exact rate-limit thresholds for passwordless login requests, and whether repeated failed code entries should temporarily lock that request (not the account) rather than just expiring it.

---

## 7. Future Considerations (Post-v1)

- Full multi-currency support beyond EUR/USD.
- Additional billing cycles (weekly, quarterly, custom).
- Bank/email integration for auto-detecting subscriptions.
- Budget caps and spending alerts.
- Native mobile apps.
- Localization beyond English (e.g. Portuguese, given regional provider support in 4.4.1).
- Power-user integrations (API access, Zapier/Notion) for exporting subscription data into external tools.
- Push notifications (PWA) and/or SMS as additional reminder channels beyond email/in-app.

---

## 8. Success Metrics

- Time to add first subscription (target: under 30 seconds).
- % of users who add 3+ subscriptions in first session (activation).
- Onboarding checklist completion rate (3.1).
- Reminder open/click rate.
- Free-to-premium conversion rate.
- Household invite acceptance rate (4.13).
- Monthly active users retained month-over-month.
