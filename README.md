# Grizzly

A small iOS app for logging your writing progress straight to [TrackBear](https://trackbear.app), using TrackBear's [public API](https://help.trackbear.app/api/).

## Features (v1)

- **Log Progress** — pick a project, choose a measure (words, time, pages, chapters, scenes, lines), enter a count, and submit. Supports both "add to total" and "set as new total" updates.
- **Projects** — see your TrackBear projects with their running totals.
- **History** — browse and delete recent progress entries.
- **Settings** — paste in your TrackBear API token (stored in the Keychain, never in plain text) and test the connection.

## Setup

1. Open `Grizzly.xcodeproj` in Xcode 16 or later (requires the iOS 18 SDK).
2. Build and run on a simulator or device (bundle ID `ToastPhysics.Grizzly`).
3. In TrackBear, go to **Account → API Keys** (or visit [trackbear.app/account/api-keys](https://trackbear.app/account/api-keys)) and create a token.
4. On first launch, paste that token into Grizzly's settings screen and tap **Connect**.

## Project layout

```
Grizzly/
  GrizzlyApp.swift          entry point
  AppSettingsStore.swift    API token + base URL (Keychain-backed)
  WritingDataStore.swift    shared cache of projects/tallies for the session
  Models/                   Codable types matching the TrackBear API
  Networking/               URLSession-based API client + Keychain wrapper
  Views/                    SwiftUI screens (Log, Projects, History, Settings)
```

## API notes

- Base URL: `https://trackbear.app/api/v1`
- Auth: `Authorization: Bearer <token>` header, plus a descriptive `User-Agent` (TrackBear asks integrators to identify themselves).
- Full reference: https://help.trackbear.app/api/
