# 0pinion Design System

Version: 1.0

---

# Design Philosophy

0pinion is not another social media app.

The design should feel like:

* Reading a newspaper
* Participating in a debate club
* Browsing a knowledge forum

Not:

* Watching TikTok
* Scrolling Instagram
* Consuming entertainment content

The interface should encourage thinking rather than scrolling.

---

# Design Principles

## Ideas Over Visuals

Opinions are the primary content.

Visual elements should never compete with ideas.

---

## Monochrome First

The entire product is built around black and white.

No colorful interfaces.

No gradients.

No flashy animations.

---

## Minimalism

Every element must have a purpose.

Remove anything that does not contribute to discussion.

---

## Calm Interface

The app should feel quiet.

No dopamine-driven design.

No attention traps.

No aggressive notifications.

---

# Color System

## Light Mode

Background

```css
#FFFFFF
```

Primary Text

```css
#000000
```

Secondary Text

```css
#666666
```

Borders

```css
#E5E5E5
```

Cards

```css
#FAFAFA
```

---

## Dark Mode

Background

```css
#000000
```

Primary Text

```css
#FFFFFF
```

Secondary Text

```css
#A0A0A0
```

Borders

```css
#333333
```

Cards

```css
#111111
```

---

# Forbidden Colors

Never use:

* Red
* Green
* Blue
* Purple
* Yellow
* Orange

Exception:

Small system status indicators if absolutely required.

---

# Typography

## Font Family

Primary

Inter

Fallback

System Sans Serif

---

## Font Scale

### Display

48px

Used for:

* Splash Screen

---

### Heading 1

32px

Used for:

* Screen Titles

---

### Heading 2

24px

Used for:

* Opinion Titles

---

### Body

16px

Used for:

* Opinion Content

---

### Caption

14px

Used for:

* Metadata

---

# Logo

## Wordmark

0pinion

Use:

```text
0pinion
```

The zero is always numeric.

Never replace it with O.

---

# Avatar System

Users cannot upload profile pictures.

Generated avatars only.

Requirements:

* Monochrome
* Geometric
* Anonymous-friendly

Examples:

* Abstract faces
* Shapes
* Patterns

---

# Navigation

## Bottom Navigation

```text
Home
Search
Create
Live
Profile
```

Always visible.

Maximum 5 items.

---

# Home Screen

## Tabs

```text
For You

Cooking

Latest
```

---

## Opinion Card

Structure:

```text
Opinion Title

Opinion Preview

Username

Zeroes

Support Count
Oppose Count

Join Debate
```

---

# Opinion Detail Screen

Layout

```text
Title

Author

Zeroes

Content

Support
Oppose
Question
```

Debate sections appear directly below content.

---

# Debate Design

Each response appears as:

```text
Avatar

Username

Argument

Timestamp
```

Actions:

```text
Reply

Report
```

No emojis.

No reactions.

No GIFs.

---

# Zeroes Design

Example:

```text
0technology

12,450 Opinions
```

Users can:

```text
Join Zero
```

Zeroes function as idea communities.

---

# Cooking Design

Cooking replaces Trending.

Label:

```text
COOKING
```

No fire emoji.

No color indicators.

Visual style:

* Bold border
* Monochrome badge

Example:

```text
[ COOKING ]
```

---

# Create Opinion Screen

Fields

```text
Title

Content

Select Zeroes

Post Anonymously
```

Primary Action

```text
Post Opinion
```

---

# Live Room Design

Text-only.

Layout:

```text
Room Title

Participants

Messages

Input Field
```

No:

* Voice
* Video
* Screensharing

---

# Buttons

Primary

Black background

White text

Rounded corners

```css
border-radius: 12px;
```

---

Secondary

White background

Black border

Black text

---

# Cards

Border Radius

```css
16px
```

Padding

```css
16px
```

Shadow

Very subtle or none.

Prefer borders over shadows.

---

# Animations

Minimal.

Allowed:

* Fade In
* Fade Out
* Slide Transition

Avoid:

* Bounce
* Scale Pop
* Confetti
* Excessive Motion

---


# Reputation Design

Display:

```text
Reputation: 1240
```

No badges.

No crowns.

No influencer symbols.

Reputation should feel earned, not gamified.

---

# Accessibility

Requirements:

* WCAG AA compliance
* Large touch targets
* Screen reader support
* Adjustable text sizes

---

# User Experience Rules

Always prioritize:

1. Clarity
2. Readability
3. Discussion
4. Learning

Never prioritize:

1. Virality
2. Addiction
3. Popularity
4. Influencer culture

---

# Design Statement

0pinion should feel like a modern digital forum where ideas matter more than appearances, communities matter more than personalities, and debate matters more than engagement.
