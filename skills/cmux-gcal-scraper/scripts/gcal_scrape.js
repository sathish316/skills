(() => {
  // Scrape the currently displayed Google Calendar week/day grid.
  // Returns JSON: { url, title, count, events: [{raw,title,time,date}] }
  // `raw` is the event chip's accessible label, which the Python side parses.
  const seen = new Set();
  const events = [];

  // Event chips in the grid carry data-eventid; fall back to role=button
  // elements whose accessible label looks like a calendar event.
  const nodes = document.querySelectorAll(
    '[data-eventid], div[role="button"][data-eventchip], div[role="button"][jslog], [role="button"][aria-label]'
  );

  const timeRe = /(\d{1,2}(?::\d{2})?\s*(?:–|-|to)\s*\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM))/;

  nodes.forEach((n) => {
    let raw = (n.getAttribute('aria-label') || n.innerText || '').trim().replace(/\s+/g, ' ');
    if (!raw) return;
    // Heuristic: real events almost always contain a time range or "all day".
    const hasTime = timeRe.test(raw) || /all day/i.test(raw);
    const eid = n.getAttribute('data-eventid');
    if (!hasTime && !eid) return;
    const key = eid || raw;
    if (seen.has(key)) return;
    seen.add(key);

    let title = raw, time = '', date = '';
    const m = raw.match(timeRe);
    if (m) {
      time = m[1].replace(/\s+/g, '');
      const parts = raw.split(',').map((s) => s.trim());
      // Title is usually the segment before the one containing the time.
      const timeIdx = parts.findIndex((p) => timeRe.test(p) || /all day/i.test(p));
      if (timeIdx > 0) title = parts.slice(0, timeIdx).join(', ');
      // A trailing segment that looks like a date.
      const dpart = parts.find((p) => /\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b|\b\d{4}\b|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday/.test(p));
      if (dpart) date = dpart;
    }
    events.push({ raw, title, time, date });
  });

  return JSON.stringify({
    url: location.href,
    title: document.title,
    count: events.length,
    events,
  });
})();
