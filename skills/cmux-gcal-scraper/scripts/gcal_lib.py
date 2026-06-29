#!/usr/bin/env python3
"""Shared helpers for scraping Google Calendar weeks via the cmux browser.

Why this exists: the cmux socket only answers processes that cmux itself
spawned (a peer-credential check), so these helpers MUST run from inside a
cmux terminal pane. They shell out to the cmux CLI to drive the browser
surface that already has Google Calendar open and logged in — no Google API,
OAuth, or GCP project required.
"""
import json
import os
import re
import subprocess
import datetime

CMUX = os.environ.get(
    "CMUX_BIN", "/Applications/cmux.app/Contents/Resources/bin/cmux"
)
HERE = os.path.dirname(os.path.abspath(__file__))
SCRAPE_JS_PATH = os.path.join(HERE, "gcal_scrape.js")

MONTHS = ("January February March April May June July August September October "
          "November December").split()
MONTHS_L = [m.lower() for m in MONTHS]
STATUSES = ["Accepted", "Declined", "Tentative", "Needs RSVP"]

_date_re = re.compile(r'\b(' + "|".join(MONTHS) + r')\s+(\d{1,2}),\s*(\d{4})')
_time_re = re.compile(
    r'^\s*(\d{1,2}(?::\d{2})?\s*[ap]m)\s+to\s+(\d{1,2}(?::\d{2})?\s*[ap]m)', re.I)


def cmux(*args, timeout=60):
    """Run a cmux CLI command; return (stdout, stderr, returncode)."""
    try:
        r = subprocess.run([CMUX, *args], capture_output=True, text=True,
                            timeout=timeout)
        return r.stdout, r.stderr, r.returncode
    except Exception as e:  # noqa: BLE001 - surface any failure to the caller
        return "", f"EXC {e}", -1


def check_access():
    """Verify the cmux socket is reachable from this process.

    Returns (ok, message). If not ok, the caller is almost certainly running
    outside a cmux pane (e.g. under tmux) and must relaunch inside cmux.
    """
    out, err, rc = cmux("--json", "list-workspaces", timeout=15)
    if rc == 0 and out.strip():
        return True, "cmux socket reachable"
    msg = (err or "").strip() or "empty response"
    return False, (
        "Cannot reach cmux. Run this from a terminal INSIDE a cmux pane "
        f"(not tmux). Detail: {msg}"
    )


def find_calendar_surface():
    """Walk every workspace/pane and return the browser surface ref whose URL
    is on calendar.google.com, or None if not found."""
    out, _, _ = cmux("--json", "list-workspaces")
    ws_refs = list(dict.fromkeys(re.findall(r'"(workspace:\d+)"', out)))
    found = []
    for ws in ws_refs:
        pout, _, _ = cmux("--json", "list-panes", "--workspace", ws)
        pane_refs = list(dict.fromkeys(re.findall(r'"(pane:\d+)"', pout)))
        for pane in pane_refs:
            sout, _, _ = cmux("--json", "list-pane-surfaces",
                              "--workspace", ws, "--pane", pane)
            try:
                data = json.loads(sout)
            except Exception:
                continue
            for s in data.get("surfaces", []):
                if (s.get("type") or "").lower() != "browser":
                    continue
                ref = s.get("ref") or s.get("id")
                uout, _, _ = cmux("browser", "--surface", ref, "get-url")
                url = uout.strip()
                if "calendar.google" in url:
                    return ref
                found.append((ref, url))
    # No calendar tab found; return the first browser surface if any, else None.
    return found[0][0] if found else None


def get_url(surface):
    out, _, _ = cmux("browser", "--surface", surface, "get-url")
    return out.strip()


def navigate_week(surface, week_start):
    """Navigate the surface to a given week (a datetime.date, ideally a Sunday)."""
    url = (f"https://calendar.google.com/calendar/u/0/r/week/"
           f"{week_start.year}/{week_start.month}/{week_start.day}")
    cmux("browser", "--surface", surface, "navigate", url)
    return url


def url_is_week(surface, week_start):
    frag = f"/week/{week_start.year}/{week_start.month}/{week_start.day}"
    return frag in get_url(surface)


def scrape_displayed(surface, timeout=60):
    """Eval the DOM scraper on the surface; return parsed JSON dict (or {})."""
    with open(SCRAPE_JS_PATH) as f:
        js = f.read()
    out, _, _ = cmux("browser", "--surface", surface, "eval", js, timeout=timeout)
    try:
        return json.loads(out)
    except Exception:
        return {"events": []}


def _to24(t):
    t = t.strip().lower().replace(" ", "")
    m = re.match(r'(\d{1,2})(?::(\d{2}))?(am|pm)', t)
    if not m:
        return (99, 99)
    h = int(m.group(1)); mins = int(m.group(2) or 0); ap = m.group(3)
    if ap == "pm" and h != 12:
        h += 12
    if ap == "am" and h == 12:
        h = 0
    return (h, mins)


def parse_events(events):
    """Turn raw scraped events into sorted rows with normalized fields.

    Each input event has a `raw` accessible-label string like:
      "1:30pm to 2pm, RCA sync, Sathish Kumar, Accepted, Location: ..., June 2, 2026"
    We pull start/end, the title (text before the organizer marker), the RSVP
    status, the location, and the ISO date.
    """
    rows = []
    for ev in events:
        raw = ev.get("raw", "")
        if not raw:
            continue
        tm = _time_re.match(raw)
        start = tm.group(1).replace(" ", "") if tm else ""
        end = tm.group(2).replace(" ", "") if tm else ""

        dm = _date_re.search(raw)
        if dm:
            mon = MONTHS.index(dm.group(1)) + 1
            d = datetime.date(int(dm.group(3)), mon, int(dm.group(2)))
            date_iso, dow = d.isoformat(), d.strftime("%a")
        else:
            date_iso, dow = "", ""

        # Title: text between the leading time segment and the organizer marker.
        body = raw[tm.end():].lstrip(", ") if tm else raw
        cut = len(body)
        for marker in (", Sathish Kumar", ", Calendar:"):
            i = body.find(marker)
            if i != -1:
                cut = min(cut, i)
        title = body[:cut].strip().strip(",").strip()

        status = next((s for s in STATUSES
                       if re.search(r'\b' + re.escape(s) + r'\b', raw)), "")

        if "No location" in raw:
            location = ""
        else:
            lm = re.search(r'Location:\s*(.*)', raw)
            location = ""
            if lm:
                loc = lm.group(1)
                dm2 = _date_re.search(loc)
                if dm2:
                    loc = loc[:dm2.start()]
                location = loc.strip().strip(",").strip()

        rows.append({
            "date": date_iso, "day": dow, "start": start, "end": end,
            "title": title, "status": status, "location": location,
            "_sort": (date_iso, _to24(start)),
        })
    rows.sort(key=lambda r: r["_sort"])
    for r in rows:
        r.pop("_sort", None)
    return rows


def week_filename(week_start, status_filter):
    """Build the per-week CSV filename, e.g. gcal_week_accepted_02_june_2026.csv.
    status_filter=None -> 'all'."""
    tag = (status_filter or "all").lower().replace(" ", "")
    return (f"gcal_week_{tag}_{week_start.day:02d}_"
            f"{MONTHS_L[week_start.month-1]}_{week_start.year}.csv")


def write_csv(rows, outdir, week_start, status_filter="Accepted"):
    """Filter rows by status (or keep all if status_filter is None) and write
    the per-week CSV. Returns (path, kept_count, total_count)."""
    import csv
    os.makedirs(outdir, exist_ok=True)
    kept = ([r for r in rows if r["status"] == status_filter]
            if status_filter else rows)
    path = os.path.join(outdir, week_filename(week_start, status_filter))
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(
            f, fieldnames=["date", "day", "start", "end", "title", "status", "location"])
        w.writeheader()
        for r in kept:
            w.writerow(r)
    return path, len(kept), len(rows)


def sundays(start, end):
    """Yield week-start dates (stepping 7 days) from start through end inclusive."""
    d = start
    while d <= end:
        yield d
        d += datetime.timedelta(days=7)
