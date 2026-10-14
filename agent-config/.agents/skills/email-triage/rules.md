# Email triage rules

Standing preferences for the `email-triage` skill. When Wade states a new one, add it here (or to `rules.local.md` if it names customers, partners, or anything private — this repo is public).

## Auto-archive

Archive without asking:

- Buckets D (login codes and security notices), E (low-value notifications), F (paid receipts), and G (monitoring and infra alerts). Infra alerts are tracked elsewhere, so archive all of them, not just older copies.
- Everything from these senders, in any bucket: `united.com`, `cursor.com`, `amazon.com`, `beehiiv.com`.
- Older copies of any repeated notification; keep only the newest.

## Ask first

- Newsletters (A), marketing (B), and cold pitches (C): list subjects grouped by vendor and let Wade choose per vendor — archive, unsubscribe, or unsubscribe from marketing only.
- Anything in bucket H.

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
