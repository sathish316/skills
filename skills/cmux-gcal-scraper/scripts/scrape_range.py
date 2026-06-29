#!/usr/bin/env python3
"""Scrape a range of Google Calendar weeks via the cmux browser.

Run this from a terminal INSIDE a cmux pane, with Google Calendar already open
and logged in on a browser surface. For each week (Sunday start) in the range
it navigates the surface, waits for the grid to render, scrapes the events,
filters by RSVP status, and writes one CSV per week.

Examples:
  # All accepted meetings, H1 2026 (weeks ending within the range):
  python3 scrape_range.py --start 2026-01-04 --end 2026-05-24

  # Keep every event regardless of RSVP status, into a custom folder:
  python3 scrape_range.py --start 2025-06-29 --end 2025-12-28 \
      --status all --outdir ../../data/calendar

Output filenames: gcal_week_<status>_<dd>_<month>_<year>.csv
(e.g. gcal_week_accepted_04_january_2026.csv)
"""
import argparse
import datetime
import sys
import time

import gcal_lib as g


def parse_date(s):
    return datetime.datetime.strptime(s, "%Y-%m-%d").date()


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--start", required=True, type=parse_date,
                    help="First week-start date (YYYY-MM-DD, ideally a Sunday)")
    ap.add_argument("--end", required=True, type=parse_date,
                    help="Last week-start date (YYYY-MM-DD, inclusive)")
    ap.add_argument("--outdir", default="./data/calendar",
                    help="Directory to write per-week CSVs (default: %(default)s)")
    ap.add_argument("--status", default="Accepted",
                    help="RSVP status to keep, or 'all' for no filter "
                         "(default: %(default)s)")
    ap.add_argument("--surface", default=None,
                    help="cmux browser surface ref (default: auto-detect the "
                         "calendar tab)")
    ap.add_argument("--render-wait", type=float, default=5.0,
                    help="Seconds to wait after navigation for the grid to "
                         "render (default: %(default)s)")
    ap.add_argument("--retries", type=int, default=2,
                    help="Attempts per week if a scrape returns zero events "
                         "(default: %(default)s)")
    args = ap.parse_args()

    status_filter = None if args.status.lower() == "all" else args.status

    ok, msg = g.check_access()
    if not ok:
        print(f"ERROR: {msg}", file=sys.stderr)
        return 2

    surface = args.surface or g.find_calendar_surface()
    if not surface:
        print("ERROR: No Google Calendar browser surface found. Open Google "
              "Calendar in a cmux browser tab first.", file=sys.stderr)
        return 2
    print(f"Using surface {surface}; current URL: {g.get_url(surface)}")

    weeks = list(g.sundays(args.start, args.end))
    last_end = weeks[-1] + datetime.timedelta(days=6)
    print(f"Scraping {len(weeks)} weeks: {weeks[0]} .. {weeks[-1]} "
          f"(ends {last_end})\n")
    print(f"{'Week start':<12} {'Total':>6} {'Kept':>6}   File")
    print("-" * 72)

    summary = []
    for wk in weeks:
        rows = []
        for _ in range(max(1, args.retries)):
            g.navigate_week(surface, wk)
            for _ in range(15):
                time.sleep(1)
                if g.url_is_week(surface, wk):
                    break
            time.sleep(args.render_wait)
            data = g.scrape_displayed(surface)
            rows = g.parse_events(data.get("events", []))
            if rows:
                break
            time.sleep(3)  # brief pause before retrying a zero-event week

        path, kept, total = g.write_csv(rows, args.outdir, wk, status_filter)
        flag = "  <-- ZERO (re-check)" if total == 0 else ""
        print(f"{str(wk):<12} {total:>6} {kept:>6}   {path.split('/')[-1]}{flag}")
        summary.append((wk, total, kept))

    print("-" * 72)
    total_kept = sum(s[2] for s in summary)
    print(f"Done. {len(weeks)} weeks, {total_kept} kept "
          f"({'all events' if status_filter is None else status_filter}).")
    zeros = [str(s[0]) for s in summary if s[1] == 0]
    if zeros:
        print("ZERO-event weeks (likely render misses — re-scrape with "
              "scrape_week.py):", zeros)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
