# Design System: 0pinion
**Project ID:** 12994651394271601218
**Design System ID:** assets/13244779772264007188

## 1. Visual Theme & Atmosphere
Quiet, editorial, and deliberate. The interface evokes the calm focus of reading a broadsheet newspaper or sitting in a university debate hall. Every pixel serves the exchange of ideas. The aesthetic is "premium utilitarian" — stripped of decoration, rich in typographic hierarchy. Monochrome palette with generous whitespace creates breathing room for dense textual content. The mood is intellectual, unhurried, and confident.

## 2. Color Palette & Roles
| Name | Hex | Role |
|------|-----|------|
| Pure Canvas | `#FFFFFF` | Background, primary surface |
| Warm Parchment | `#FAFAFA` | Card surfaces, elevated containers |
| Ink Black | `#111111` | Primary text, primary buttons, wordmark |
| Charcoal Whisper | `#666666` | Secondary text, metadata, timestamps |
| Fog Divider | `#E5E5E5` | Borders, dividers, input strokes |
| Absolute Black | `#000000` | Custom seed, accent anchor |

**Forbidden:** Red, green, blue, purple, yellow, orange. Exception: minimal system status indicators only.

## 3. Typography Rules
- **Headlines (Space Grotesk):** Geometric sans-serif with distinctive character. Tight tracking (`-0.02em`), tight line-height (`1.1`). Used at 48px (display), 32px (H1), 24px (H2). Weight: SemiBold to Bold.
- **Body & UI (Geist):** Clean, modern sans-serif with excellent readability. 16px body, 14px caption. Line-height `1.6` for body text. Weight: Regular for body, Medium for UI labels.
- **Monospace (Geist Mono):** Used sparingly for counts, reputation numbers, and metadata.

## 4. Component Stylings
* **Primary Buttons:** Solid Ink Black (`#111111`) background, white text, generously rounded corners (`12px`). No shadow. Hover: subtle shift to `#333333`. Active: `scale(0.98)`.
* **Secondary Buttons:** White background, Ink Black border (`1px solid`), Ink Black text. Clean outlined appearance.
* **Cards/Containers:** Warm Parchment (`#FAFAFA`) background, Fog Divider border (`1px solid #E5E5E5`), gently rounded corners (`16px`), internal padding `16px`. No shadow — flat and editorial.
* **Inputs/Forms:** White background, Fog Divider stroke, subtly rounded (`8px`). Focus state: Ink Black border.
* **Chips/Tags (Zeroes):** Pill-shaped, Fog Divider border, small typography. Zeroes always prefixed with `0`.
* **Bottom Navigation:** 5 items, always visible, clean outlined icons, Ink Black active state.

## 5. Layout Principles
- Generous vertical whitespace between content blocks
- Content width constrained for reading comfort
- Cards separated by consistent `12px` gaps
- Flat, no elevation hierarchy through shadows
- Bottom navigation fixed, providing persistent wayfinding
- Opinion cards are the atomic unit — scannable yet information-dense

## 6. Design System Notes for Stitch Generation
When generating screens for 0pinion, always include:
- Monochrome palette only: #FFFFFF, #FAFAFA, #111111, #666666, #E5E5E5, #000000
- Space Grotesk for headlines, Geist for body text
- All buttons are rounded (12px), black bg with white text for primary
- Cards have 1px solid #E5E5E5 border, 16px border-radius, #FAFAFA background
- Bottom navigation with 5 icons: Home, Search, Create (+), Live, Profile
- NO colors, NO emojis, NO gradients, NO heavy shadows
- The wordmark is "0pinion" (zero, not O)
- Avatars are monochrome geometric shapes, never photos
- Reputation is shown as a plain number, no badges or crowns
