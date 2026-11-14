# CINEORA UI/UX Design System

> **Brand Identity:** CINEORA  
> **Slogan:** "Your Cinema. Everywhere."  
> **Design Philosophy:** Dark Cinema Aesthetic, immersive edge-to-edge typography, crisp high-contrast controls, zero visual distraction during playback.

---

## 1. Color Palette (Dark Cinema Theme)

```
Primary Crimson:   #E50914 (Action buttons, brand accents, active indicators)
Secondary Crimson: #B20710 (Pressed states, gradients, subtle glow)
Background:        #090909 (Ultra-dark OLED cinema background)
Surface:           #151515 (Cards, navigation bars, bottom sheets)
Surface Elevated:  #212121 (Modals, popup menus, active chips)
Border / Divider:  #292929 (Subtle 1px boundaries)
Text Primary:      #FFFFFF (Headings, titles, high-emphasis text)
Text Secondary:    #A3A3A3 (Subtitles, metadata, timestamps)
Text Tertiary:     #737373 (Disabled states, captions)
Success:           #22C55E (Completed watch, active subscriptions)
Warning:           #F59E0B (Expiring licenses, notice badges)
Error:             #EF4444 (Playback failure, alert toasts)
```

---

## 2. Typography Scale

- **Display 1 (Hero Title):** Inter / Roboto, 32px, Bold, Line-height 38px
- **Heading 1 (Section Titles):** 20px, Semi-Bold, Line-height 26px
- **Heading 2 (Card Titles):** 16px, Medium, Line-height 22px
- **Body 1 (Synopsis, Descriptions):** 14px, Regular, Line-height 20px
- **Body 2 (Metadata, Labels):** 12px, Regular, Line-height 16px
- **Caption (Badge, Tags):** 10px, Medium, Letter-spacing 0.5px, Uppercase

---

## 3. UI Components

### 3.1. Hero Carousel Banner
- **Aspect Ratio:** 16:9 on tablets / landscape, 3:4 on portrait mobile with bottom gradient fade to `#090909`.
- **Badges:** Quality pill (`4K HDR` / `1080p`), Age rating (`16+` / `18+`), Vietnamese audio badge (`Thuyết minh` / `Phụ đề`).
- **Action Buttons:**
  - "Xem ngay" (Play Button): Primary Crimson background, white text with Play icon.
  - "Trailer": Surface Elevated background with 1px border.
  - "+ Danh sách": Bookmark toggle icon.

### 3.2. Movie Card
- **Aspect Ratio:** 2:3 standard vertical cinema poster.
- **Corner Radius:** 8px.
- **Shadow:** Elevation 2 with smooth black shadow.
- **Overlay:** Rating chip top-right (Star icon + `8.5`), Episode count badge bottom-left for series.

### 3.3. Continue Watching Card
- **Aspect Ratio:** 16:9 horizontal thumbnail with episode still.
- **Progress Bar:** 3px crimson bar at the bottom showing exact percentage watched.
- **Quick Action:** Center overlay play button to instantly resume from last position.

### 3.4. Video Player Overlay UI
- **Control Bar:** Auto-hides after 3.5 seconds of inactivity.
- **Top Bar:** Back button, movie/episode title, AirPlay / Cast button, Settings (Quality / Subtitle / Audio).
- **Center Controls:** 10s Rewind, Play/Pause toggle (64px crimson circle), 10s Fast-Forward.
- **Bottom Bar:** Current time, custom scrubbable slider (crimson thumb and active track), total duration, Episode picker button, Screen lock toggle, Fullscreen toggle.

---

## 4. Intro & Splash Experience
1. **0.0s - 0.4s:** Pure pitch black `#090909` screen.
2. **0.4s - 1.2s:** CINEORA film-frame play symbol fades in with a subtle crimson neon glow and scale up from 90% to 100%.
3. **1.2s - 1.8s:** "CINEORA" typographic logotype wipes in with the tagline "Your Cinema. Everywhere."
4. **1.8s - 2.0s:** Smooth crossfade transition into the Home Screen carousel.
