#!/usr/bin/env python3
"""Scrape a single Google Calendar week via the cmux browser.

Run from a terminal INSIDE a cmux pane. Useful for re-scraping one week that a
range run missed (a render miss shows up as a zero-TOTAL week), or for a quick
one-off pull.

Examples:
  # Scrape whatever week is currently displayed in the calendar tab:
  python3 scrape_week.py

  # Navigate to a specific week first, then scrape:
  python3 scrape_week.py --week 2026-03-01

  # Keep all events (not just Accepted), preview to stdout without writing:
  python3 scrape_week.py --week 2026-03-01 --status all --dry-run
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
    ap.add_argument("--week", type=parse_date, default=None,
                    help="Week-start date to navigate to (YYYY-MM-DD). If "
                         "omitted, scrapes the currently displayed week.")
    ap.add_argument("--outdir", default="./data/calendar")
    ap.add_argument("--status", default="Accepted",
                    help="RSVP status to keep, or 'all' (default: %(default)s)")
    ap.add_argument("--surface", default=None,
                    help="cmux browser surface ref (default: auto-detect)")
    ap.add_argument("--render-wait", type=float, default=5.0)
    ap.add_argument("--dry-run", action="store_true",
                    help="Print the kept rows instead of writing a CSV")
    args = ap.parse_args()

    status_filter = None if args.status.lower() == "all" else args.status

    ok, msg = g.check_access()
    if not ok:
        print(f"ERROR: {msg}", file=sys.stderr)
        return 2

    surface = args.surface or g.find_calendar_surface()
    if not surface:
        print("ERROR: No Google Calendar browser surface found.", file=sys.stderr)
        return 2

    if args.week:
        g.navigate_week(surface, args.week)
        for _ in range(15):
            time.sleep(1)
            if g.url_is_week(surface, args.week):
                break
        time.sleep(args.render_wait)

    data = g.scrape_displayed(surface)
    rows = g.parse_events(data.get("events", []))

    # Derive the week-start for the filename: explicit flag wins, else infer
    # from the earliest event date in the scrape.
    week_start = args.week
    if week_start is None and rows:
        first = next((r["date"] for r in rows if r["date"]), None)
        if first:
            d = datetime.date.fromisoformat(first)
            week_start = d - datetime.timedelta(days=(d.weekday() + 1) % 7)  # back to Sunday

    kept = ([r for r in rows if r["status"] == status_filter]
            if status_filter else rows)
    print(f"URL: {data.get('url')}")
    print(f"events: {len(rows)} total, {len(kept)} kept "
          f"({'all' if status_filter is None else status_filter})")

    if args.dry_run:
        for r in kept:
            print(r)
        return 0

    if week_start is None:
        print("ERROR: Could not determine week start (no dated events). "
              "Re-run with --week.", file=sys.stderr)
        return 1

    path, k, total = g.write_csv(rows, args.outdir, week_start, status_filter)
    print(f"wrote {path} ({k}/{total})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
