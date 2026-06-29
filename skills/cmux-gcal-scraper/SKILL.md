---
name: gcal-week-scraper
description: >-
  Scrape Google Calendar meeting events week-by-week from a browser open inside
  cmux, then save filtered per-week CSVs. Use this whenever the user wants to
  pull, export, archive, or collect their calendar meetings/events over a date
  range (e.g. "scrape my calendar for the last year", "export accepted meetings
  per week", "grab the events for the week of June 7", "collect calendar data
  for self-review / performance appraisal") WITHOUT Google API access, OAuth, or
  a GCP project. Relevant any time Google Calendar is already logged in inside a
  cmux browser surface but API/ICS paths are unavailable.
---

# Google Calendar week scraper (via cmux browser)

This skill captures a workflow for harvesting Google Calendar events when the
"normal" programmatic routes are closed:

- **Google Calendar API** needs OAuth credentials from a GCP project — blocked
  when the user's Workspace admin disallows project creation / third-party apps.
- **Secret ICS feed** is usually admin-disabled on enterprise calendars and only
  covers a limited window.
- **macOS Calendar.app / EventKit** depends on flaky local sync.

The reliable fallback: the user already has Google Calendar **open and logged in
inside a cmux browser surface**. We drive that surface with the cmux CLI, scrape
the rendered week grid's DOM, and parse the event chips into clean CSV. No
credentials, no API.

## Critical prerequisite: must run inside cmux

The cmux socket (`/tmp/cmux.sock`) enforces a peer-credential check — it **only
answers processes that cmux itself spawned**. A shell running under `tmux` (even
if displayed inside a cmux pane) is reparented to `launchd`, fails the check, and
every cmux command returns empty (the CLI swallows the `ERROR: Access denied —
only processes started inside cmux can connect`).

So before anything else, confirm access:

```bash
python3 scripts/gcal_lib.py >/dev/null 2>&1   # importable sanity
/Applications/cmux.app/Contents/Resources/bin/cmux --json list-workspaces
```

If `list-workspaces` returns JSON, you're good. If it returns nothing, the
session is not a cmux child — ask the user to **stop and resume the agent
session from a cmux terminal surface (not tmux)**, then retry. All scripts call
`gcal_lib.check_access()` and will print a clear error if access is missing.

## Workflow

1. **Confirm the user has Google Calendar open** in a cmux browser tab, logged
   in, on the week they want as the starting point.
2. **Confirm cmux access** (above).
3. **Decide the range and filter.** The user typically wants a date range (e.g.
   a full year) and only `Accepted` meetings. Weeks are Sunday-start; a range's
   last week ends on its Saturday.
4. **Run the range scraper** (it auto-detects the calendar surface, navigates
   each week, waits for render, scrapes, and writes one CSV per week):

   ```bash
   cd scripts
   python3 scrape_range.py --start 2026-01-04 --end 2026-05-24 \
       --status Accepted --outdir ./data/calendar
   ```

   It prints a per-week progress table (`Week start | Total | Kept | File`) and
   flags any **zero-TOTAL** week — that means the grid hadn't rendered when
   scraped, not an empty week.
5. **Re-scrape any zero-TOTAL week** with the single-week helper:

   ```bash
   python3 scrape_week.py --week 2026-03-01 --status Accepted --outdir ./data/calendar
   ```
6. **Report progress to the user** as a table of `Week start → Accepted count`,
   and call out weeks with suspiciously low counts (they're usually genuine
   leave/holiday weeks since TOTAL is healthy, but worth a manual look).

For long ranges the run takes several minutes (≈10-15s/week). Run it in the
background and stream the progress table.

## Output format

One CSV per week named `gcal_week_<status>_<dd>_<month>_<year>.csv`
(e.g. `gcal_week_accepted_04_january_2026.csv`). Columns:

```
date,day,start,end,title,status,location
2026-06-02,Tue,2:30pm,3pm,RCA sync,Accepted,
```

- `date` is ISO `YYYY-MM-DD`; `day` is the abbreviated weekday.
- `status` is the RSVP state (`Accepted`/`Declined`/`Tentative`/`Needs RSVP`);
  blank means a self-created block (focus time, holds) with no RSVP.
- Full Zoom URLs / room names are preserved in `location`.

Note: the output directory's `.gitignore` ignores `*.csv`, so scraped weeks
are local/untracked by default. Add a `!gcal_week_*.csv` exception only if the
user wants them version-controlled.

## Scripts (in `scripts/`)

- **`gcal_lib.py`** — shared helpers: cmux subprocess wrapper, `check_access()`,
  `find_calendar_surface()`, week navigation, `scrape_displayed()`,
  `parse_events()` (raw accessible-label → normalized rows), `write_csv()`, and
  `sundays()`. Edit parsing/filename logic here; both CLIs import it.
- **`gcal_scrape.js`** — the DOM scraper evaluated in the browser. Collects event
  chips (`[data-eventid]` + `role=button[aria-label]`), dedupes, and returns
  `{url,title,count,events:[{raw,...}]}`. If Google changes the calendar DOM and
  scrapes come back empty despite a rendered grid, update the selectors here.
- **`scrape_range.py`** — multi-week orchestrator (the main entry point).
  `--start/--end/--status/--outdir/--surface/--render-wait/--retries`.
- **`scrape_week.py`** — single-week scrape / re-scrape; can target the displayed
  week or `--week YYYY-MM-DD`, with `--dry-run` to preview.

## Gotchas learned the hard way

- **tmux breaks cmux access** — the #1 failure mode. See prerequisite above.
- **Render timing** — Google Calendar lazy-renders chips. The scripts wait for
  the URL to settle then sleep `--render-wait` seconds (default 5) and retry once
  on a zero-event scrape. If you still see zero-TOTAL weeks, raise `--render-wait`.
- **Surface IDs are not stable** across cmux restarts — always auto-detect (the
  default) rather than hard-coding a `surface:NN`.
- **Bracketed title prefixes** like `[Tentative] Sathish / Kunal` or `[Hold] …`
  are just part of the title; the real RSVP state comes from the chip's status
  word, so such events still correctly count as `Accepted` when accepted.
- **Low-but-nonzero weeks** (e.g. 1 accepted out of 84) are real RSVP states
  (leave/holiday), distinguishable from render misses because TOTAL is healthy.
