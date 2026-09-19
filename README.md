# Grizzly

A small iOS app for logging your writing progress straight to [TrackBear](https://trackbear.app), using TrackBear's [public API](https://help.trackbear.app/api/). Independent project, not affiliated with the TrackBear team.

## Features

- **Log Progress** — pick a project, choose a measure (words, time, pages, chapters, scenes, lines), enter a count, and submit. Supports both "add to total" and "set as new total" updates. Logging a session fires a small confetti celebration.
- **Projects** — see your TrackBear projects as cards with running totals; tap one for a full totals breakdown and its complete entry history.
- **History** — everything you've logged, grouped into Today / Yesterday / This Week / Earlier, with swipe-to-delete.
- **Leaderboards** — view boards you're part of, join a new one by code, and see a leaderboard's cumulative-progress chart (scrollable, full-screen in landscape) and ranked standings.
- **Settings** — paste in your TrackBear API token (stored in the Keychain, never in plain text), test the connection, and sign out. Includes step-by-step instructions for getting a token.
- **Demo Mode** — explore the whole app with sample data, no TrackBear account or token required (also what App Review uses).

See [HELP.md](HELP.md) for the end-user-facing walkthrough of all of this.

## Setup

1. Open `Grizzly/Grizzly.xcodeproj` in Xcode 16 or later (targets iOS 18+).
2. Build and run on a simulator or device (bundle ID `ToastPhysics.Grizzly`).
3. On first launch, either:
   - Tap **Try the Demo** to explore with sample data, no account needed, or
   - Get a TrackBear API token (**Account → API Keys** at [trackbear.app/account/api-keys](https://trackbear.app/account/api-keys) — Settings has full step-by-step instructions) and paste it in, then tap **Connect**.

## Project layout

```
Grizzly/
  GrizzlyApp.swift          entry point
  AppSettingsStore.swift    API token + base URL (Keychain-backed) + demo mode flag
  WritingDataStore.swift    shared cache of projects/tallies/leaderboards for the session
  DemoData.swift            static sample data backing Demo Mode
  Models/                   Codable types matching the TrackBear API
  Networking/               URLSession-based API client + Keychain wrapper
  Views/
    LogProgressView, ProjectsView, ProjectDetailView, HistoryView
    LeaderboardsView, LeaderboardDetailView, LeaderboardChartView, JoinLeaderboardView
    SettingsView, ConfettiView, ViewModifiers (shared styling: glass cards,
    accent-edge cards, the warm background wash, stat numbers, color palette)
```

## API notes

- Base URL: `https://trackbear.app/api/v1`
- Auth: `Authorization: Bearer <token>` header, plus a descriptive `User-Agent` (TrackBear asks integrators to identify themselves).
- Full reference: https://help.trackbear.app/api/
- A few gotchas the docs don't make obvious (see comments at the call sites for details): tally creation requires `note` and `tags` to be present even when empty — a Swift `nil` that gets omitted from the JSON body fails validation; the `works` tally-list filter needs bracket notation (`works[]=<id>`) even for a single id, or it's parsed as a scalar and rejected.
