# GYM FEATURE SCOPE

This document consolidates all current plans and decisions for the Gym feature. Use this as the single source of truth for Gym UI/UX, features, and integration with chat/voice. This is UI-first; implementation will follow in phases. No data model changes are included at this stage.

References (existing project docs):
- notes/CURRENT_STATUS.md
- notes/CHAT_SESSION_NOTES.md
- notes/AI_INTEGRATION_PROGRESS.md
- scope/PROJECT_SCOPE.md
- scope/CURRENT_STATUS.md
- scope/QUICK_REFERENCE.md
- scope/TECHNICAL_GUIDE.md
- scope/CONCEPT_OVERVIEW.md

Competitive references:
- Gravitus: https://gravitus.com/
- Hevy: https://www.hevyapp.com/

Constraints and principles:
- No data model changes for now; compute from existing logs and attach any extras via non-breaking metadata if needed
- Light theme and visuals consistent with Tasks/Reminders UI
- All forms/widgets must be responsive per project rules
- Social/community features deferred (can be added later)

---

## A. Navigation and High-Level Structure

Bottom toolbar tabs:
1) Log (Today)
2) Templates
3) History
4) Analytics
5) Running

Floating actions:
- Center: Scan machine (camera → OCR/vision → suggest exercise → confirm → auto-start)
- Right: Mic (voice-to-chat input for logging sets/exercises)

Top bar (Log tab):
- Start/End workout, Add exercise, Rest timer status chip

---

## B. Log (Today)

Exercise card layout:
- Media box (reserved for images/animations)
  - Aspect ratio: 1:1, large placeholder (e.g., 240px phone / 360px tablet max height)
  - Placeholder: shimmer + "Add media" label; tap to open a detail viewer (planned)
- Exercise title
- Set rows: reps, weight (kg), RPE (optional), quick add/edit/delete
- Badges: PR, best set indicators (placeholder states)
- Notes: small text field per exercise
- Rest timer chip: shows remaining time; tap for bottom sheet with presets (60/90/120s)

Optional set types (UI ready, logic later): warmup/drop/failure/superset tagging

---

## C. Templates

- Saved routines (e.g., Push/Pull/Legs, Upper/Lower, Full Body)
- Create template (name, exercises, default sets/reps/weights)
- Apply template to start a session
- Thumbnail list/grid with small media previews (96px squares)

---

## D. History

- List of past workouts (date, title, key exercises, duration)
- Detail view per workout: exercises, sets/reps/weight, notes, PR badges
- Per-exercise history: quick access from exercise name

---

## E. Analytics (Phase 2 UI placeholders now)

Metrics:
- PRs: per exercise and per muscle group (heaviest set, best reps, 1RM estimate)
- Consistency: weekly streaks, weeks trained, sessions/week
- Volume & frequency: per timeframe (week, month, custom), per exercise, per muscle group
- Trends: this month vs last month; 4/12-week views; day-of-week breakdown
- Muscle group analysis: distribution to avoid imbalances

UI:
- Filter bar: timeframe, muscle group, exercise selector
- Cards: PRs, Consistency, Volume, Frequency, Trends
- Charts placeholders (wire later)

---

## F. Running

Live session UI:
- Start / Pause / End controls
- Live map route (placeholder), distance, pace, time, splits
- Summary screen after End: route preview, totals, averages, best split

Analytics:
- Weekly/monthly totals, average pace/time, run count

---

## G. Scan Machine Flow

- Capture machine photo → OCR (read placard) → image labeling for top matches
- Result sheet: recognized name, top 3 exercise suggestions, media preview, confidence
- Actions: Start workout with chosen exercise; switch exercise if needed
- Memory: remember mapping (photo signature → exercise) locally for instant future matches
- Privacy: on-device by default; optional cloud assist later (opt-in)

---

## H. Media Strategy (Images/Animations)

- Accepted formats: MP4 (preferred), WebP; GIF discouraged
- Placement: exercise card (inline preview), detail sheet (hero media), templates/history thumbnails, scan confirmation
- Behavior: lazy-load, cache, autoplay muted in detail view; tap-to-play on cards; pause off-screen
- Consistent style: 1:1 aspect, white background, single side view
- Naming examples:
  - assets/exercises/animations/lower_body/barbell_back_squat.mp4
  - assets/exercises/thumbnails/lower_body/barbell_back_squat.webp

---

## I. Chat/Voice Integration

Intents (examples):
- start_workout, end_workout
- add_exercise, create_exercise, add_set
- start_run, end_run
- analytics queries

Sample phrases:
- "Start bench: 10 reps 25 kg; second set 10 reps 50 kg"
- "Create exercise: Seated Smith Shoulder Press"
- "What did I do last Monday on chest?"
- "Compare this month to last month"
- "Start a run"

Behavior:
- Chat/voice → parse → append to current session (or create new)
- Analytics queries return summaries and can open Analytics tab with filters applied

---

## J. Phased Rollout

Phase 1 (UI only):
- Build static UI for all tabs (Log, Templates, History, Analytics placeholders, Running)
- Include media boxes and placeholders; no logic, no schema changes

Phase 2 (Core wiring):
- Set logging, rest timers, templates apply, history details
- Chat/voice: start_workout, add_exercise, add_set, end_workout

Phase 3 (Analytics & Running):
- Compute PRs, volume, consistency; charts
- Running live tracking and summary
- Chat analytics queries

Phase 4 (Enhancements):
- Scan machine recognition flow
- Supersets/giant sets and advanced set types
- Adaptive progression/deloads (optional)

---

## K. Out of Scope (for now)

- Social/community (leaderboards, feeds)
- Cloud media recognition by default (opt-in later)
- Data model changes (re-evaluate after wiring Phase 2)

---

## L. Cross-References and Notes

- Chat parser already supports gym phrases in a basic form (see notes/CHAT_SESSION_NOTES.md). This scope expands on intents and UI/UX.
- Keep UI consistent with app-wide spacing, shadows, and light theme.
- All components must remain responsive on mobile/tablet per rules/FOLDER_STRUCTURE.md. 

---

## M. Changelog — Aug 9, 2025

- **Workout detail UX**
  - Finish action moved into `Today's session` header; collapse chevron and subtitle hidden during live session
  - Removed interim summary row to reduce card height
  - Set rows: flexible columns (Previous 3, Weight 2, Reps 1), inline editing with unit toggle
  - Headers aligned to left edges of Weight/Reps inputs; no column borders; consistent spacing so checkmark doesn’t crowd inputs
- **Next**
  - FAB Quick Actions: unified list with filters and quick picks
  - Analytics and Running placeholders to be scaffolded 