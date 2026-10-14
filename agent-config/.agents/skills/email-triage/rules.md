# Email triage rules

Standing preferences for the `email-triage` skill. When Wade states a new one, add it here (or to `rules.local.md` if it names customers, partners, or anything private — this repo is public).

## Auto-archive

Archive without asking:

- Buckets D (login codes and security notices), E (low-value notifications), F (paid receipts), and G (monitoring and infra alerts). Infra alerts are tracked elsewhere, so archive all of them, not just older copies.
- Everything from these senders, in any bucket: `united.com`, `cursor.com`, `amazon.com`, `beehiiv.com`.
- Older copies of any repeated notification; keep only the newest.
- Dead mail: invites to past events, expired access requests, and date-bound promos whose date has passed. Keep cold pitches Wade could still answer.

## Ask first

- Newsletters (A), marketing (B), and cold pitches (C): list subjects grouped by vendor and let Wade choose per vendor — archive, unsubscribe, or unsubscribe from marketing only. Don't suggest unsubscribing from newsletters or marketing lists he hasn't named; he reads them in Superhuman.
- Anything in bucket H.

## Never

- Gmail filters. Wade triages in Superhuman, so routing belongs there, not in Gmail.

## Notification settings already changed

These sources were turned down at the source. If their mail starts arriving again, the setting reverted; tell Wade instead of archiving quietly.

- **Google Calendar:** Event responses emails are off on his calendar, so accepts and declines no longer arrive. New, changed, and cancelled event emails stay on.
- **Zoom:** the "attendees join meeting before host" email is off.
- **Secureframe:** only the weekly Admin summary, plus event alerts for auditor activity, a disabled integration, and an assigned questionnaire.

## Closed accounts

Mail from these means something is still billing or open; flag it.

- **Brex:** closed. Cards and spend moved to Ramp.
- **Blacksmith:** account closed, GitHub app uninstalled, Ramp fund archived.
- **Gem:** cancelled.

## Calendar mail

Archive every calendar notification (invites, updates, accepts, declines, cancellations, and Wade's own sent invites) **except** an invite from an outside party (not `@tractorbeam.ai`) that Wade hasn't responded to and that is still in the future. Archive past events regardless of response.

## Unsubscribed

Vendors already unsubscribed. If mail from them reappears, the unsubscribe didn't take; tell Wade rather than unsubscribing again.

- All mail: Manus, RedPocket, Photon, Next Insurance, Replicas (onboarding and updates lists)
- Marketing only: Granola, Braintrust
- Friend suggestions only: Happenstance (Wade is closing the account himself)

## Superhuman AI labels

Last known label IDs (verify with `list_labels`; IDs can change):

| ID | Label |
|---|---|
| `Label_6` | `[Superhuman]/AI/Respond` |
| `Label_8` | `[Superhuman]/AI/Meeting` |
| `Label_9` | `[Superhuman]/AI/News` |
| `Label_10` | `[Superhuman]/AI/Social` |
| `Label_11` | `[Superhuman]/AI/Pitch` |
| `Label_12` | `[Superhuman]/AI/Marketing` |
| `Label_16` | `[Superhuman]/AI/Uber` |
| `Label_17` | `[Superhuman]/AI/Recruiting` |
| `Label_18` | `[Superhuman]/AI/Login` |
| `Label_19` | `[Superhuman]/AI/Notifications` |
| `Label_24` | `Receipt sent to Brex` |
| `Label_26` | `Failed payments` |
