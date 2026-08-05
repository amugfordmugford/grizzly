# Grizzly Help

Grizzly is a companion app for [TrackBear](https://trackbear.app) — it lets you log your writing progress and check leaderboards without opening a browser.

## Getting Started

Grizzly doesn't have its own account system. It connects directly to your existing TrackBear account using an **API key**.

### Getting your API key

1. [Log in to your TrackBear account](https://trackbear.app).
2. Tap your name in the top right corner and select **API Keys** from the menu.
3. Tap **New**.
4. Give your key a name, and choose how long it should stay valid. If it expires, you'll need to create a new one to keep Grizzly connected.
5. Tap **Create**.
6. Copy the API key it shows you — it usually starts with `tb.`
7. Open Grizzly, paste the key into the **API Token** field on the Settings tab (or the setup screen on first launch).
8. Tap **Connect** (or **Test Connection & Save**). You should see a green checkmark that says "Connected."

Your key is stored securely in the device Keychain — it's never sent anywhere except directly to TrackBear.

## Log

The **Log** tab is for quickly recording a writing session:

- **Project** — pick which TrackBear project you're logging progress for.
- **Measure** — words, time, pages, chapters, scenes, or lines.
- The count field — how much you're adding. Toggle **"This is my new total, not an addition"** if you'd rather set an absolute total instead of adding to your existing one (useful if you're catching up on progress you tracked elsewhere).
- **Date** — defaults to today, but you can log for a past day too.
- **Note** — optional, for context on the entry.

Tap **Log Progress** to submit. If your device keyboard is covering the tab bar, tap **Done** above the keyboard, or swipe down on the form to dismiss it.

## Projects

Lists all your TrackBear projects with a quick summary of total progress per measure (words, pages, etc. logged so far).

Tap a project to see:
- A full totals breakdown
- Its complete entry history, with swipe-to-delete for corrections

Pull down to refresh.

## History

Every entry you've logged, grouped into **Today**, **Yesterday**, **This Week**, and **Earlier**. Swipe left on an entry to delete it.

## Leaderboards

Shows leaderboards you're already part of.

- Tap **Join** (top right) and enter a join code to find and join a new leaderboard.
- Tap a leaderboard to see:
  - **Progress** — a chart of everyone's cumulative progress over time. Each participant gets a consistent color, matched to their entry in Standings below. If the board covers more than two weeks, drag the chart left/right to scroll through it.
  - **Standings** — everyone's progress toward their goal, ranked, with gold/silver/bronze badges for the top 3.
- **Rotate your device to landscape** while viewing a leaderboard to expand the chart to fill the screen.

## Settings

- Update or replace your API key here at any time.
- **Sign Out** removes your key from this device (you'll need to paste it back in to reconnect).

## Troubleshooting

**"Add your TrackBear API token in Settings first."**
You haven't entered a key yet, or it was removed. Go to Settings and follow the steps above.

**Connecting fails / no green checkmark.**
Double-check you copied the whole key (it should start with `tb.`), and that it hasn't expired — expired keys need to be replaced with a new one from TrackBear.

**"TrackBear returned an error (400)..." or similar.**
This means TrackBear rejected the request — usually a sign something about the data doesn't match what's expected (for example, an invalid or expired join code when joining a leaderboard). The message after the error code describes what specifically was rejected.

**A project or leaderboard I expect to see isn't listed.**
Pull down on the list to refresh. If it's still missing, confirm it actually exists on your TrackBear account at [trackbear.app](https://trackbear.app).

## Privacy

Grizzly has no servers or analytics of its own. It only talks directly to TrackBear's API using the key you provide, which is stored in your device's Keychain.

## Contact

Made by Andrew. Questions or feedback: [jointcommand@icloud.com](mailto:jointcommand@icloud.com)
