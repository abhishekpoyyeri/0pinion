# 0pinion — App & Design Analysis

## 1. App Idea & Vision
**0pinion** is a text-first, monochrome social platform built around exchanging opinions and meaningful debates rather than doomscrolling, creator worship, or visual stimulation. 

**Tagline:** Debate, Not Doomscroll.

**Core Philosophy:** 
- **Ideas Over People:** Opinions are judged purely on their quality. The platform removes followers, following, and influencer mechanics.
- **Debate Over Engagement:** It prioritizes structured, constructive discussion instead of screen-time maximization.
- **Privacy First:** Users can participate anonymously.
- **Community Driven:** Content is categorized into "Zeroes" (topic communities like `0technology` or `0science`) rather than personal profiles.

---

## 2. Design System & Aesthetics
The app uses a strict **Monochrome First** design philosophy to ensure visual elements never compete with ideas. The interface is meant to feel like reading a newspaper or participating in a debate club.

### Color System (Strictly B&W)
Implemented in `lib/core/theme/app_colors.dart`:
- **Light Mode:** Background (`#FFFFFF`), Primary Text (`#000000`), Secondary Text (`#666666`), Borders (`#E5E5E5`), Cards (`#FAFAFA`)
- **Dark Mode:** Background (`#000000`), Primary Text (`#FFFFFF`), Secondary Text (`#A0A0A0`), Borders (`#333333`), Cards (`#111111`)

**Forbidden Colors:** 
Red, Green, Blue, Purple, Yellow, Orange are strictly forbidden. There are no gradients and no flashy animations.

### Visual Effects & Layout
- **Minimalism:** Every element must have a purpose. No dopamine-driven design, no attention traps.
- **Cards:** Clean cards with a 16px border radius, 16px padding. Prefer borders over shadows.
- **Avatars:** No user-uploaded profile pictures. Avatars are system-generated (monochrome, geometric).
- **Animations:** Kept minimal (Fade In, Fade Out, Slide). Bounces, scale pops, and confetti are prohibited.

---

## 3. Typography & Fonts
The typography is designed for supreme readability and clarity. As implemented in `lib/core/theme/app_typography.dart`:

- **Headlines (Display, H1, H2, H3, Buttons):** `Space Grotesk`
  - *Example:* Display is 48px, bold, with -1.5 letter spacing.
- **Body & Labels:** `Inter` (via Google Fonts)
  - *Example:* Body is 16px regular, Captions are 14px, Labels are 12px.

---

## 4. Implemented Features & Core Logic
Based on the `lib/features` architecture, the Flutter application is composed of the following distinct modules:

- **Opinion & Debate System (`lib/features/opinion`):** The core content engine. Opinions are posted and instantly open up distinct debate threads:
  - `Support`: Arguments validating the opinion.
  - `Oppose`: Arguments challenging the opinion.
  - `Question`: Clarifications and inquiries.
- **Zeroes / Communities (`lib/features/community`):** Topic-based communities (e.g., `0technology`, `0startup`).
- **Home Feed (`lib/features/feed`):** The personalized feed, including tabs for 'For You', 'Cooking' (trending), and 'Latest'.
- **Live Rooms (`lib/features/live`):** Real-time, text-only discussion rooms (strictly no voice, video, or screen sharing).
- **Profile System (`lib/features/profile`):** User profiles containing generated avatars and calculated Reputation Scores.
- **Search (`lib/features/search`):** Full-text search functionality across opinions, Zeroes, and users.
- **Authentication & Onboarding (`lib/features/auth`, `lib/features/onboarding`):** User setup and login handling via Supabase and Google Sign-in.
- **Reporting (`lib/features/report`):** Moderation tools for reporting spam and abuse.

---

## 5. Tech Stack (Implemented)
- **Frontend / Mobile App:** Flutter & Dart
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter
- **Backend & DB:** Supabase (`supabase_flutter`) & PostgreSQL (with Full-Text Search)
- **Authentication:** Supabase Auth + Google Sign In
- **Realtime:** Supabase Realtime
- **Networking:** Dio
- **Local Storage:** Hive, Flutter Secure Storage
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Monitoring & Analytics:** Sentry (Errors), PostHog (Analytics)
- **Third-Party Services:** OpenAI (Moderation & Summaries)
