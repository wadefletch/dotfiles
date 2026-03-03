# File Organization Guide

Instructions for organizing Wade's Downloads folder into ~/Documents (iCloud Drive synced).

## Key Principles

- **Downloads is a todo list.** The goal is to empty it, but it's fine to skip items and circle back.
- **Never use `rm`.** Always use `mv ~/.Trash/` or the `trash` CLI.
- **Read before filing.** Don't guess where a file goes based on name alone. Read the contents (or use a haiku subagent to read/analyze) when it's not completely obvious.
- **Ask when unsure.** Use AskUserQuestion to clarify ambiguous files rather than guessing wrong.
- **Tax & Finance is personal only.** Wade's personal financial documents (insurance, bank statements, tax returns, eBay orders, etc.). Never put Tractorbeam or client documents here.
- **Social Media is Wade's personal profiles.** Not Tractorbeam social media assets.

## Folder Structure

### ~/Documents/ (top level)
Personal documents, general reference. Some standalone files live here (e.g., business writing guides).

### ~/Documents/Tax & Finance/
Wade's **personal** financial documents only: tax returns, W-2s, paystubs, insurance, bank statements, utility bills, personal purchase receipts.

**NOT:** Tractorbeam corporate finances, client financial documents, or balance sheets from client work.

### ~/Documents/Mazda CX-5/
Wade's personal car documents (financing, insurance, etc.).

### ~/Documents/Recovery Phrases/
Recovery codes, recovery keys, 2FA backup codes. All services (personal and work).

### ~/Documents/Signatures/
Digital signatures and initials.

### ~/Documents/Resumes/
Wade's personal resumes only.

### ~/Documents/Social Media/
Wade's **personal** social media profile photos and banners. Not Tractorbeam brand assets.

### ~/Documents/Reference Decks/
Example documents from other companies used as reference material. This includes:
- Consulting firm reports/decks (BCG, Deloitte, Accenture, SAP, etc.)
- Example contracts, MSAs, SOWs from other companies (government procurement, AT&T, etc.)
- Industry whitepapers and AI research papers
- Template documents from legal publishers (e.g., Kilpatrick Townsend practice notes)
- Reference policy documents (HIPAA examples, harassment form templates, etc.)
- Okta workflow pattern guides, Windows 365 job aids, etc.

### ~/Documents/OSINT/
Security research, CVEs, vulnerability demos.

### ~/Documents/Data Exports/
Calendar exports, data dumps, backup files.

### ~/Documents/Tractorbeam/brand/
Tractorbeam's own brand assets:
- Logo files (Logo_Black, Mark_Black, Mark_White, etc.)
- Figma frame exports (website illustrations, UI mockups)
- Stock office photos used for website/marketing
- Tractorbeam social media banners (X, LinkedIn)
- Font files used in Tractorbeam branding
- **Waud brand assets go in the Waud client folder, not here.**

### ~/Documents/Tractorbeam/corporate/
Tractorbeam internal business documents:
- Employee agreements (CIIAAs)
- SaaS expense tracking
- Okta admin logs (ABM activity, sign-in info)
- API cost reports
- Financial snapshots (Tractorbeam's own finances)
- Apple Developer Program License Agreement (Tractorbeam's account)
- Internal Terraform/infrastructure artifacts

### ~/Documents/Tractorbeam/recovery-codes/
Tractorbeam service recovery codes.

### ~/Documents/Tractorbeam/clients/{client}/
Client-specific work product, data, and assets. See client index below.

### ~/Desktop/okta-app-logos/
Product logos uploaded to Okta for app tiles. These are logos of **tools Tractorbeam uses** (Anthropic, ChatGPT, Cursor, Datadog, Fleet, Granola, OpenAI, Apple, etc.). Temporary holding folder on Desktop.

### ~/.dotfiles/
Configuration files and settings exports (e.g., Obsidian web clipper settings).

### ~/Developer/Tractorbeam/internal-infra/
Infrastructure credentials and config (e.g., GCP service account keys). Flag any credentials found in Downloads as potential security risks.

## Tractorbeam Client Index

### Waud (~/Documents/Tractorbeam/clients/waud/)
**Also known as:** WCP, Waud Capital Partners, RCVC, CoE, Center of Excellence

Waud Capital Partners (WCP) hired RCVC, who hired Tractorbeam to build the Center of Excellence (CoE) product.

**Keywords:** WCP, Waud, RCVC, CoE, Center of Excellence, PortCo, Portfolio Assessment, Bullhorn, Knowledge Vault, "RC" (as in "Tractorbeam + RC" check-ins), Sweta, Better Jobs (WRONG - see Carlyle)

**File types:** CoE product feedback, portfolio assessment surveys, maturity assessments, deal team interview context, weekly PortCo meeting transcripts, Bullhorn app logs, Waud logos and brand assets (NOT in Tractorbeam/brand)

### Carlyle (~/Documents/Tractorbeam/clients/carlyle/)
**Also known as:** CSE, Carlyx, Tempus

**Keywords:** Carlyle, CSE, Carlyx, Tempus, AlpInvest, CIM (Carlyle Investment Management), LPA, CW (contract workspace documents), Dbell, rules-comparison, Better Jobs Dashboard, EDCI, employee sentiment

**File types:** Balance sheets (audited/unaudited), contract extraction data, LPA results, subscription/vendor document lists, infrastructure standards (AWS config, naming conventions, resource tagging), Tempus LMS screenshots, VPC/infrastructure code screenshots, Linear workspace screenshots, financial modeling data

**Common mistakes:**
- Balance sheets from Carlyle are client work, NOT personal Tax & Finance documents
- CSE docs are Carlyle infrastructure standards, not Tractorbeam internal
- "rules-comparison" and "Dbell" files are Carlyle, not Waud
- Better Jobs Dashboard is Carlyle (has EDCI benchmarks), not Waud

### Linden (~/Documents/Tractorbeam/clients/linden/)
**Also known as:** Linden Capital Partners

**Keywords:** Linden, Quest Analytics, US Fertility, "Post MMM", "Linden AI Update"

**File types:** Client assessment folders (dated like "2025-06-16 Quest Analytics"), AI update presentations, OneDrive data extraction deliverables (Financial Statement Review, IC Memo Extraction, RepRisk)

### Other existing client folders
- avathon, barcode, bluej, rcvc, tempus — already exist under ~/Documents/Tractorbeam/clients/

## Corrections Log (Things I Got Wrong)

1. **Apple Developer Program License Agreement** — Filed to Tax & Finance. WRONG: It's a Tractorbeam corporate document (Tractorbeam's Apple developer account).
2. **Balance sheets (0_Audited, 0_Unaudited, Annual Audited, Quarterly Unaudited)** — Filed to Tax & Finance. WRONG: These are Carlyle client documents.
3. **Waud logos** — Initially tried to put in Tractorbeam/brand. WRONG: Client brand assets go in the client folder (waud/).
4. **Social media assets (X Banner, LinkedIn cover)** — Initially tried to put in ~/Documents/Social Media. WRONG: These were Tractorbeam brand assets, not Wade's personal social media.
5. **Fonts (Inter, Source Serif 4)** — Tried to put in Tractorbeam/brand. User said to trash them.
6. **Terraform/ECS artifacts** — Tried to put in Tractorbeam/corporate. User said to trash them.
7. **GCP service account key** — Tried to put in Tractorbeam/corporate. WRONG: Goes in ~/Developer/Tractorbeam/internal-infra.
8. **Salesforce CSV** — Assumed Tractorbeam corporate. WRONG: It was Carlyle fund agreement data.
9. **vuln-demo HTML files** — Tried to put in OSINT. User said to trash them.
10. **Tailscale logo** — Tried to put in okta-app-logos. User said to trash it.
11. **Reference SOWs/contracts** — Initially mixed up reference examples with actual Tractorbeam agreements. Most contracts from big companies (Accenture, Deloitte, BCG, AT&T, etc.) are reference examples, not Tractorbeam's own agreements.
12. **SAML metadata XML** — Initially kept it. User said trash (config file).

## General Heuristics

- **If it's from a big consulting/tech company** (Accenture, Deloitte, BCG, SAP, etc.) it's almost certainly a **reference example**, not a Tractorbeam document.
- **If it has Carlyle entity names** (AlpInvest, CIM, CSE) it's a **Carlyle client doc**.
- **If it mentions WCP, CoE, PortCo, RCVC** it's a **Waud client doc**.
- **If it mentions Quest Analytics, US Fertility, or Linden** it's a **Linden client doc**.
- **Product logos** (recognizable SaaS tools) likely go in **okta-app-logos** on Desktop.
- **DMGs, PKGs, VSCode extensions (.vsix), installers** — generally trash.
- **3D printing files (.stl, .3mf, .step)** — trash.
- **Random config files (.vcf, .eml, .ics, tsconfig)** — generally trash.
- **Hash-named files** — usually VS Code extension downloads or other installer artifacts. Check with `file` or `unzip -l` before trashing.
- **macOS screenshots** may have Unicode non-breaking spaces (U+202F) before AM/PM. Use glob patterns (`Screenshot*.png`) instead of typing the filename to handle this.
